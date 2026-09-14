import SwiftUI

struct PropertiesView: View {
    @EnvironmentObject var store:CRMStore
    @State private var query = ""
    @State private var type = "",status = "",ward = "",direction = "",transaction = ""
    @State private var minPrice = "",maxPrice = "",minArea = "",bedrooms = ""
    @State private var drafts = false
    @State private var filters = false
    var items:[CRMRecord] {
        if drafts {return store.data.drafts}
        let min = (try? Money.vnd(fromBillions:minPrice)).map{NSDecimalNumber(decimal:$0).doubleValue}
        let max = (try? Money.vnd(fromBillions:maxPrice)).map{NSDecimalNumber(decimal:$0).doubleValue}
        return store.data.properties.filter {p in
            let price = p.number("price.amount") ?? 0
            let area = (p.number("dimensions.width") ?? 0)*(p.number("dimensions.length") ?? 0)
            let hay = ["title","code","owner.name","owner.phone","location.wardCommune","location.addressText","location.street","details","note"].map{p.text($0)}.joined(separator:" ")+p.strings("tags").joined(separator:" ")
            return (query.isEmpty || PropertyLogic.normalizedText(hay).contains(PropertyLogic.normalizedText(query))) && (type.isEmpty || p.text("type") == type) && (status.isEmpty || p.text("status") == status) && (ward.isEmpty || p.text("location.wardCommune").localizedStandardContains(ward)) && (direction.isEmpty || p.text("direction") == direction) && (transaction.isEmpty || p.text("transactionType") == transaction) && (min == nil || price >= min!) && (max == nil || price <= max!) && (min == nil || max == nil || min! <= max!) && area >= (Double(minArea) ?? 0) && (p.number("bedrooms") ?? 0) >= (Double(bedrooms) ?? 0)
        }
    }
    var body:some View {
        ScrollView {
            LazyVStack(spacing:14) {
                Toggle("Bản nháp",isOn:$drafts)
                DisclosureGroup("Bộ lọc",isExpanded:$filters) {
                    VStack(spacing:12) {
                        picker("Loại BĐS",$type,CRMStyle.types);picker("Trạng thái",$status,CRMStyle.statuses)
                        picker("Giao dịch",$transaction,["SALE":"Mua bán","RENT":"Cho thuê"]);picker("Hướng",$direction,CRMStyle.directions)
                        TextField("Phường / Xã",text:$ward).textFieldStyle(.roundedBorder)
                        HStack{TextField("Giá từ (tỷ)",text:$minPrice);TextField("Giá đến (tỷ)",text:$maxPrice)}.keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        ScrollView(.horizontal) {HStack {preset("Dưới 1 tỷ","","0,999999999");preset("1–2 tỷ","1","2");preset("2–3 tỷ","2","3");preset("Trên 3 tỷ","3,000000001","")}}
                        HStack{TextField("Diện tích từ (m²)",text:$minArea);TextField("Phòng ngủ từ",text:$bedrooms)}.keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        Button("Bỏ bộ lọc") {type="";status="";ward="";direction="";transaction="";minPrice="";maxPrice="";minArea="";bedrooms=""}
                    }.padding(.vertical)
                }
                Text("\(items.count) \(drafts ? "bản nháp" : "bất động sản")").font(.subheadline).frame(maxWidth:.infinity,alignment:.leading)
                if items.isEmpty {CRMEmpty(title:"Chưa có BĐS trong mục này",detail:"Nhấn Thêm BĐS để nhập hoặc đổi bộ lọc.")}
                ForEach(items) {p in
                    if drafts {NavigationLink {PropertyEditor(record:p)} label:{CRMPanel{Text(p.title.isEmpty ? "Nháp chưa có tiêu đề" : p.title);Text("Tiếp tục nhập →").font(.caption)}}.buttonStyle(.plain)}
                    else {NavigationLink {PropertyReadView(id:p.id)} label:{VStack(spacing:0){if let image = p["media.images"].array.first {CRMImage(reference:image["url"].text).frame(height:190).clipped()};PropertySummary(property:p)}.clipShape(RoundedRectangle(cornerRadius:16))}.buttonStyle(.plain)}
                }
            }.padding(18)
        }.searchable(text:$query,prompt:"Tìm mã, địa chỉ, chủ, ghi chú…")
        .toolbar{ToolbarItem(placement:.topBarTrailing){NavigationLink {PropertyEditor(record:PropertyLogic.newDraft())} label:{Label("Thêm BĐS",systemImage:"plus")}}}
    }
    private func picker(_ label:String,_ binding:Binding<String>,_ options:[String:String])->some View{Picker(label,selection:binding){Text("Tất cả").tag("");ForEach(options.keys.sorted(),id:\.self){Text(options[$0] ?? $0).tag($0)}}}
    private func preset(_ label:String,_ min:String,_ max:String)->some View{Button(label){minPrice=min;maxPrice=max}.buttonStyle(.bordered)}
}

