import XCTest
@testable import LamAICRM

final class MatchingTests:XCTestCase {
    struct Fixture:Decodable {let property:CRMRecord;let requirement:CRMRecord;let weights:JSONValue;let expected:MatchScore}
    func testGoldenFixturesFromOriginalWebEngine() throws {
        let url = Bundle(for:Self.self).url(forResource:"matching",withExtension:"json")!
        let fixtures = try JSONDecoder().decode([Fixture].self,from:Data(contentsOf:url))
        XCTAssertFalse(fixtures.isEmpty)
        for f in fixtures {XCTAssertEqual(Matching.score(f.property,f.requirement,weights:f.weights),f.expected)}
    }
    func testRecommendationBoundary() {
        XCTAssertFalse(MatchScore(eligible:true,score:69,reasons:[]).recommended)
        XCTAssertTrue(MatchScore(eligible:true,score:70,reasons:[]).recommended)
        XCTAssertFalse(MatchScore(eligible:false,score:100,reasons:[]).recommended)
    }
    func testBothDirectionsDeduplicateMultipleNeeds() throws {
        let url = Bundle(for:Self.self).url(forResource:"matching",withExtension:"json")!
        let fixtures = try JSONDecoder().decode([Fixture].self,from:Data(contentsOf:url))
        let f = try XCTUnwrap(fixtures.first{$0.expected.recommended})
        var c = CustomerLogic.newCustomer();c["name"] = .string("Test")
        var need = f.requirement;need["customerId"] = .string(c.id)
        var other = need;other["id"] = .string(UUID().uuidString)
        var d = Database();d.properties = [f.property];d.customers = [c];d.requirements = [need,other];d.settings["weights"] = f.weights
        XCTAssertEqual(Matching.pairs(d,customerId:c.id).count,1);XCTAssertEqual(Matching.pairs(d,propertyId:f.property.id).count,1)
        d.customers[0]["status"] = .string("Tạm dừng");XCTAssertTrue(Matching.pairs(d).isEmpty)
    }
}
