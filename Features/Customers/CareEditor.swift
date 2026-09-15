import SwiftUI

struct CareEditor:View {
    @EnvironmentObject var store:CRMStore
    @Environment(\.dismiss) private var dismiss
    let customerId:String
    @State private var type = "CALL"
    @State private var propertyId = ""
    @State private var taskId = ""
    @State private var note = ""
    @State private var followUp = false
    @State private var nextAt = Date().addingTimeInterval(86400)
    @State private var error = ""
    var body:some View {
        Form {
            Section("Kết quả chăm sóc") {
                Text("Chỉ lưu sau khi đã liên hệ. Bấm gọi hoặc mở Zalo không tự đánh dấu đã chăm sóc.").font(.footnote)
                Picker("Hình thức",selection:$type) {Text("Gọi điện").tag("CALL");Text("Zalo").tag("ZALO");Text("Xem BĐS").tag("VIEWING");Text("Gửi sản phẩm").tag("SEND_PROPERTY");Text("Pháp lý").tag("LEGAL");Text("Theo dõi").tag("FOLLOW_UP");Text("Khác").tag("OTHER")}
                Picker("Công việc đã hoàn thành",selection:$taskId) {Text("Ghi nhận lần chăm sóc mới").tag("");ForEach(store.data.tasks.filter{$0.text("customerId") == customerId && $0.text("status") == "TODO"}) {Text($0.title).tag($0.id)}}
                Picker("BĐS liên quan",selection:$propertyId) {Text("Không chọn").tag("");ForEach(store.data.properties){Text($0.title).tag($0.id)}}
                TextField("Kết quả / ghi chú *",text:$note,axis:.vertical).lineLimit(4...12)
            }
            Section("Chăm sóc tiếp") {Toggle("Tạo lịch hẹn tiếp theo",isOn:$followUp);if followUp {DatePicker("Ngày giờ",selection:$nextAt)}}
            if !error.isEmpty {Text(error).foregroundStyle(.red)}
        }.navigationTitle("Ghi nhận chăm sóc")
        .toolbar {ToolbarItem(placement:.confirmationAction) {Button("Lưu") {Task {do {
            try await store.commit(entity:customerId,action:"Chăm sóc: "+note) {try CustomerLogic.recordCare(customerId:customerId,propertyId:propertyId,type:type,note:note,nextAt:followUp ? nextAt : nil,completeTaskId:taskId,into:&$0)};dismiss()
        } catch {self.error = error.localizedDescription}}}.disabled(store.busy)}}
    }
}