struct PropertyReadView:View {
    @EnvironmentObject var store:CRMStore
    @Environment(\.dismiss) var dismiss
    let id:String
    @State private var remove = false
    var property:CRMRecord?{store.data.properties.first{$0.id == id}}
    var body:some View {
        ScrollView {
            if let p = property {
                VStack(alignment:.leading,spacing:16) {
                    ScrollView(.horizontal){HStack{ForEach(Array(p["media.images"].array.enumerated()),id:\.offset){_,image in CRMImage(reference:image["url"].text).frame(width:290,height:210).clipped().clipShape(RoundedRectangle(cornerRadius:16))}}}
                    PropertySummary(property:p)
                    CRMPanel{Text("Thông tin chi tiết").font(.headline);Text(p.text("details"));Text(p.text("legal.certificateStatus") == "RED_BOOK" ? "Sổ đỏ" : p.text("legal.certificateStatus") == "NO_CERTIFICATE" ? "Chưa có sổ" : "Pháp lý chưa cung cấp");Text(p.text("legal.note"))}
                    CRMPanel {
                        Text("Thông tin nội bộ").font(.headline);Text("Chủ: "+p.text("owner.name"));Text(p.text("owner.phone"));Text(p.text("note"))
                        if let phone = contact(p.text("owner.phone")){Link("Gọi chủ",destination:phone)}
                        Text("Cập nhật: "+p.text("updatedAt")).font(.caption)
                        Button("Đã xác minh hôm nay"){Task{try? await store.commit(entity:id,action:"Xác minh lại BĐS"){d in guard let index = d.properties.firstIndex(where:{$0.id == id})else{return};d.properties[index]["lastVerifiedAt"] = .string(Database.now);d.properties[index]["updatedAt"] = .string(Database.now)}}}
                    }
                    if p.text("status") == "SOLD" {CRMPanel{Text("Đã bán: "+p.text("soldInfo.soldAt")).font(.headline);Text(CRMStyle.money(p.number("soldInfo.actualSoldPrice") ?? 0));Text(p.text("soldInfo.note"))}}
                    NavigationLink("Chỉnh sửa BĐS"){PropertyEditor(record:p)}.buttonStyle(.borderedProminent)
                    CRMPanel{Text("Lịch sử").font(.headline);ForEach(store.data.activities.filter{$0.text("entityId") == id}){a in Text(a.text("action"));Text(a.text("at")).font(.caption).foregroundStyle(.secondary)}}
                    Button("Xóa BĐS",role:.destructive){remove = true}
                }.padding(18)
            }else{CRMEmpty(title:"Không tìm thấy BĐS").padding()}
        }.navigationTitle(property?.title ?? "Bất động sản").navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Xóa BĐS? Công việc được giữ và gỡ liên kết sản phẩm.",isPresented:$remove,titleVisibility:.visible){Button("Xóa BĐS",role:.destructive){Task{do{try await store.commit(entity:id,action:"Xóa BĐS"){d in d.properties.removeAll{$0.id == id};for i in d.tasks.indices where d.tasks[i].text("propertyId") == id {d.tasks[i]["propertyId"] = .null}};dismiss()}catch{}}}}
    }
    private func contact(_ phone:String)->URL?{let p = phone.filter{$0.isNumber || $0 == "+"};return p.count >= 8 && p.count <= 16 ? URL(string:"tel:"+p) : nil}
}
