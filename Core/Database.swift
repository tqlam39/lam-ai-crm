import Foundation

struct Database: Codable, Equatable, Sendable {
    static let collections = ["properties", "drafts", "customers", "requirements", "tasks", "activities"]
    var properties: [CRMRecord] = []
    var drafts: [CRMRecord] = []
    var customers: [CRMRecord] = []
    var requirements: [CRMRecord] = []
    var tasks: [CRMRecord] = []
    var activities: [CRMRecord] = []
    var settings: JSONValue = .object([
        "brand": .string("Lắm BĐS Sóc Trăng"), "phone": .string("0946 261 719"),
        "favoriteAreas": .array(["Phường Phú Lợi", "Phường Mỹ Xuyên", "Phường Sóc Trăng", "Xã Trần Đề"].map(JSONValue.string)),
        "weights": .object(["area":25,"price":20,"type":15,"dimensions":10,"bedrooms":10,"direction":5,"legal":5,"car":5,"semantic":5].mapValues { .number(Decimal($0)) })
    ])
    subscript(_ collection: String) -> [CRMRecord] {
        get { switch collection {
        case "properties": return properties; case "drafts": return drafts; case "customers": return customers
        case "requirements": return requirements; case "tasks": return tasks; case "activities": return activities; default: return []
        } }
        set { switch collection {
        case "properties": properties = newValue; case "drafts": drafts = newValue; case "customers": customers = newValue
        case "requirements": requirements = newValue; case "tasks": tasks = newValue; case "activities": activities = newValue; default: break
        } }
    }
    mutating func upsert(_ record: CRMRecord, into collection: String) {
        self[collection].removeAll { $0.id == record.id }
        self[collection].insert(record, at: 0)
    }
    mutating func log(entity: String, action: String) {
        activities.insert(CRMRecord(["id": .string(UUID().uuidString), "entityId": .string(entity), "action": .string(action), "at": .string(Self.now)]), at: 0)
    }
    static var now: String { ISO8601DateFormatter().string(from: Date()) }
    static func date(_ text: String) -> Date? {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = f.date(from: text) { return date }
        f.formatOptions = [.withInternetDateTime]
        if let date = f.date(from: text) { return date }
        let short = DateFormatter(); short.locale = Locale(identifier: "en_US_POSIX"); short.timeZone = TimeZone(secondsFromGMT: 0); short.dateFormat = "yyyy-MM-dd"
        return short.date(from: text)
    }
}

struct BackupEnvelope: Codable {
    var schemaVersion = 1
    var exportedAt = Database.now
    var platform = "ios"
    var data: Database
    enum CodingKeys: String, CodingKey { case schemaVersion, exportedAt, platform, data }
    init(data: Database) { self.data = data }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        guard schemaVersion == 1 else { throw CRMError.invalid("Chỉ nhận bản sao lưu CRM V1.") }
        exportedAt = try c.decodeIfPresent(String.self, forKey: .exportedAt) ?? ""
        platform = try c.decodeIfPresent(String.self, forKey: .platform) ?? "web"
        data = try c.decode(Database.self, forKey: .data)
        try Validation.database(data)
    }
}

