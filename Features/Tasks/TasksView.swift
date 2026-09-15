import SwiftUI
import UIKit

struct TasksView:View {
    @EnvironmentObject var store:CRMStore
    var calendar = false
    var urgent = false
    @State private var status = "TODO"
    @State private var date = Date()
    @State private var permission = ""
    var body:some View {
        ScrollView {LazyVStack(spacing:14) {
            Picker("Trạng thái",selection:$status) {Text("Cần làm").tag("TODO");Text("Hoàn thành").tag("DONE");Text("Tất cả").tag("")}.pickerStyle(.segmented)
            if calendar {DatePicker("Ngày hẹn",selection:$date,displayedComponents:.date).datePickerStyle(.graphical)}
            Button("Bật nhắc lịch trên iPhone") {Task {do {
                if try await ReminderService.shared.request() {permission = "Đã bật nhắc lịch cho tối đa 60 lịch hẹn gần nhất.";await store.refreshReminders()}
                else {permission = "Chưa có quyền thông báo. Bạn vẫn sử dụng công việc bình thường; có thể bật lại trong Cài đặt iPhone."}
            } catch {permission = error.localizedDescription}}}
            if !permission.isEmpty {Text(permission).font(.footnote);Link("Mở Cài đặt iPhone",destination:URL(string:UIApplication.openSettingsURLString)!)}
            let items = TaskLogic.sorted(store.data.tasks.filter {t in
                (status.isEmpty || t.text("status") == status) && (!urgent || (t.text("status") == "TODO" && (TaskLogic.overdue(t) || t.text("priority") == "URGENT"))) && (!calendar || Database.date(t.text("dueAt")).map{Calendar.current.isDate($0,inSameDayAs:date)} == true)
            })
            if items.isEmpty {CRMEmpty(title:"Không có công việc trong mục này")}
            ForEach(items) {TaskCard(record:$0)}
        }.padding(18)}
        .toolbar {ToolbarItem(placement:.topBarTrailing) {NavigationLink {TaskEditor(record:TaskLogic.newTask())} label:{Label("Tạo công việc",systemImage:"plus")}.accessibilityIdentifier("add-task")}}
    }
}

struct TaskCard:View {
    @EnvironmentObject var store:CRMStore
    let record:CRMRecord
    var body:some View {
        CRMPanel {
            HStack {
                Button {Task {do {try await store.commit(entity:record.text("customerId").isEmpty ? record.id : record.text("customerId"),action:record.text("status") == "DONE" ? "Mở lại công việc" : "Hoàn thành công việc"){try TaskLogic.toggle(record.id,into:&$0)}} catch {store.error = error.localizedDescription}}} label:{Image(systemName:record.text("status") == "DONE" ? "checkmark.circle.fill" : "circle").font(.title2)}.disabled(store.busy).accessibilityLabel(record.text("status") == "DONE" ? "Mở lại công việc" : "Hoàn thành công việc")
                NavigationLink {TaskEditor(record:record)} label:{Text(record.title).font(.headline)}
            }
            Text(TaskLogic.labels[record.text("type")] ?? record.text("type")).font(.caption)
            if let due = Database.date(record.text("dueAt")) {Text((TaskLogic.overdue(record) ? "Quá hạn · " : "")+due.formatted(date:.abbreviated,time:.shortened)).foregroundStyle(TaskLogic.overdue(record) ? .red : .secondary)} else {Text("Chưa hẹn giờ").foregroundStyle(.secondary)}
            Text(record.text("note"))
            if record.text("priority") == "URGENT" {Text("Gấp").foregroundStyle(.red)}
            if let c = store.data.customers.first(where:{$0.id == record.text("customerId")}) {NavigationLink("Khách: "+c.title){CustomerDetail(id:c.id)}}
            if let p = store.data.properties.first(where:{$0.id == record.text("propertyId")}) {NavigationLink("BĐS: "+p.title){PropertyReadView(id:p.id)}}
        }
    }
}

struct TaskEditor:View {
    @EnvironmentObject var store:CRMStore
    @Environment(\.dismiss) private var dismiss
    @State var record:CRMRecord
    @State private var scheduled = false
    @State private var date = Date().addingTimeInterval(3600)
    @State private var error = ""
    var body:some View {
        Form {
            TextField("Nội dung *",text:text("title")).autocorrectionDisabled().accessibilityIdentifier("task-title")
            Picker("Loại",selection:text("type")) {ForEach(TaskLogic.labels.keys.sorted(),id:\.self){Text(TaskLogic.labels[$0]!).tag($0)}}
            Picker("Ưu tiên",selection:text("priority")) {Text("Bình thường").tag("NORMAL");Text("Cao").tag("HIGH");Text("Gấp").tag("URGENT")}
            Picker("Trạng thái",selection:text("status")) {Text("Cần làm").tag("TODO");Text("Hoàn thành").tag("DONE");Text("Đã hủy").tag("CANCELLED")}
            Toggle("Hẹn ngày giờ",isOn:$scheduled);if scheduled {DatePicker("Ngày giờ",selection:$date)}
            Picker("Khách",selection:text("customerId")) {Text("Không liên kết").tag("");ForEach(store.data.customers){Text($0.title).tag($0.id)}}
            Picker("BĐS",selection:text("propertyId")) {Text("Không liên kết").tag("");ForEach(store.data.properties){Text($0.title).tag($0.id)}}
            TextField("Ghi chú",text:text("note"),axis:.vertical).lineLimit(3...12)
            if !error.isEmpty {Text(error).foregroundStyle(.red)}
        }.navigationTitle("Công việc / lịch hẹn")
        .onAppear {if let due = Database.date(record.text("dueAt")) {date = due;scheduled = true}}
        .toolbar {ToolbarItem(placement:.confirmationAction) {Button("Lưu") {Task {do {
            record["dueAt"] = scheduled ? .string(ISO8601DateFormatter().string(from:date)) : .null
            record["completedAt"] = record.text("status") == "DONE" ? (record["completedAt"] == .null ? .string(Database.now) : record["completedAt"]) : .null
            try await store.commit(entity:record.text("customerId").isEmpty ? record.id : record.text("customerId"),action:"Lưu công việc"){try TaskLogic.save(record,into:&$0)};dismiss()
        } catch {self.error = error.localizedDescription}}}.disabled(store.busy).accessibilityIdentifier("save-task")}}
    }
    private func text(_ key:String)->Binding<String> {Binding(get:{record.text(key)},set:{record[key] = $0.isEmpty ? .null : .string($0)})}
}
