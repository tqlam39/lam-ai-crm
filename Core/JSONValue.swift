import Foundation

/// Preserves additional fields, nested draft values and integer VND across migrations.
enum JSONValue: Codable, Equatable, Sendable {
    case object([String: JSONValue]), array([JSONValue]), string(String), number(Decimal), bool(Bool), null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(Decimal.self) { self = .number(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode([JSONValue].self) { self = .array(v) }
        else { self = .object(try c.decode([String: JSONValue].self)) }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .object(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }
    var text: String { if case .string(let v) = self { return v }; return "" }
    var decimal: Decimal? { if case .number(let v) = self { return v }; return nil }
    var double: Double? { decimal.map { NSDecimalNumber(decimal: $0).doubleValue } }
    var bool: Bool? { if case .bool(let v) = self { return v }; return nil }
    var array: [JSONValue] { if case .array(let v) = self { return v }; return [] }
    var object: [String: JSONValue] { if case .object(let v) = self { return v }; return [:] }
    func merging(_ newer: JSONValue) -> JSONValue {
        guard case .object(var old) = self, case .object(let changes) = newer else {return newer}
        for (key,value) in changes {old[key] = old[key]?.merging(value) ?? value}
        return .object(old)
    }
    subscript(_ path: String) -> JSONValue {
        get { path.split(separator: ".").reduce(self) { $0.object[String($1)] ?? .null } }
        set {
            let parts = path.split(separator: ".").map(String.init)
            guard let first = parts.first else { return }
            var fields = object
            if parts.count == 1 { fields[first] = newValue == .null ? nil : newValue }
            else { var child = fields[first] ?? .object([:]); child[parts.dropFirst().joined(separator: ".")] = newValue; fields[first] = child }
            self = .object(fields)
        }
    }
}

struct CRMRecord: Codable, Identifiable, Equatable, Sendable {
    var value: JSONValue
    var id: String { value["id"].text }
    init(_ fields: [String: JSONValue]) { value = .object(fields) }
    init(from decoder: Decoder) throws {
        value = try JSONValue(from: decoder)
        guard case .object = value else { throw CRMError.invalid("Bản ghi phải là một đối tượng JSON.") }
    }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
    subscript(_ path: String) -> JSONValue { get { value[path] } set { value[path] = newValue } }
    func text(_ path: String) -> String { self[path].text }
    func number(_ path: String) -> Double? { self[path].double }
    func strings(_ path: String) -> [String] { self[path].array.map(\.text) }
    var title: String { text("title").isEmpty ? text("name") : text("title") }
}

enum CRMError: LocalizedError {
    case invalid(String), database(String)
    var errorDescription: String? {
        switch self { case .invalid(let m), .database(let m): return m }
    }
}

enum Money {
    static func vnd(fromBillions text: String) throws -> Decimal? {
        if text.isEmpty || text == "," || text == "." { return nil }
        guard text.range(of: #"^\d{0,6}([.,]\d{0,9})?$"#, options: .regularExpression) != nil,
              let decimal = Decimal(string: text.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")) else {
            throw CRMError.invalid("Giá không hợp lệ. Ví dụ: 1,5 tỷ.")
        }
        return decimal * 1_000_000_000
    }
    static func billions(_ amount: Decimal?) -> String {
        guard let amount else { return "" }
        return NSDecimalNumber(decimal: amount / 1_000_000_000).stringValue.replacingOccurrences(of: ".", with: ",")
    }
}
