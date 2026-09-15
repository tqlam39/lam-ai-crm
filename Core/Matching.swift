import Foundation

struct MatchScore:Codable,Equatable,Sendable {var eligible:Bool;var score:Int;var reasons:[String];var recommended:Bool {eligible && score >= 70}}
struct MatchPair:Identifiable,Sendable {var property:CRMRecord;var customer:CRMRecord;var requirement:CRMRecord;var result:MatchScore;var id:String{property.id+":"+customer.id}}
enum Matching {
    static func score(_ p:CRMRecord,_ r:CRMRecord,weights:JSONValue = Database().settings["weights"])->MatchScore {
        let area = (p.number("dimensions.calculatedArea") ?? 0) != 0 ? p.number("dimensions.calculatedArea")! : (p.number("dimensions.width") ?? 0)*(p.number("dimensions.length") ?? 0)
        var failures:[String] = []
        func check(_ bad:Bool,_ message:String){if bad {failures.append(message)}}
        func mismatch(_ field:String,_ value:String)->Bool {!r.strings(field).isEmpty && !r.strings(field).contains(value)}
        check(p.text("status") != "ACTIVE" || r.text("status") != "ACTIVE","Không hoạt động")
        check(!r.text("transactionType").isEmpty && r.text("transactionType") != p.text("transactionType"),"Hình thức")
        check(mismatch("propertyTypes",p.text("type")),"Loại BĐS")
        check(mismatch("provinceCities",p.text("location.provinceCity")),"Tỉnh/thành")
        check(mismatch("wardCommunes",p.text("location.wardCommune")),"Khu vực")
        check(r.number("priceMax").map{(p.number("price.amount") ?? 0) > $0} ?? false,"Vượt ngân sách")
        check(r.number("priceMin").map{(p.number("price.amount") ?? 0) < $0} ?? false,"Dưới ngân sách")
        check(r.number("widthMin").map{(p.number("dimensions.width") ?? 0) < $0} ?? false,"Ngang")
        check(r.number("lengthMin").map{(p.number("dimensions.length") ?? 0) < $0} ?? false,"Dài")
        check(r.number("areaMin").map{area < $0} ?? false,"Diện tích nhỏ")
        check(r.number("areaMax").map{area > $0} ?? false,"Diện tích lớn")
        check(r.number("bedroomsMin").map{(p.number("bedrooms") ?? 0) < $0} ?? false,"Thiếu phòng ngủ")
        check(mismatch("directions",p.text("direction")),"Hướng")
        check(r["carAccess"].bool == true && p["road.carAccess"].bool != true,"Chưa có ô tô tới")
        check(r.strings("legalPreferences").contains{!PropertyLogic.normalizedText(p.text("legal.note")).contains(PropertyLogic.normalizedText($0))},"Chưa đủ pháp lý")
        if !failures.isEmpty {return MatchScore(eligible:false,score:0,reasons:failures)}
        let signals:[(String,Bool,String)] = [
            ("area",!r.strings("wardCommunes").isEmpty,"Đúng khu vực"),
            ("price",r.number("priceMax") != nil || r.number("priceMin") != nil,"Trong ngân sách"),
            ("type",!r.strings("propertyTypes").isEmpty,"Đúng loại BĐS"),
            ("dimensions",["areaMin","areaMax","widthMin","lengthMin"].contains{r.number($0) != nil},"Đủ diện tích / kích thước"),
            ("bedrooms",r.number("bedroomsMin") != nil,"Đủ phòng ngủ"),
            ("direction",!r.strings("directions").isEmpty,"Đúng hướng"),
            ("legal",!r.strings("legalPreferences").isEmpty,"Pháp lý phù hợp"),
            ("car",r["carAccess"].bool == true,"Ô tô tới")]
        var total = 0.0,points = 0.0;var reasons:[String] = []
        for (key,active,reason) in signals where active {let w = weights[key].double ?? 0;total += w;points += w;reasons.append(reason)}
        let semantic = r.strings("semanticPreferences")
        if !semantic.isEmpty {
            let w = weights["semantic"].double ?? 0;total += w
            let source = PropertyLogic.normalizedText(p.text("details")+" "+(p["note"] == .null ? "undefined" : p.text("note"))+" "+p.title)
            let count = semantic.filter{source.contains(PropertyLogic.normalizedText($0))}.count
            points += w*Double(count)/Double(semantic.count);if count > 0 {reasons.append("Có từ khóa sở thích")}
        }
        return MatchScore(eligible:true,score:total > 0 ? Int((points/total*100).rounded()) : 0,reasons:reasons.isEmpty ? ["Chưa có tiêu chí cụ thể để chấm điểm"] : reasons)
    }
    static func pairs(_ data:Database,customerId:String? = nil,propertyId:String? = nil)->[MatchPair] {
        let customers = data.customers.filter {c in (customerId == nil || c.id == customerId) && !["Đã giao dịch","Tạm dừng"].contains(c.text("status"))}
        let properties = data.properties.filter {p in p.text("status") == "ACTIVE" && (propertyId == nil || p.id == propertyId)}
        let needs = Dictionary(grouping:data.requirements.filter{$0.text("status") == "ACTIVE"},by:{$0.text("customerId")})
        var results:[MatchPair] = []
        for customer in customers {for property in properties {
            var best:MatchPair?
            for need in needs[customer.id] ?? [] {
                let result = score(property,need,weights:data.settings["weights"])
                if result.recommended && result.score > (best?.result.score ?? -1) {best = MatchPair(property:property,customer:customer,requirement:need,result:result)}
            }
            if let best {results.append(best)}
        }}
        return results.sorted{$0.result.score == $1.result.score ? $0.id < $1.id : $0.result.score > $1.result.score}
    }
}
