import SwiftUI

struct MatchingView:View {
    @EnvironmentObject var store:CRMStore
    var customerId:String?
    var propertyId:String?
    @State private var results:[MatchPair] = []
    @State private var loading = true
    var body:some View {
        ScrollView {LazyVStack(spacing:14) {
            Text("Đề xuất từ 70% và đáp ứng mọi điều kiện bắt buộc. Điểm thể hiện mức phù hợp, không phải xác suất giao dịch.").font(.footnote).foregroundStyle(.secondary)
            if loading {ProgressView("Đang so khớp trên máy…")}
            else if results.isEmpty {CRMEmpty(title:"Chưa có đề xuất phù hợp",detail:"Kiểm tra nhu cầu đang tìm, khoảng giá và trạng thái BĐS. Các tiêu chí trống không được tự tính điểm.")}
            ForEach(results) {pair in
                CRMPanel {
                    HStack {Text("\(pair.result.score)% phù hợp").font(.title3.bold()).foregroundStyle(CRMStyle.green);Spacer()}
                    NavigationLink(pair.property.title) {PropertyReadView(id:pair.property.id)}
                    Text(CRMStyle.money(pair.property.number("price.amount") ?? 0))
                    NavigationLink("Khách: "+pair.customer.title) {CustomerDetail(id:pair.customer.id)}
                    Text(pair.result.reasons.joined(separator:" · ")).font(.subheadline)
                    NavigationLink("AI giải thích mức phù hợp") {AIWritingView(title:"Giải thích so khớp",instruction:"Giải thích điểm và lý do được cung cấp bằng tiếng Việt; không thay đổi điểm hoặc bỏ qua điều kiện bắt buộc.",input:.object(["score":.number(Decimal(pair.result.score)),"reasons":.array(pair.result.reasons.map(JSONValue.string))]))}
                    HStack {if let url = CustomerLogic.phone(pair.customer) {Link("Gọi",destination:url)};if let url = CustomerLogic.zalo(pair.customer) {Link("Zalo",destination:url)}}
                    NavigationLink("Ghi chăm sóc / hẹn tiếp") {CareEditor(customerId:pair.customer.id,initialPropertyId:pair.property.id)}
                }
            }
        }.padding(18)}
        .task(id:store.revision) {
            loading = true;let data = store.data,c = customerId,p = propertyId
            let values = await Task.detached(priority:.userInitiated){Matching.pairs(data,customerId:c,propertyId:p)}.value
            if !Task.isCancelled {results = values;loading = false}
        }
    }
}