enum Validation {
    static let propertyTypes = ["HOUSE", "LAND", "AGRICULTURAL_LAND", "WAREHOUSE"]
    static let directions = ["E", "S", "W", "N", "NW", "SW", "NE", "SE"]
    static func require(_ condition: Bool, _ message: String) throws { if !condition { throw CRMError.invalid(message) } }
    static func property(_ p: CRMRecord) throws {
        for (field,label) in [("title","tiêu đề"),("location.provinceCity","tỉnh/thành"),("location.wardCommune","phường/xã"),("owner.name","chủ sở hữu")] {
            try require(!p.text(field).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Nhập \(label).")
        }
        try require(propertyTypes.contains(p.text("type")), "Chọn loại BĐS.")
        try require(["SALE","RENT"].contains(p.text("transactionType")), "Chọn giao dịch.")
        try require(["ACTIVE","SOLD","PAUSED","OUT_OF_STOCK"].contains(p.text("status")), "Chọn trạng thái.")
        try require(directions.contains(p.text("direction")), "Chọn hướng.")
        for field in ["dimensions.width","dimensions.length","price.amount"] { try require((p.number(field) ?? 0) > 0, "Ngang, dài và giá phải lớn hơn 0.") }
        try require(p.text("price.unit") == "VND", "Giá lưu phải dùng VNĐ.")
        let bedrooms = p.number("bedrooms") ?? -1
        try require(bedrooms >= 0 && bedrooms.rounded() == bedrooms, "Số phòng ngủ phải là số nguyên không âm.")
        if ["LAND","AGRICULTURAL_LAND"].contains(p.text("type")) { try require(bedrooms == 0, "Đất có số phòng ngủ bằng 0.") }
        try require(!p["media.images"].array.isEmpty, "Cần ít nhất một ảnh BĐS.")
        for image in p["media.images"].array { try require(!image["id"].text.isEmpty && !image["url"].text.isEmpty, "Ảnh thiếu ID hoặc đường dẫn.") }
        if let lat = p.number("location.latitude") { try require((-90...90).contains(lat), "Vĩ độ không hợp lệ.") }
        if let lon = p.number("location.longitude") { try require((-180...180).contains(lon), "Kinh độ không hợp lệ.") }
        if p["legal.certificateStatus"] != .null { try require(["RED_BOOK","NO_CERTIFICATE"].contains(p.text("legal.certificateStatus")), "Pháp lý không hợp lệ.") }
        if p.text("status") == "SOLD" { try require(!p.text("soldInfo.soldAt").isEmpty && (p.number("soldInfo.actualSoldPrice") ?? 0) > 0, "Nhập ngày và giá bán thực tế.") }
    }
    static func requirement(_ r: CRMRecord) throws {
        try require(!r.text("customerId").isEmpty, "Chọn khách hàng.")
        try require(["ACTIVE","PAUSED","FULFILLED"].contains(r.text("status")),"Trạng thái nhu cầu không hợp lệ.")
        if r["transactionType"] != .null {try require(["SALE","RENT"].contains(r.text("transactionType")),"Giao dịch nhu cầu không hợp lệ.")}
        for (key,allowed) in [("propertyTypes",propertyTypes),("directions",directions)] where r[key] != .null {
            guard case .array(let items) = r[key],items.allSatisfy({allowed.contains($0.text)}) else {throw CRMError.invalid("Loại BĐS hoặc hướng nhu cầu không hợp lệ.")}
        }
        for key in ["provinceCities","wardCommunes","legalPreferences","semanticPreferences"] where r[key] != .null {
            guard case .array(let items) = r[key],items.allSatisfy({if case .string = $0 {return true};return false}) else {throw CRMError.invalid("Khu vực / ưu tiên phải là danh sách văn bản.")}
        }
        if r["carAccess"] != .null {try require(r["carAccess"].bool != nil,"Điều kiện đường ô tô không hợp lệ.")}
        for key in ["priceMin","priceMax","widthMin","lengthMin","areaMin","areaMax","bedroomsMin"] where r[key] != .null {
            try require(r.number(key) != nil && (r.number(key) ?? -1) >= 0,"Thông tin giá / kích thước phải là số không âm hoặc bỏ trống.")
        }
        if let beds = r.number("bedroomsMin") {try require(beds.rounded() == beds,"Số phòng ngủ phải là số nguyên.")}
        if let min = r.number("priceMin") { try require(min >= 0, "Ngân sách từ không âm.") }
        if let max = r.number("priceMax") { try require(max > 0, "Ngân sách đến phải lớn hơn 0.") }
        if let min = r.number("priceMin"), let max = r.number("priceMax") { try require(min <= max, "Ngân sách từ không lớn hơn đến.") }
        if let min = r.number("areaMin"), let max = r.number("areaMax") { try require(min <= max, "Diện tích từ không lớn hơn đến.") }
    }
    static func database(_ d: Database) throws {
        for collection in Database.collections {
            let records = d[collection]
            try require(records.allSatisfy { !$0.id.isEmpty } && Set(records.map(\.id)).count == records.count, "ID trùng hoặc không hợp lệ trong \(collection).")
        }
        try d.properties.forEach(property)
        for c in d.customers { try require(!c.text("name").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Nhập tên khách.") }
        for r in d.requirements { try requirement(r); try require(d.customers.contains { $0.id == r.text("customerId") }, "Nhu cầu thiếu khách liên kết.") }
        for t in d.tasks {
            try require(!t.text("title").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Nhập nội dung công việc.")
            try require(["TODO","DONE","CANCELLED"].contains(t.text("status")), "Trạng thái công việc không hợp lệ.")
        }
        guard case .string = d.settings["brand"], case .array = d.settings["favoriteAreas"], case .object(let weights) = d.settings["weights"] else { throw CRMError.invalid("Cấu hình không hợp lệ.") }
        try require(weights.values.allSatisfy { ($0.double ?? -1) >= 0 }, "Trọng số phải là số không âm.")
    }
}
