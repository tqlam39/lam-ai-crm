import SwiftUI

struct CopilotView:View {
    @EnvironmentObject var store:CRMStore
    @State private var question = ""
    @State private var history:[CopilotResult] = []
    @State private var busy = false
    @State private var error = ""
    var body:some View {
        ScrollView {LazyVStack(alignment:.leading,spacing:16) {
            Text("Hỏi dữ liệu CRM bằng tiếng Việt").font(.title2.bold())
            Text("Ví dụ: Tôi có nhà nào dưới 2 tỷ ở Phú Lợi? Có khách nào tìm nhà hướng Đông?").font(.footnote).foregroundStyle(.secondary)
            HStack {Button("Khách cần chăm sóc") {local("pending","Hôm nay cần chăm sóc khách nào?")};Button("BĐS lâu chưa cập nhật") {local("stale","BĐS nào lâu chưa cập nhật?")}}
            ForEach(history) {answer in
                CRMPanel {
                    Text(answer.question).font(.headline);Text(answer.message)
                    ForEach(answer.properties.prefix(50)) {p in NavigationLink {PropertyReadView(id:p.id)} label:{Text(p.title+" · "+CRMStyle.money(p.number("price.amount") ?? 0))}}
                    ForEach(answer.customers.prefix(50)) {c in
                        if answer.matching {NavigationLink("So khớp cho "+c.title) {MatchingView(customerId:c.id)}}
                        else {NavigationLink(c.title) {CustomerDetail(id:c.id)}}
                    }
                    if answer.properties.count+answer.customers.count > 50 {Text("Đang hiển thị 50 kết quả đầu; thêm điều kiện để thu hẹp.").font(.caption)}
                }
            }
            if busy {ProgressView("Đang hiểu câu hỏi…")}
            if !error.isEmpty {Text(error).foregroundStyle(.red)}
        }.padding(18)}
        .safeAreaInset(edge:.bottom) {HStack {TextField("Hỏi về BĐS, khách, chăm sóc…",text:$question,axis:.vertical).lineLimit(1...4).textFieldStyle(.roundedBorder);Button("Gửi") {ask()}.disabled(busy || question.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)}.padding().background(.white)}
        .navigationTitle("Hỏi CRM")
    }
    private func local(_ intent:String,_ text:String) {history.append(Copilot.search(.object(["intent":.string(intent)]),in:store.data,question:text))}
    private func ask() {
        let text = question;question = "";busy = true;error = ""
        Task {defer{busy = false};do {
            guard let config = try AIVault.read() else {throw CRMError.invalid("Cấu hình API key / model AI để hỏi tự do. Hai nút tra cứu nhanh dùng được khi offline.")}
            let query = try await AIClient.shared.generate(config,instruction:Copilot.prompt,input:.object(["question":.string(String(text.prefix(3000)))]))
            let data = store.data
            let result = await Task.detached{Copilot.search(query,in:data,question:text)}.value
            history.append(result)
        }catch{self.error = error.localizedDescription}}
    }
}
