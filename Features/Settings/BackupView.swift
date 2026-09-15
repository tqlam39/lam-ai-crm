import SwiftUI
import UniformTypeIdentifiers

struct BackupView:View {
    @EnvironmentObject var store:CRMStore
    @State private var includeImages = true
    @State private var document:CRMDocument?
    @State private var contentType = UTType.json
    @State private var filename = "LAM-CRM-backup"
    @State private var exporting = false
    @State private var importing = false
    @State private var preview:Database?
    @State private var replace = false
    @State private var busy = false
    @State private var message = ""
    @AppStorage("crm.lastBackup") private var lastBackup = ""
    var body:some View {
        Form {
            Section("Sao lưu / xuất dữ liệu") {
                Toggle("Kèm ảnh trên máy",isOn:$includeImages)
                Text(includeImages ? "Ảnh lưu trong app được nhúng vào JSON. Ảnh đang là link web vẫn cần mạng." : "Bản này chỉ có database và đường dẫn ảnh; không đủ chuyển ảnh sang điện thoại khác.").font(.footnote)
                Button("Sao lưu JSON → Files / Drive") {exportJSON()}.accessibilityIdentifier("export-backup")
                Button("Xuất quỹ hàng CSV") {document = CRMDocument(data:BackupService.csv(store.data));contentType = .commaSeparatedText;filename = "LAM-CRM-quy-hang";exporting = true}
                Text(lastBackup.isEmpty ? "Chưa ghi nhận lần xuất JSON thành công." : "Lần xuất JSON: "+lastBackup).font(.caption)
                if store.data.properties.contains(where:{$0.text("status") == "OUT_OF_STOCK"}) {Text("Trạng thái Hết hàng là phần mở rộng iOS; bản web cũ có thể chưa hiểu trạng thái này.").font(.footnote)}
            }.disabled(busy || store.busy)
            Section("Khôi phục") {
                Button("Chọn bản JSON từ Files / Drive") {importing = true}.disabled(busy || store.busy)
                if let preview {
                    Text("Bản đã chọn: \(preview.properties.count) BĐS, \(preview.drafts.count) nháp, \(preview.customers.count) khách, \(preview.requirements.count) nhu cầu, \(preview.tasks.count) việc.")
                    Text("\(BackupService.externalImages(preview)) ảnh là link ngoài, cần mạng.")
                    Button("Khôi phục bản đã chọn",role:.destructive) {replace = true}.disabled(busy || store.busy)
                    Button("Bỏ bản đã chọn") {self.preview = nil}
                }
                Text("Khôi phục thay thế database hiện tại. API key không nằm trong bản sao lưu và không bị thay đổi.").font(.footnote)
            }
            Section("Dùng Google Drive trên iPhone") {
                Text("Cài Google Drive và đăng nhập trong ứng dụng Drive. Mở Files (Tệp) → Duyệt → … → Sửa, bật Google Drive. Khi xuất hoặc chọn JSON trong CRM, chọn vị trí Drive. Không cần đăng nhập Firebase.")
                Link("Hướng dẫn Files của Apple",destination:URL(string:"https://support.apple.com/en-gb/102238")!)
            }
            if busy {ProgressView("Đang xử lý dữ liệu…")}
            if !message.isEmpty {Text(message)}
        }.navigationTitle("Sao lưu & khôi phục")
        .fileExporter(isPresented:$exporting,document:document,contentType:contentType,defaultFilename:filename) {result in
            switch result {case .success:message = "Đã xuất file.";if contentType == .json {lastBackup = Date().formatted(date:.abbreviated,time:.shortened)};case .failure:message = "Chưa xuất file. Bạn có thể chọn lại vị trí lưu."}
        }
        .fileImporter(isPresented:$importing,allowedContentTypes:[.json],allowsMultipleSelection:false) {result in
            do {guard let url = try result.get().first else{return};busy = true;Task {defer{busy = false};do {
                preview = try await Task.detached {let accessed = url.startAccessingSecurityScopedResource();defer{if accessed {url.stopAccessingSecurityScopedResource()}};let size = try url.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0;try Validation.require(size <= BackupService.maxBytes,"File quá lớn.");return try BackupService.parse(Data(contentsOf:url))}.value
                message = "Đã kiểm tra cấu trúc. Chưa thay đổi dữ liệu hiện tại."
            }catch{message = error.localizedDescription}}}catch{message = "Chưa chọn file."}
        }
        .confirmationDialog("Thay thế toàn bộ database bằng bản đã chọn?",isPresented:$replace,titleVisibility:.visible) {Button("Xác nhận khôi phục",role:.destructive) {restore()}}
    }
    private func exportJSON() {
        busy = true;message = "";let snapshot = store.data,images = includeImages
        Task {defer{busy = false};do {document = CRMDocument(data:try await BackupService.export(snapshot,includeImages:images));contentType = .json;filename = "LAM-CRM-backup-"+Date().formatted(.iso8601.year().month().day().dateSeparator(.dash));exporting = true}catch{message = error.localizedDescription}}
    }
    private func restore() {
        guard let preview else{return};busy = true;message = ""
        Task {defer{busy = false};do {
            let prepared = try await BackupService.prepareImport(preview)
            try await store.commit(entity:"backup",action:"Khôi phục từ JSON"){$0 = prepared}
            self.preview = nil;message = "Đã khôi phục và cập nhật lịch nhắc."
        }catch{message = error.localizedDescription}}
    }
}
