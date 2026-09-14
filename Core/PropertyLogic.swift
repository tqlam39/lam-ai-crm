import Foundation

enum PropertyLogic {
    static func normalize(_ input: CRMRecord) -> CRMRecord {
        var p = input
        let area = (p.number("dimensions.width") ?? 0) * (p.number("dimensions.length") ?? 0)
        p["dimensions.calculatedArea"] = .number(Decimal(area))
        if area > 0 { p["price.pricePerM2"] = .number(Decimal((p.number("price.amount") ?? 0)/area)) }
        for field in ["title","owner.name"] { p[field] = .string(p.text(field).trimmingCharacters(in:.whitespacesAndNewlines)) }
        p["owner.phone"] = .string(p.text("owner.phone").filter{!$0.isWhitespace})
        if ["LAND","AGRICULTURAL_LAND"].contains(p.text("type")) { p["bedrooms"] = .number(0) }
        return p
    }
    static func normalizedText(_ text:String)->String { text.folding(options:[.diacriticInsensitive,.caseInsensitive],locale:Locale(identifier:"vi_VN")).replacingOccurrences(of:"đ",with:"d").trimmingCharacters(in:.whitespacesAndNewlines) }
    struct Duplicate: Identifiable { var property:CRMRecord; var score:Int; var reasons:[String]; var id:String{property.id} }
    static func duplicates(_ p:CRMRecord, in items:[CRMRecord])->[Duplicate] {
        items.filter{$0.id != p.id}.compactMap { x in
            var score = 0; var reasons:[String] = []
            func add(_ yes:Bool,_ points:Int,_ reason:String) { if yes {score += points;reasons.append(reason)} }
            let phone = p.text("owner.phone").filter(\.isNumber)
            add(!phone.isEmpty && phone == x.text("owner.phone").filter(\.isNumber),25,"Cùng SĐT chủ")
            add(normalizedText(p.text("owner.name")) == normalizedText(x.text("owner.name")),15,"Cùng tên chủ")
            add(normalizedText(p.text("location.wardCommune")) == normalizedText(x.text("location.wardCommune")),15,"Cùng khu vực")
            add(p.text("type") == x.text("type"),5,"Cùng loại")
            add(abs((p.number("dimensions.width") ?? 0)-(x.number("dimensions.width") ?? 0)) < 0.3,10,"Ngang tương tự")
            add(abs((p.number("dimensions.length") ?? 0)-(x.number("dimensions.length") ?? 0)) < 1,10,"Dài tương tự")
            let price = p.number("price.amount") ?? 0
            add(abs(price-(x.number("price.amount") ?? 0))/max(price,1) < 0.05,10,"Giá tương tự")
            add(normalizedText(p.title) == normalizedText(x.title),10,"Cùng tiêu đề")
            return score >= 65 ? Duplicate(property:x,score:score,reasons:reasons) : nil
        }.sorted{$0.score > $1.score}
    }
    static func newDraft()->CRMRecord {
        let id = UUID().uuidString
        return CRMRecord(["id":.string(id),"code":.string("BĐS-"+String(id.prefix(6))),"title":.string(""),"type":.string("HOUSE"),"transactionType":.string("SALE"),"status":.string("ACTIVE"),"location":.object(["provinceCity":.string("TP Cần Thơ"),"wardCommune":.string("")]),"price":.object(["unit":.string("VND")]),"media":.object(["images":.array([])]),"createdAt":.string(Database.now),"updatedAt":.string(Database.now)])
    }
}
