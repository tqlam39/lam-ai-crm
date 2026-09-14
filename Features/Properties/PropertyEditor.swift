import SwiftUI
import PhotosUI

struct PropertyEditor: View {
    @EnvironmentObject var store:CRMStore
    @Environment(\.dismiss) var dismiss
    @State var record:CRMRecord
    @State private var photos:[PhotosPickerItem] = []
    @State private var importing = false
    @State private var error = ""
    @State private var duplicates:[PropertyLogic.Duplicate] = []
    @State private var confirm = false
    @State private var oldProperty:CRMRecord?
    private func text(_ path:String)->Binding<String> {Binding(get:{record.text(path)},set:{record[path] = .string($0)})}
    private func numeric(_ path:String)->Binding<String> {Binding(get:{record[path].decimal.map{NSDecimalNumber(decimal:$0).stringValue.replacingOccurrences(of:".",with:",")} ?? ""},set:{record[path] = Decimal(string:$0.replacingOccurrences(of:",",with:"."),locale:Locale(identifier:"en_US_POSIX")).map(JSONValue.number) ?? .null})}
    private func money(_ path:String)->Binding<String> {Binding(get:{Money.billions(record[path].decimal)},set:{do {record[path] = try Money.vnd(fromBillions:$0).map(JSONValue.number) ?? .null;error = ""}catch{self.error = error.localizedDescription;record[path] = .null}})}
    private func flag(_ path:String)->Binding<Bool> {Binding(get:{record[path].bool ?? false},set:{record[path] = .bool($0)})}
    var body:some View {
        Form {
            Section("Thông tin cơ bản") {
                TextField("Tiêu đề *",text:text("title")).accessibilityIdentifier("property-title")
                choices("Loại BĐS *","type",CRMStyle.types)
                choices("Giao dịch *","transactionType",["SALE":"Mua bán","RENT":"Cho thuê"])
                choices("Trạng thái *","status",CRMStyle.statuses)
            }
            Section("Vị trí") {
                TextField("Tỉnh / Thành *",text:text("location.provinceCity"))
                TextField("Phường / Xã *",text:text("location.wardCommune"))
                Menu("Khu vực yêu thích") {ForEach(store.data.settings["favoriteAreas"].array.map(\.text),id:\.self){area in Button(area){record["location.wardCommune"] = .string(area)}}}
                TextField("Khóm / Ấp",text:text("location.hamlet"));TextField("Đường",text:text("location.street"))
                TextField("Khu vực",text:text("location.area"));TextField("Địa chỉ mô tả",text:text("location.addressText"),axis:.vertical)
                TextField("Vĩ độ",text:numeric("location.latitude")).keyboardType(.numbersAndPunctuation)
                TextField("Kinh độ",text:numeric("location.longitude")).keyboardType(.numbersAndPunctuation)
                TextField("Link bản đồ",text:text("location.mapUrl")).keyboardType(.URL).textInputAutocapitalization(.never)
            }
            Section("Diện tích và kết cấu") {
                number("Ngang (m) *","dimensions.width");number("Dài (m) *","dimensions.length")
                Text("Diện tích: \((record.number("dimensions.width") ?? 0)*(record.number("dimensions.length") ?? 0),specifier:"%g") m²")
                choices("Hướng *","direction",CRMStyle.directions,empty:true)
                if !["LAND","AGRICULTURAL_LAND"].contains(record.text("type")) {number("Phòng ngủ *","bedrooms")}
                number("WC","bathrooms");number("Tầng","floors");TextField("Loại đất",text:text("landType"));number("Diện tích thổ cư (m²)","residentialArea")
                Toggle("Ô tô tới (đã xác minh)",isOn:flag("road.carAccess"))
            }
            Section("Pháp lý") {
                choices("Giấy chứng nhận","legal.certificateStatus",["RED_BOOK":"Sổ đỏ","NO_CERTIFICATE":"Chưa có sổ"],empty:true)
                TextField("Ghi chú pháp lý",text:text("legal.note"),axis:.vertical)
                Toggle("Đã hoàn công",isOn:flag("legal.completion"));Toggle("Sổ riêng",isOn:flag("legal.separateCertificate"))
            }
            Section("Giá") {
                TextField("Giá tổng (tỷ đồng) *",text:money("price.amount")).keyboardType(.decimalPad)
                Text("1,5 tỷ = 1.500.000.000 VNĐ").font(.caption).foregroundStyle(.secondary)
                Toggle("Giá thương lượng",isOn:flag("price.negotiable"))
            }
            Section("Liên hệ") {
                TextField("Chủ sở hữu *",text:text("owner.name"));TextField("SĐT chủ",text:text("owner.phone")).keyboardType(.phonePad)
                TextField("Môi giới",text:text("broker.name"));TextField("SĐT môi giới",text:text("broker.phone")).keyboardType(.phonePad)
                TextField("Người đang nắm chủ",text:text("holder.name"));TextField("SĐT người nắm chủ",text:text("holder.phone")).keyboardType(.phonePad)
                TextField("Nguồn sản phẩm",text:text("source"));TextField("Link nguồn",text:text("sourceUrl")).keyboardType(.URL).textInputAutocapitalization(.never)
            }
            Section("Ảnh bất động sản *") {
                PhotosPicker(selection:$photos,maxSelectionCount:20,matching:.images) {Label("Chọn nhiều ảnh",systemImage:"photo.on.rectangle")}.disabled(importing)
                if importing {ProgressView("Đang tối ưu ảnh…")}
                ForEach(Array(record["media.images"].array.enumerated()),id:\.offset) {index,image in
                    HStack {
                        CRMImage(reference:image["url"].text).frame(width:72,height:72).clipped().clipShape(RoundedRectangle(cornerRadius:8))
                        Text(index == 0 ? "Ảnh đại diện" : "Ảnh \(index+1)")
                        Spacer()
                        Button("Đại diện") {var images = record["media.images"].array;let selected = images.remove(at:index);images.insert(selected,at:0);setImages(images)}.buttonStyle(.borderless).disabled(index == 0)
                        Button("Bỏ",role:.destructive) {var images = record["media.images"].array;images.remove(at:index);setImages(images)}.buttonStyle(.borderless)
                    }
                }
                TextField("Link video",text:text("media.videoUrl")).keyboardType(.URL)
            }
            Section("Mô tả và ghi chú") {
                TextField("Thông tin chi tiết",text:text("details"),axis:.vertical).lineLimit(4...12)
                TextField("Ghi chú nội bộ",text:text("note"),axis:.vertical).lineLimit(3...8)
                TextField("Tags (ngăn cách bằng ;)",text:Binding(get:{record.strings("tags").joined(separator:";")},set:{record["tags"] = .array($0.split(separator:";").map{.string(String($0).trimmingCharacters(in:.whitespaces))})}))
            }
            if record.text("status") == "SOLD" {
                Section("Thông tin giao dịch đã bán") {
                    Text("Giá đăng được giữ nguyên; nhập giá bán thực tế riêng.")
                    TextField("Ngày bán (yyyy-MM-dd) *",text:text("soldInfo.soldAt"))
                    TextField("Giá bán thực tế (tỷ đồng) *",text:money("soldInfo.actualSoldPrice")).keyboardType(.decimalPad)
                    TextField("Người mua",text:text("soldInfo.buyer"));number("Hoa hồng (VNĐ)","soldInfo.commission")
                    TextField("Ghi chú giao dịch",text:text("soldInfo.note"),axis:.vertical)
                }
            }
            if !error.isEmpty {Section {Text(error).foregroundStyle(.red)}}
            if !duplicates.isEmpty {Section("Sản phẩm này có thể trùng với BĐS đã tồn tại.") {
                ForEach(duplicates) {match in
                    VStack(alignment:.leading,spacing:8) {
                        Button("Xem \(match.property.title) · \(match.score)%") {oldProperty = match.property}
                        Text(match.reasons.joined(separator:" · ")).font(.caption)
                        Button("Cập nhật BĐS này") {record["id"] = .string(match.property.id);record["createdAt"] = match.property["createdAt"];confirm = true}
                    }
                }
                Button("Tôi đã kiểm tra, vẫn tạo mới") {Task{await persist()}}
                Button("Quay lại chỉnh sửa") {duplicates = []}
            }}
            Section {
                Button("Lưu chính thức") {save()}.disabled(store.busy || importing).accessibilityIdentifier("save-property")
                Button("Lưu nháp") {Task {do{try await store.commit(entity:record.id,action:"Lưu nháp BĐS"){$0.upsert(record,into:"drafts")};dismiss()}catch{self.error = error.localizedDescription}}}.disabled(store.busy || importing).accessibilityIdentifier("save-draft")
            }
        }
        .navigationTitle(store.data.properties.contains{$0.id == record.id} ? "Chỉnh sửa BĐS" : "Thêm bất động sản")
        .onChange(of:photos) {_,items in Task {importing = true;defer{importing = false;photos = []};do{var images = record["media.images"].array;for item in items {if let data = try await item.loadTransferable(type:Data.self){images.append(try MediaFiles.saveImage(data))}};setImages(images)}catch{self.error = error.localizedDescription}}}
        .confirmationDialog("Xác nhận thay đổi giá, trạng thái hoặc chủ sở hữu?",isPresented:$confirm,titleVisibility:.visible) {Button("Xác nhận và lưu") {Task{await persist()}}}
        .sheet(item:$oldProperty) {property in NavigationStack {PropertyReadView(id:property.id).toolbar {ToolbarItem(placement:.cancellationAction){Button("Đóng"){oldProperty = nil}}}}}
    }
    private func setImages(_ images:[JSONValue]) {record["media.images"] = .array(images.enumerated().map{index,value in var image = value;image["order"] = .number(Decimal(index));return image})}
    private func number(_ title:String,_ field:String)->some View {TextField(title,text:numeric(field)).keyboardType(.decimalPad)}
    private func choices(_ title:String,_ field:String,_ options:[String:String],empty:Bool = false)->some View {
        Picker(title,selection:text(field)) {if empty {Text("Chưa cung cấp").tag("")};ForEach(options.keys.sorted(),id:\.self){Text(options[$0] ?? $0).tag($0)}}
    }
    private func save() {
        do {
            error = ""
            var prepared = record;prepared["updatedAt"] = .string(Database.now)
            if ["LAND","AGRICULTURAL_LAND"].contains(prepared.text("type")){prepared["bedrooms"] = .number(0)}
            try Validation.property(prepared);record = PropertyLogic.normalize(prepared)
            duplicates = PropertyLogic.duplicates(record,in:store.data.properties)
            if !duplicates.isEmpty{return}
            if let old = store.data.properties.first(where:{$0.id == record.id}),["price.amount","status","owner.name"].contains(where:{old[$0] != record[$0]}) {confirm = true;return}
            Task {await persist()}
        } catch {self.error = error.localizedDescription}
    }
    private func persist() async {
        do {try Validation.property(record);try await store.commit(entity:record.id,action:"Lưu bất động sản") {d in d.upsert(record,into:"properties");d.drafts.removeAll{$0.id == record.id}};dismiss()}catch{self.error = error.localizedDescription}
    }
}
