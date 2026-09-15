import SwiftUI

struct NeedFields<Header:View>:View {
    @EnvironmentObject var store:CRMStore
    @Binding var record:CRMRecord
    @State private var raw:[String:String] = [:]
    var header:Header
    init(record:Binding<CRMRecord>,@ViewBuilder header:()->Header) {self._record = record;self.header = header()}
    var body:some View {
        Form {
            Section {header;Text("Có thể bỏ trống mọi tiêu chí. Chỉ các tiêu chí đã nhập được dùng để so khớp.").font(.footnote)}
            Section("Loại BĐS / giao dịch") {
                Picker("Trạng thái nhu cầu",selection:text("status")) {Text("Đang tìm").tag("ACTIVE");Text("Tạm dừng").tag("PAUSED");Text("Đã đáp ứng").tag("FULFILLED")}
                Picker("Giao dịch",selection:text("transactionType")) {Text("Không giới hạn").tag("");Text("Mua").tag("SALE");Text("Thuê").tag("RENT")}
                ForEach(Validation.propertyTypes,id:\.self) {key in Toggle(CRMStyle.types[key] ?? key,isOn:selected("propertyTypes",key))}
            }
            Section("Khoảng giá (tỷ đồng)") {
                TextField("Từ, ví dụ 1",text:number("priceMin",money:true)).keyboardType(.decimalPad).accessibilityIdentifier("need-price-min")
                TextField("Đến, ví dụ 1,5",text:number("priceMax",money:true)).keyboardType(.decimalPad).accessibilityIdentifier("need-price-max")
                Button("1 – 1,5 tỷ") {record["priceMin"] = .number(1_000_000_000);record["priceMax"] = .number(1_500_000_000);raw["priceMin"] = "1";raw["priceMax"] = "1,5"}
                Button("Bỏ khoảng giá") {record["priceMin"] = .null;record["priceMax"] = .null;raw["priceMin"] = "";raw["priceMax"] = ""}
            }
            Section("Khu vực — nhiều mục ngăn bằng dấu ;") {
                TextField("Tỉnh / thành",text:arrayText("provinceCities"))
                TextField("Phường / xã",text:arrayText("wardCommunes"))
                ForEach(store.data.settings["favoriteAreas"].array.map(\.text),id:\.self) {area in Toggle(area,isOn:selected("wardCommunes",area))}
            }
            Section("Hướng mong muốn") {ForEach(Validation.directions,id:\.self) {key in Toggle(CRMStyle.directions[key] ?? key,isOn:selected("directions",key))}}
            Section("Kích thước / tiện ích") {
                TextField("Ngang tối thiểu (m)",text:number("widthMin")).keyboardType(.decimalPad)
                TextField("Dài tối thiểu (m)",text:number("lengthMin")).keyboardType(.decimalPad)
                TextField("Diện tích từ (m²)",text:number("areaMin")).keyboardType(.decimalPad)
                TextField("Diện tích đến (m²)",text:number("areaMax")).keyboardType(.decimalPad)
                TextField("Phòng ngủ tối thiểu",text:number("bedroomsMin")).keyboardType(.numberPad)
                Toggle("Cần đường ô tô",isOn:Binding(get:{record["carAccess"].bool == true},set:{record["carAccess"] = $0 ? .bool(true) : .null}))
                TextField("Pháp lý mong muốn; phân cách bằng ;",text:arrayText("legalPreferences"))
                TextField("Ưu tiên khác; phân cách bằng ;",text:arrayText("semanticPreferences"))
            }
            Section("Mô tả nhu cầu") {TextField("Mô tả chi tiết",text:text("rawRequirementText"),axis:.vertical).lineLimit(4...12)}
        }.navigationTitle("Nhu cầu tìm BĐS")
    }
    private func text(_ key:String)->Binding<String> {Binding(get:{record.text(key)},set:{record[key] = $0.isEmpty ? .null : .string($0)})}
    private func arrayText(_ key:String)->Binding<String> {Binding(get:{record.strings(key).joined(separator:";")},set:{record[key] = .array($0.components(separatedBy:";").map(JSONValue.string))})}
    private func selected(_ key:String,_ value:String)->Binding<Bool> {Binding(get:{record.strings(key).contains(value)},set:{on in var values = record.strings(key).filter{$0 != value};if on {values.append(value)};record[key] = .array(values.map(JSONValue.string))})}
    private func number(_ key:String,money:Bool = false)->Binding<String> {
        Binding(get:{raw[key] ?? (money ? Money.billions(record[key].decimal) : record[key].decimal.map{NSDecimalNumber(decimal:$0).stringValue} ?? record.text(key))},set:{value in
            raw[key] = value
            if value.isEmpty {record[key] = .null;return}
            if money,let parsed = try? Money.vnd(fromBillions:value) {record[key] = .number(parsed)}
            else if !money,value.range(of:#"^\d+([.,]\d*)?$"#,options:.regularExpression) != nil,let parsed = Decimal(string:value.replacingOccurrences(of:",",with:"."),locale:Locale(identifier:"en_US_POSIX")) {record[key] = .number(parsed)}
            else {record[key] = .string(value)}
        })
    }
}
extension NeedFields where Header == EmptyView {init(record:Binding<CRMRecord>) {self.init(record:record){EmptyView()}}}
