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
    static func recordCare(customerId:String,propertyId:String = "",type:String,note:String,nextAt:Date?,completeTaskId:String = "",into data:inout Database,now:Date = Date()) throws {
        guard let customer = data.customers.first(where:{$0.id == customerId}) else {throw CRMError.invalid("Không tìm thấy khách hàng.")}
        let note = note.trimmingCharacters(in:.whitespacesAndNewlines)
        try Validation.require(!note.isEmpty,"Nhập kết quả hoặc ghi chú chăm sóc.")
        if let nextAt {try Validation.require(nextAt > now,"Lịch chăm sóc tiếp theo phải ở tương lai.")}
        try Validation.require(propertyId.isEmpty || data.properties.contains{$0.id == propertyId},"Không tìm thấy BĐS.")
        let existing = data.tasks.firstIndex{$0.id == completeTaskId && $0.text("customerId") == customerId && $0.text("status") == "TODO"}
        try Validation.require(completeTaskId.isEmpty || existing != nil,"Công việc đã thay đổi, vui lòng chọn lại.")
        let timestamp = ISO8601DateFormatter().string(from:now)
        let linkedProperty = propertyId.isEmpty ? existing.map{data.tasks[$0].text("propertyId")} ?? "" : propertyId
        if let existing {
            data.tasks[existing]["status"] = .string("DONE");data.tasks[existing]["completedAt"] = .string(timestamp)
            data.tasks[existing]["note"] = .string([data.tasks[existing].text("note"),note].filter{!$0.isEmpty}.joined(separator:"\n"))
        } else {
            var task = CRMRecord(["id":.string(UUID().uuidString),"title":.string("Chăm sóc "+customer.title),"type":.string(type),"customerId":.string(customerId),"status":.string("DONE"),"priority":customer["priority"],"note":.string(note),"completedAt":.string(timestamp)])
            if !propertyId.isEmpty {task["propertyId"] = .string(propertyId)};data.tasks.insert(task,at:0)
        }
        if let nextAt {
            var task = CRMRecord(["id":.string(UUID().uuidString),"title":.string("Chăm sóc tiếp "+customer.title),"type":.string("FOLLOW_UP"),"customerId":.string(customerId),"status":.string("TODO"),"priority":customer["priority"],"note":.string(note),"dueAt":.string(ISO8601DateFormatter().string(from:nextAt))])
            if !linkedProperty.isEmpty {task["propertyId"] = .string(linkedProperty)};data.tasks.insert(task,at:0)
        }
        if let i = data.customers.firstIndex(where:{$0.id == customerId}) {data.customers[i]["updatedAt"] = .string(timestamp)}
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
