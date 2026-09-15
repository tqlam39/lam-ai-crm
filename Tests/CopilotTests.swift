import XCTest
@testable import LamAICRM

final class CopilotTests:XCTestCase {
    func testRetrievalUsesActualRecordsAndBudget() {
        var d = Database();let p = CRMRecord(["id":.string("real"),"title":.string("Nhà Phú Lợi"),"type":.string("HOUSE"),"status":.string("ACTIVE"),"price":.object(["amount":.number(1_500_000_000)]),"location":.object(["wardCommune":.string("Phường Phú Lợi")])]);d.properties = [p]
        var query:JSONValue = .object(["intent":.string("properties"),"inventedId":.string("fake"),"filters":.object(["wardCommunes":.array([.string("Phú Lợi")]),"priceMax":.number(2_000_000_000)])])
        XCTAssertEqual(Copilot.search(query,in:d,question:"").properties.map(\.id),["real"])
        query["filters.priceMax"] = .number(1_000_000_000);XCTAssertTrue(Copilot.search(query,in:d,question:"").properties.isEmpty)
        query["intent"] = .string("delete");let before = d;XCTAssertTrue(Copilot.search(query,in:d,question:"").properties.isEmpty);XCTAssertEqual(d,before)
    }
    func testNoFabricatedAnswerForEmptyDatabase() {
        let result = Copilot.search(.object(["intent":.string("properties")]),in:Database(),question:"Tìm nhà")
        XCTAssertTrue(result.properties.isEmpty);XCTAssertTrue(result.message.contains("Không tìm thấy"))
    }
}
