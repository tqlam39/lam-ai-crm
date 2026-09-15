import Foundation
import UserNotifications

@MainActor
final class ReminderService {
    static let shared = ReminderService()
    private var revision = 0
    func request() async throws->Bool {try await UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.sound,.badge])}
    func refresh(tasks:[CRMRecord]) async -> String? {
        revision += 1;let current = revision
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard current == revision else{return nil}
        let old = await center.pendingNotificationRequests()
        guard current == revision else{return nil}
        center.removePendingNotificationRequests(withIdentifiers:old.filter{$0.identifier.hasPrefix("crm-task-")}.map(\.identifier))
        guard [.authorized,.provisional,.ephemeral].contains(settings.authorizationStatus) else{return nil}
        do {
            for task in TaskLogic.reminderTasks(tasks) {
                guard current == revision else{return nil}
                let content = UNMutableNotificationContent();content.title = "LẮM AI CRM";content.body = task.title;content.sound = .default;content.userInfo = ["taskId":task.id]
                let date = Database.date(task.text("dueAt"))!
                var components = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second],from:date);components.timeZone = .current
                try await center.add(UNNotificationRequest(identifier:"crm-task-"+task.id,content:content,trigger:UNCalendarNotificationTrigger(dateMatching:components,repeats:false)))
            }
        } catch {return "Dữ liệu đã lưu; không đặt được nhắc lịch: \(error.localizedDescription)"}
        return nil
    }
}
