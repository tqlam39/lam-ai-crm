import Foundation
import UserNotifications

@MainActor
final class ReminderService {
    static let shared = ReminderService()
    private var queued:[CRMRecord]?
    private var running = false
    func request() async throws->Bool {try await UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.sound,.badge])}
    func refresh(tasks:[CRMRecord]) async -> String? {
        queued = tasks
        guard !running else{return nil}
        running = true;defer{running = false}
        var warning:String?
        while let next = queued {queued = nil;warning = await apply(tasks:next)}
        return warning
    }
    private func apply(tasks:[CRMRecord]) async -> String? {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let old = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers:old.filter{$0.identifier.hasPrefix("crm-task-")}.map(\.identifier))
        guard [.authorized,.provisional,.ephemeral].contains(settings.authorizationStatus) else{return nil}
        do {
            for task in TaskLogic.reminderTasks(tasks) {
                if queued != nil {break}
                let content = UNMutableNotificationContent();content.title = "LẮM AI CRM";content.body = task.title;content.sound = .default;content.userInfo = ["taskId":task.id]
                let date = Database.date(task.text("dueAt"))!
                var components = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second],from:date);components.timeZone = .current
                try await center.add(UNNotificationRequest(identifier:"crm-task-"+task.id,content:content,trigger:UNCalendarNotificationTrigger(dateMatching:components,repeats:false)))
            }
        } catch {return "Dữ liệu đã lưu; không đặt được nhắc lịch: \(error.localizedDescription)"}
        return nil
    }
}
