import Foundation
import SQLite3

/// Record JSON is lossless; searchable columns are derived and rebuilt transactionally.
actor SQLiteRepository {
    private var db: OpaquePointer?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var handle: OpaquePointer?
        guard sqlite3_open_v2(url.path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            if let handle { sqlite3_close(handle) }; throw CRMError.database("Không mở được database. Dữ liệu chưa bị thay đổi.")
        }
        db = handle
        sqlite3_busy_timeout(handle, 5000)
        let schema = """
        PRAGMA journal_mode=WAL;
        PRAGMA foreign_keys=ON;
        CREATE TABLE IF NOT EXISTS records(collection TEXT NOT NULL,id TEXT NOT NULL,json TEXT NOT NULL,position INTEGER NOT NULL,phone TEXT,price REAL,ward TEXT,propertyType TEXT,status TEXT,updatedAt TEXT,PRIMARY KEY(collection,id));
        CREATE TABLE IF NOT EXISTS metadata(key TEXT PRIMARY KEY,value TEXT NOT NULL);
        CREATE INDEX IF NOT EXISTS idx_phone ON records(collection,phone);
        CREATE INDEX IF NOT EXISTS idx_price ON records(collection,price);
        CREATE INDEX IF NOT EXISTS idx_ward ON records(collection,ward);
        CREATE INDEX IF NOT EXISTS idx_type ON records(collection,propertyType);
        CREATE INDEX IF NOT EXISTS idx_status ON records(collection,status);
        CREATE INDEX IF NOT EXISTS idx_updated ON records(collection,updatedAt);
        PRAGMA user_version=1;
        """
        guard sqlite3_exec(handle, schema, nil, nil, nil) == SQLITE_OK else {
            sqlite3_close(handle); db = nil; throw CRMError.database("Không chuẩn bị được database. Không xóa dữ liệu cũ.")
        }
    }
    deinit { if let db { sqlite3_close(db) } }

    private func exec(_ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw CRMError.database("Không ghi được SQLite. Kiểm tra dung lượng thiết bị.") }
    }
    private func statement(_ sql: String) throws -> OpaquePointer {
        var s: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &s, nil) == SQLITE_OK, let s else { throw CRMError.database("Không truy vấn được database.") }
        return s
    }
    private func bind(_ text: String, to s: OpaquePointer, at index: Int32) { sqlite3_bind_text(s, index, text, -1, Self.transient) }
    func load() throws -> Database {
        var result = Database()
        let s = try statement("SELECT collection,json FROM records ORDER BY position ASC")
        defer { sqlite3_finalize(s) }
        var status = sqlite3_step(s)
        while status == SQLITE_ROW {
            let name = String(cString: sqlite3_column_text(s,0))
            let json = String(cString: sqlite3_column_text(s,1))
            result[name].append(try decoder.decode(CRMRecord.self, from: Data(json.utf8)))
            status = sqlite3_step(s)
        }
        guard status == SQLITE_DONE else { throw CRMError.database("Đọc database chưa hoàn tất. Không sửa dữ liệu trước khi mở lại.") }
        let meta = try statement("SELECT value FROM metadata WHERE key='settings'")
        defer { sqlite3_finalize(meta) }
        let step = sqlite3_step(meta)
        if step == SQLITE_ROW { result.settings = try decoder.decode(JSONValue.self, from: Data(String(cString: sqlite3_column_text(meta,0)).utf8)) }
        else if step != SQLITE_DONE { throw CRMError.database("Không đọc được cấu hình.") }
        try Validation.database(result)
        return result
    }
    func save(_ data: Database) throws {
        try Validation.database(data)
        // Serialize before opening a transaction. No partial writes on encoding errors.
        let rows = try Database.collections.flatMap { name in try data[name].enumerated().map { (name, $0.offset, $0.element, String(decoding: try encoder.encode($0.element), as: UTF8.self)) } }
        let settings = String(decoding: try encoder.encode(data.settings), as: UTF8.self)
        try exec("BEGIN IMMEDIATE")
        do {
            try exec("DELETE FROM records")
            let s = try statement("INSERT INTO records(collection,id,json,position,phone,price,ward,propertyType,status,updatedAt) VALUES(?,?,?,?,?,?,?,?,?,?)")
            defer { sqlite3_finalize(s) }
            for (name, position, row, json) in rows {
                sqlite3_reset(s); sqlite3_clear_bindings(s)
                bind(name,to:s,at:1); bind(row.id,to:s,at:2); bind(json,to:s,at:3); sqlite3_bind_int64(s,4,Int64(position))
                bind(row.text(name == "properties" ? "owner.phone" : "phone"),to:s,at:5)
                if let price = row.number("price.amount") { sqlite3_bind_double(s,6,price) } else { sqlite3_bind_null(s,6) }
                bind(row.text("location.wardCommune"),to:s,at:7); bind(row.text("type"),to:s,at:8); bind(row.text("status"),to:s,at:9); bind(row.text("updatedAt"),to:s,at:10)
                guard sqlite3_step(s) == SQLITE_DONE else { throw CRMError.database("Ghi bản ghi thất bại; đã giữ database trước đó.") }
            }
            let m = try statement("INSERT OR REPLACE INTO metadata(key,value) VALUES('settings',?)")
            defer { sqlite3_finalize(m) }; bind(settings,to:m,at:1)
            guard sqlite3_step(m) == SQLITE_DONE else { throw CRMError.database("Không lưu được cấu hình.") }
            try exec("COMMIT")
        } catch { try? exec("ROLLBACK"); throw error }
    }
    func close() throws {
        if let handle = db { guard sqlite3_close(handle) == SQLITE_OK else { throw CRMError.database("Database vẫn đang bận.") }; db = nil }
    }
}
