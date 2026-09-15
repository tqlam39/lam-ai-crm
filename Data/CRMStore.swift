import Foundation
import Combine

@MainActor
final class CRMStore: ObservableObject {
    @Published private(set) var data = Database()
    @Published private(set) var ready = false
    @Published private(set) var busy = false
    @Published private(set) var revision = 0
    @Published var error: String?
    @Published var message: String?
    private var repository: SQLiteRepository?
    private var failedToLoad = false

    init() {
        Task {
            do {
                let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("LamCRM", isDirectory: true)
                let repo = try SQLiteRepository(url: directory.appendingPathComponent("crm.sqlite"))
                let loaded = try await repo.load()
                repository = repo; data = loaded
            } catch { failedToLoad = true; self.error = "Không mở được database. Dữ liệu được giữ nguyên. \(error.localizedDescription)" }
            ready = true
            await refreshReminders()
        }
    }
    func commit(entity: String, action: String, change: (inout Database) throws -> Void) async throws {
        guard ready, !failedToLoad, let repository else { throw CRMError.database("Database chưa sẵn sàng; mở lại app trước khi sửa.") }
        guard !busy else { throw CRMError.database("Đang lưu, vui lòng đợi.") }
        busy = true; defer { busy = false }
        var next = data
        do {
            try change(&next); next.log(entity: entity, action: action)
            try await repository.save(next)
            data = next; revision += 1; message = "Đã lưu trên iPhone"
            await refreshReminders()
        } catch { self.error = error.localizedDescription; throw error }
    }
    func refreshReminders() async {
        if let warning = await ReminderService.shared.refresh(tasks:data.tasks) {message = warning}
    }
}
