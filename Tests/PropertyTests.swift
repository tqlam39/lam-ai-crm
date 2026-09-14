import XCTest
@testable import LamAICRM

final class PropertyTests:XCTestCase {
    func fixture() throws -> CRMRecord {
        let url = try XCTUnwrap(Bundle(for:Self.self).url(forResource:"web-v1",withExtension:"json"))
        return try JSONDecoder().decode(BackupEnvelope.self,from:Data(contentsOf:url)).data.properties[0]
    }
    func testDuplicateScoreAndIdentity() throws {
        let p = try fixture();var copy = p;copy["id"] = .string("other")
        XCTAssertTrue(PropertyLogic.duplicates(p,in:[p]).isEmpty)
        XCTAssertEqual(PropertyLogic.duplicates(copy,in:[p]).first?.score,75)
    }
    func testNormalizationAndSoldPriceRemainSeparate() throws {
        var p = try fixture();p["title"] = .string(" Nhà mới ");p["status"] = .string("SOLD")
        XCTAssertThrowsError(try Validation.property(p))
        p["soldInfo"] = .object(["soldAt":.string("2026-09-15"),"actualSoldPrice":.number(1_400_000_000)])
        try Validation.property(p)
        let n = PropertyLogic.normalize(p)
        XCTAssertEqual(n.title,"Nhà mới");XCTAssertEqual(n.number("dimensions.calculatedArea"),120)
        XCTAssertEqual(n.number("price.amount"),1_450_000_000)
        XCTAssertEqual(n.number("soldInfo.actualSoldPrice"),1_400_000_000)
    }
    func testDraftCanRemainIncompleteWithoutBecomingProperty() throws {
        var d = Database();d.drafts = [PropertyLogic.newDraft()]
        try Validation.database(d)
        d.properties = d.drafts
        XCTAssertThrowsError(try Validation.database(d))
    }
}
