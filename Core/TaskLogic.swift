import Foundation

enum TaskLogic {
    static let labels = ["CALL":"Gọi điện","ZALO":"Nhắn Zalo","VIEWING":"Dẫn xem","SEND_PROPERTY":"Gửi BĐS","LEGAL":"Pháp lý","FOLLOW_UP":"Chăm sóc","OTHER":"Khác"]
    static func newTask()->CRMRecord {CRMRecord(["id":.string(UUID().uuidString),"title":.string(""),"type":.string("CALL"),"status":.string("TODO"),"priority":.string("NORMAL")])}
    static func overdue(_ t:CRMRecord,now:Date = Date())->Bool {t.text("status") == "TODO" && (Database.date(t.text("dueAt")) ?? .distantFuture) <= now}
    static func sorted(_ tasks:[CRMRecord],now:Date = Date())->[CRMRecord] {
        func rank(_ t:CRMRecord)->Int {(t.text("status") == "TODO" ? 0 : 100) + ((Database.date(t.text("dueAt")) ?? .distantFuture) < now ? 0 : 10) + (t.text("priority") == "URGENT" ? 0 : t.text("priority") == "HIGH" ? 1 : 2)}
        return tasks.sorted {a,b in
            if rank(a) != rank(b) {return rank(a) < rank(b)}
            let x = Database.date(a.text("dueAt")) ?? .distantFuture, y = Database.date(b.text("dueAt")) ?? .distantFuture
            return x == y ? a.id < b.id : x < y
        }
    }
    static func pending(_ d:Database,now:Date = Date())->[CRMRecord] {
        func tasks(_ c:CRMRecord)->[CRMRecord] {d.tasks.filter{$0.text("customerId") == c.id && $0.text("status") == "TODO"}}
        func due(_ c:CRMRecord)->Date {tasks(c).compactMap{Database.date($0.text("dueAt"))}.min() ?? .distantFuture}
        return d.customers.filter {c in !["Đã giao dịch","Tạm dừng"].contains(c.text("status")) && (c.text("status") == "Đang tìm" || !tasks(c).isEmpty || d.requirements.contains{$0.text("customerId") == c.id && $0.text("status") == "ACTIVE"})}.sorted {a,b in
            if (due(a) <= now) != (due(b) <= now) {return due(a) <= now}
            if tasks(a).isEmpty != tasks(b).isEmpty {return tasks(a).isEmpty}
            return due(a) == due(b) ? a.id < b.id : due(a) < due(b)
        }
    }
    static func reminderTasks(_ tasks:[CRMRecord],now:Date = Date())->[CRMRecord] {
        Array(tasks.filter{$0.text("status") == "TODO" && (Database.date($0.text("dueAt")) ?? .distantPast) > now}.sorted{Database.date($0.text("dueAt"))! < Database.date($1.text("dueAt"))!}.prefix(60))
    }
    static func save(_ record:CRMRecord,into d:inout Database) throws {
        try Validation.require(!record.title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,"Nhập nội dung công việc.")
        try Validation.require(labels[record.text("type")] != nil,"Chọn loại công việc.")
        try Validation.require(["TODO","DONE","CANCELLED"].contains(record.text("status")),"Trạng thái không hợp lệ.")
        if !record.text("dueAt").isEmpty {try Validation.require(Database.date(record.text("dueAt")) != nil,"Ngày hẹn không hợp lệ.")}
        try Validation.require(record.text("customerId").isEmpty || d.customers.contains{$0.id == record.text("customerId")},"Khách không còn tồn tại.")
        try Validation.require(record.text("propertyId").isEmpty || d.properties.contains{$0.id == record.text("propertyId")},"BĐS không còn tồn tại.")
        var saved = record;saved["title"] = .string(record.title.trimmingCharacters(in:.whitespacesAndNewlines));d.upsert(saved,into:"tasks")
    }
    static func toggle(_ id:String,into d:inout Database) throws {
        guard let i = d.tasks.firstIndex(where:{$0.id == id}) else {throw CRMError.invalid("Không tìm thấy công việc.")}
        let done = d.tasks[i].text("status") != "DONE"
        d.tasks[i]["status"] = .string(done ? "DONE" : "TODO");d.tasks[i]["completedAt"] = done ? .string(Database.now) : .null
    }
}
