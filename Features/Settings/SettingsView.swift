import SwiftUI

struct SettingsView:View {
    @EnvironmentObject var store:CRMStore
    @State private var form:JSONValue = .object([:])
    @State private var loaded = false
    @State private var message = ""
    let labels = ["area":"Khu vực","price":"Giá","type":"Loại BĐS","dimensions":"Kích thước","bedrooms":"Phòng ngủ","direction":"Hướng","legal":"Pháp lý","car":"Ô tô","semantic":"Sở thích"]
    var body:some View {
        Form {
            Section {Text("Dữ liệu SQLite trên iPhone");NavigationLink("API key / model AI") {AISettingsView()};NavigationLink("Sao lưu / khôi phục / CSV") {BackupView()}}
            Section("Thương hiệu & khu vực") {
                TextField("Tên thương hiệu",text:text("brand"));TextField("Điện thoại trên tin chia sẻ",text:text("phone")).keyboardType(.phonePad)
                TextField("Khu vực yêu thích, mỗi dòng một nơi",text:Binding(get:{form["favoriteAreas"].array.map(\.text).joined(separator:"\n")},set:{form["favoriteAreas"] = .array($0.components(separatedBy:"\n").map(JSONValue.string))}),axis:.vertical).lineLimit(3...8)
                Stepper("Nhắc xác minh BĐS sau \(Int(form["freshnessDays"].double ?? 7)) ngày",value:number("freshnessDays",fallback:7),in:1...365)
            }
            Section("Trọng số so khớp") {ForEach(labels.keys.sorted(),id:\.self){key in Stepper("\(labels[key]!) · \(Int(form["weights."+key].double ?? 0))",value:number("weights."+key),in:0...100)}}
            Button("Lưu cài đặt") {Task {do {
                try Validation.require(!form["brand"].text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,"Nhập tên thương hiệu.")
                try Validation.require(form["weights"].object.values.contains{($0.double ?? 0) > 0},"Cần ít nhất một trọng số lớn hơn 0.")
                var prepared = form;var seen = Set<String>()
                prepared["favoriteAreas"] = .array(form["favoriteAreas"].array.map{$0.text.trimmingCharacters(in:.whitespacesAndNewlines)}.filter{!$0.isEmpty && seen.insert($0).inserted}.map(JSONValue.string))
                try await store.commit(entity:"settings",action:"Cập nhật cấu hình"){$0.settings = prepared};message = "Đã lưu."
            }catch{message = error.localizedDescription}}}.disabled(store.busy)
            if !message.isEmpty {Text(message)}
            Section("Tổng quan") {
                Text("\(store.data.properties.filter{$0.text("status") == "SOLD"}.count) BĐS đã bán")
                Text("Tổng giá giao dịch: "+CRMStyle.money(store.data.properties.filter{$0.text("status") == "SOLD"}.reduce(0){$0+($1.number("soldInfo.actualSoldPrice") ?? 0)}))
                Text("\(store.data.tasks.filter{$0.text("status") == "DONE"}.count) công việc hoàn thành")
            }
        }.navigationTitle("Cài đặt").onAppear {if !loaded {form = store.data.settings;loaded = true}}
    }
    private func text(_ key:String)->Binding<String> {Binding(get:{form[key].text},set:{form[key] = .string($0)})}
    private func number(_ key:String,fallback:Int = 0)->Binding<Int> {Binding(get:{Int(form[key].double ?? Double(fallback))},set:{form[key] = .number(Decimal($0))})}
}
