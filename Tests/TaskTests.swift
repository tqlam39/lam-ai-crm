import XCTest
@testable import LamAICRM

final class TaskTests:XCTestCase {
    func testCompletionReopenAndReminderEligibility() throws {
        var d = Database();var task = TaskLogic.newTask();task["title"] = .string("Hẹn xem")
        task["dueAt"] = .string(ISO8601DateFormatter().string(from:Date().addingTimeInterval(3600)))
        try TaskLogic.save(task,into:&d);XCTAssertEqual(TaskLogic.reminderTasks(d.tasks).count,1)
        try TaskLogic.toggle(task.id,into:&d);XCTAssertEqual(d.tasks[0].text("status"),"DONE");XCTAssertFalse(d.tasks[0].text("completedAt").isEmpty);XCTAssertTrue(TaskLogic.reminderTasks(d.tasks).isEmpty)
        try TaskLogic.toggle(task.id,into:&d);XCTAssertEqual(d.tasks[0]["completedAt"],.null);XCTAssertEqual(TaskLogic.reminderTasks(d.tasks).count,1)
        task["customerId"] = .string("missing");let before = d
        XCTAssertThrowsError(try TaskLogic.save(task,into:&d));XCTAssertEqual(d,before)
    }
    func testPendingCustomersExcludeClosedAndPrioritizeOverdue() throws {
        var d = Database();var a = CustomerLogic.newCustomer();a["name"] = .string("Chưa hẹn")
        var b = CustomerLogic.newCustomer();b["name"] = .string("Quá hạn")
        var c = CustomerLogic.newCustomer();c["name"] = .string("Đã giao dịch");c["status"] = .string("Đã giao dịch")
        d.customers = [a,b,c]
        var t = TaskLogic.newTask();t["title"] = .string("Gọi");t["customerId"] = .string(b.id);t["dueAt"] = .string("2020-01-01T00:00:00Z");d.tasks = [t]
        XCTAssertEqual(TaskLogic.pending(d).map(\.id),[b.id,a.id]);XCTAssertTrue(TaskLogic.reminderTasks(d.tasks).isEmpty)
    }
}
