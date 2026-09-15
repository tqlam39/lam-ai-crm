import SwiftUI

struct AISettingsView:View {
    @State private var provider:AIProvider = .groq
    @State private var key = ""
    @State private var model = ""
    @State private var models:[String] = []
    @State private var busy = false
    @State private var message = ""
    var body:some View {
        Form {
            Section("Nhà cung cấp AI") {
                Picker("Dịch vụ",selection:Binding(get:{provider},set:{provider = $0;models = [];model = "";key = ""})) {ForEach(AIProvider.allCases,id:\.self){Text($0.rawValue.capitalized).tag($0)}}
                SecureField("API key",text:$key).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Tải danh sách model") {run {models = try await AIClient.shared.models(provider,key:key);if model.isEmpty {model = models.first ?? ""};message = models.isEmpty ? "Không có model văn bản. Kiểm tra quyền hoặc nhập model thủ công." : "Đã tải \(models.count) model."}}
                if !models.isEmpty {Picker("Model",selection:$model) {ForEach(models,id:\.self){Text($0).tag($0)}}}
                TextField("Tên model (có thể nhập thủ công)",text:$model).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Kiểm tra kết nối và lưu") {run {
                    let credential = AICredential(provider:provider,model:model.trimmingCharacters(in:.whitespacesAndNewlines),key:key.trimmingCharacters(in:.whitespacesAndNewlines))
                    let result = try await AIClient.shared.generate(credential,instruction:"Trả JSON {\"ok\":true} để kiểm tra kết nối.",input:.object(["test":.bool(true)]))
                    try Validation.require(result["ok"].bool == true,"Model chưa trả đúng kết quả kiểm tra.")
                    try AIVault.save(credential);message = "Kết nối thành công. Đã lưu key trong Keychain."
                }}
                Button("Xóa cấu hình AI khỏi máy",role:.destructive) {do {try AIVault.delete();key = "";model = "";models = [];message = "Đã xóa."}catch {message = error.localizedDescription}}
            }.disabled(busy)
            if busy {ProgressView("Đang kết nối…")}
            if !message.isEmpty {Text(message)}
            Section {Text("Key chỉ lưu trên iPhone này, không nằm trong database hoặc bản sao lưu. Nút kiểm tra gửi một yêu cầu nhỏ tới nhà cung cấp; các tác vụ AI cần kết nối mạng.").font(.footnote)}
        }.navigationTitle("API key / model AI")
        .task {do {if let c = try AIVault.read() {provider = c.provider;key = c.key;model = c.model}}catch {message = error.localizedDescription}}
    }
    private func run(_ operation:@escaping @MainActor () async throws->Void) {busy = true;message = "";Task {defer {busy = false};do {try await operation()}catch {message = error.localizedDescription}}}
}
