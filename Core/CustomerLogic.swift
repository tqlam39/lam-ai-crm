import Foundation

enum CustomerLogic {
    static let statuses = ["Đang tìm","Đã tư vấn","Đã xem nhà","Đàm phán","Đã giao dịch","Tạm dừng"]
    static func newCustomer() -> CRMRecord {
        CRMRecord(["id":.string(UUID().uuidString),"name":.string(""),"status":.string("Đang tìm"),"priority":.string("NORMAL"),"createdAt":.string(Database.now),"updatedAt":.string(Database.now)])
    }
    static func newNeed(customerId:String) -> CRMRecord {
        CRMRecord(["id":.string(UUID().uuidString),"customerId":.string(customerId),"status":.string("ACTIVE")])
    }
    static func save(_ customer:CRMRecord, needs:[CRMRecord], into data:inout Database) throws {
        try Validation.require(!customer.title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,"Nhập tên khách hàng.")
        var prepared = needs
        for i in prepared.indices {
            prepared[i]["customerId"] = .string(customer.id)
            for field in ["wardCommunes","provinceCities","legalPreferences","semanticPreferences"] {
                if prepared[i][field] != .null { prepared[i][field] = .array(prepared[i].strings(field).map{$0.trimmingCharacters(in:.whitespacesAndNewlines)}.filter{!$0.isEmpty}.map(JSONValue.string)) }
            }
            try Validation.requirement(prepared[i])
        }
        let oldIDs = Set(data.requirements.map(\.id))
        let editedIDs = Set(prepared.map(\.id))
        try Validation.require(editedIDs.count == prepared.count,"Nhu cầu bị trùng ID.")
        var saved = customer; saved["name"] = .string(customer.title.trimmingCharacters(in:.whitespacesAndNewlines)); saved["updatedAt"] = .string(Database.now)
        data.upsert(saved,into:"customers")
        data.requirements.removeAll{editedIDs.contains($0.id)}
        let fields = ["propertyTypes","directions","wardCommunes","priceMin","priceMax","rawRequirementText","transactionType","widthMin","lengthMin","areaMin","areaMax","bedroomsMin","carAccess","semanticPreferences","legalPreferences","provinceCities"]
        data.requirements += prepared.filter { r in oldIDs.contains(r.id) || fields.contains { key in
            switch r[key] { case .null: return false; case .array(let a): return !a.isEmpty; case .string(let s): return !s.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty; case .bool(let b): return b; default: return true }
        } }
    }
    static func delete(_ id:String, from data:inout Database) {
        data.customers.removeAll{$0.id == id};data.requirements.removeAll{$0.text("customerId") == id}
        for i in data.tasks.indices where data.tasks[i].text("customerId") == id {data.tasks[i]["customerId"] = .null}
    }
    static func phone(_ customer:CRMRecord)->URL? {
        let number = customer.text("phone").filter{$0.isNumber || $0 == "+"}
        guard number.range(of:#"^\+?[0-9]{8,15}$"#,options:.regularExpression) != nil else{return nil}
        return URL(string:"tel:"+number)
    }
    static func zalo(_ customer:CRMRecord)->URL? {
        let raw = (customer.text("zalo").isEmpty ? customer.text("phone") : customer.text("zalo")).trimmingCharacters(in:.whitespacesAndNewlines)
        let number = raw.filter{!" ().-\t\n".contains($0)}
        if number.range(of:#"^\+?[0-9]{8,15}$"#,options:.regularExpression) != nil {
            return URL(string:"https://zalo.me/"+(number.hasPrefix("+84") ? "0"+number.dropFirst(3) : number))
        }
        guard let url = URL(string:raw),url.scheme == "https",url.host == "zalo.me" else{return nil};return url
    }
}
