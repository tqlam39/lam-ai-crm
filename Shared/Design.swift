import SwiftUI

enum CRMStyle {
    static let green = Color(red: 8/255, green: 120/255, blue: 102/255)
    static let background = Color(red: 245/255, green: 247/255, blue: 248/255)
    static let ink = Color(red: 32/255, green: 58/255, blue: 53/255)
    static let types = ["HOUSE":"Nhà","LAND":"Đất nền","AGRICULTURAL_LAND":"Đất nông nghiệp","WAREHOUSE":"Kho xưởng"]
    static let directions = ["E":"Đông","W":"Tây","S":"Nam","N":"Bắc","NE":"Đông Bắc","NW":"Tây Bắc","SE":"Đông Nam","SW":"Tây Nam"]
    static let statuses = ["ACTIVE":"Đang bán","SOLD":"Đã bán","PAUSED":"Tạm ngưng","OUT_OF_STOCK":"Hết hàng"]
    static func money(_ value: Double) -> String {
        let f = NumberFormatter(); f.locale = Locale(identifier:"vi_VN"); f.maximumFractionDigits = 2
        return (f.string(from: NSNumber(value: value >= 1e9 ? value/1e9 : value/1e6)) ?? "0") + (value >= 1e9 ? " tỷ" : " triệu")
    }
}
struct CRMPanel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { VStack(alignment:.leading,spacing:12) { content }.frame(maxWidth:.infinity,alignment:.leading).padding(16).background(.white,in:RoundedRectangle(cornerRadius:16)) }
}
struct CRMEmpty: View {
    var title: String
    var detail: String = "Dữ liệu được lưu trên iPhone, có thể sử dụng khi không có mạng."
    var body: some View { CRMPanel { Image(systemName:"tray").font(.largeTitle).foregroundStyle(CRMStyle.green); Text(title).font(.headline); Text(detail).font(.subheadline).foregroundStyle(.secondary) } }
}
struct PropertySummary: View {
    let property: CRMRecord
    var body: some View {
        CRMPanel {
            Text(property.text("code")).font(.caption).foregroundStyle(.secondary)
            Text(property.title).font(.headline)
            Label(property.text("location.wardCommune"),systemImage:"mappin.and.ellipse").font(.subheadline)
            Text("\(property.number("dimensions.width") ?? 0, specifier:"%g") × \(property.number("dimensions.length") ?? 0, specifier:"%g") m · \(CRMStyle.directions[property.text("direction")] ?? "")")
                .font(.subheadline).foregroundStyle(.secondary)
            HStack { Text(CRMStyle.money(property.number("price.amount") ?? 0)).font(.title3.bold()).foregroundStyle(CRMStyle.green); Spacer(); Text(CRMStyle.statuses[property.text("status")] ?? property.text("status")).font(.caption) }
        }
    }
}
