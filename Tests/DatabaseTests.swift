import XCTest
@testable import LamAICRM

final class DatabaseTests: XCTestCase {
    func fixture() throws -> Database {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "web-v1", withExtension: "json"))
        return try JSONDecoder().decode(BackupEnvelope.self, from: Data(contentsOf: url)).data
    }
    func testBackupRetainsUnknownNestedFieldsAndVND() throws {
        var d = try fixture()
        d.properties[0]["owner.extraFutureField"] = .string("Không làm mất")
        d.properties[0]["price.amount"] = .number(1_290_000_001)
        let restored = try JSONDecoder().decode(BackupEnvelope.self, from: JSONEncoder().encode(BackupEnvelope(data:d))).data
        XCTAssertEqual(d, restored)
        XCTAssertEqual(restored.properties[0]["price.amount"].decimal, 1_290_000_001)
    }
    func testSQLiteSaveReopenUpdateDeleteAndRejectedRestore() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("crm.sqlite")
        let first = try SQLiteRepository(url:url)
        var d = try fixture(); try await first.save(d); try await first.close()
        let second = try SQLiteRepository(url:url)
        let loaded = try await second.load(); XCTAssertEqual(loaded,d)
        d.properties[0]["details"] = .string("Mô tả mới\nGiữ xuống dòng")
        d.drafts.append(CRMRecord(["id":.string("draft"),"title":.string("Nháp chưa đủ thông tin")]))
        try await second.save(d)
        var bad = d; bad.customers.append(bad.customers[0])
        do { try await second.save(bad); XCTFail("Phải từ chối ID trùng") } catch {}
        let preserved = try await second.load(); XCTAssertEqual(preserved,d)
        d.drafts.removeAll(); try await second.save(d)
        let deleted = try await second.load(); XCTAssertTrue(deleted.drafts.isEmpty)
        try await second.close()
    }
    func testBadBackupAndRequiredFields() throws {
        let d = try fixture()
        var bad = d; bad.properties[0]["direction"] = .string("")
        XCTAssertThrowsError(try Validation.database(bad))
        bad = d; bad.requirements[0]["customerId"] = .string("missing")
        XCTAssertThrowsError(try Validation.database(bad))
        XCTAssertThrowsError(try JSONDecoder().decode(BackupEnvelope.self,from:Data("{\"schemaVersion\":2}".utf8)))
    }
    func testExactPriceInput() throws {
        XCTAssertEqual(try Money.vnd(fromBillions:"1,5"),1_500_000_000)
        XCTAssertEqual(try Money.vnd(fromBillions:"0,000000001"),1)
        XCTAssertEqual(try Money.vnd(fromBillions:"1.29"),1_290_000_000)
        XCTAssertNil(try Money.vnd(fromBillions:""))
        XCTAssertThrowsError(try Money.vnd(fromBillions:"-2"))
        XCTAssertEqual(try Money.vnd(fromBillions:Money.billions(1_450_000_001)),1_450_000_001)
    }
}
