import XCTest
@testable import LamAICRM

final class CustomerTests:XCTestCase {
    func testBlankNeedsAndRepeatedSaveDoNotDuplicateCustomer() throws {
        var d = Database();var c = CustomerLogic.newCustomer();c["name"] = .string("Khách A")
        let blank = CustomerLogic.newNeed(customerId:c.id)
        try CustomerLogic.save(c,needs:[blank],into:&d)
        XCTAssertEqual(d.customers.count,1);XCTAssertTrue(d.requirements.isEmpty)
        var need = blank;need["priceMin"] = .number(1_000_000_000);need["priceMax"] = .number(1_500_000_000)
        try CustomerLogic.save(c,needs:[need],into:&d);try CustomerLogic.save(c,needs:[need],into:&d)
        XCTAssertEqual(d.customers.count,1);XCTAssertEqual(d.requirements.count,1)
        var other = CustomerLogic.newNeed(customerId:c.id);other["rawRequirementText"] = .string("Kho xưởng")
        try CustomerLogic.save(c,needs:[other],into:&d);XCTAssertEqual(d.requirements.count,2)
        let before = d;need["priceMin"] = .number(2_000_000_000)
        XCTAssertThrowsError(try CustomerLogic.save(c,needs:[need],into:&d));XCTAssertEqual(d,before)
        need["priceMin"] = .string("abc");XCTAssertThrowsError(try CustomerLogic.save(c,needs:[need],into:&d))
    }
    func testDeleteUnlinksTasksWithoutDeletingHistory() throws {
        var d = Database();var c = CustomerLogic.newCustomer();c["name"] = .string("A")
        try CustomerLogic.save(c,needs:[],into:&d)
        d.tasks = [CRMRecord(["id":.string("task"),"title":.string("Gọi khách"),"customerId":.string(c.id),"status":.string("TODO")])]
        d.log(entity:c.id,action:"Ghi chú cũ");CustomerLogic.delete(c.id,from:&d)
        XCTAssertTrue(d.customers.isEmpty);XCTAssertEqual(d.tasks.count,1);XCTAssertEqual(d.tasks[0]["customerId"],.null);XCTAssertEqual(d.activities.count,1)
    }
    func testContactLinksValidateDestination() {
        var c = CustomerLogic.newCustomer();c["phone"] = .string("+84 946 261 719")
        XCTAssertEqual(CustomerLogic.phone(c)?.absoluteString,"tel:+84946261719")
        XCTAssertEqual(CustomerLogic.zalo(c)?.absoluteString,"https://zalo.me/0946261719")
        c["zalo"] = .string("https://zalo.me.evil.example/name");XCTAssertNil(CustomerLogic.zalo(c))
        c["phone"] = .string("123");XCTAssertNil(CustomerLogic.phone(c))
    }
}
