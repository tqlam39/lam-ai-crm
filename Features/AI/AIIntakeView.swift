import SwiftUI
import PhotosUI
import AVFoundation

struct AIIntakeView:View {
    @EnvironmentObject var store:CRMStore
    @StateObject private var voice = VoiceIntake()
    @State private var text = ""
    @State private var url = ""
    @State private var kind = "property"
    @State private var photo:PhotosPickerItem?
    @State private var camera = false
    @State private var busy = false
    @State private var message = ""
    @State private var preview:CRMRecord?
    @State private var previewKind = "property"
    @State private var voiceBase = ""
    var body:some View {
        Form {
            Section {
                NavigationLink("Hỏi CRM bằng ngôn ngữ tự nhiên") {CopilotView()}
                NavigationLink("API key / model AI") {AISettingsView()}
                Picker("Trích xuất",selection:$kind) {Text("Bất động sản").tag("property");Text("Nhu cầu khách").tag("need")}.pickerStyle(.segmented)
                Text("Nội dung gửi tới dịch vụ AI bạn chọn. Kiểm tra và chỉnh sửa kết quả trước khi lưu.").font(.footnote)
            }
            Section("Nhập nhanh từ link công khai") {
                TextField("Link web / bài Facebook công khai",text:$url).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Đọc nội dung link") {run {text = try await PublicLinkReader.read(url);preview = nil;message = "Đã lấy nội dung. Kiểm tra trước khi trích xuất."}}
            }.disabled(busy)
            Section("Nội dung / mô tả chi tiết") {
                TextEditor(text:$text).frame(minHeight:180).accessibilityIdentifier("ai-input")
                HStack {
                    PhotosPicker(selection:$photo,matching:.images) {Label("Đọc ảnh",systemImage:"photo")}
                    Button {Task {
                        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {message = "Máy này không có camera. Bạn có thể chọn ảnh.";return}
                        if await AVCaptureDevice.requestAccess(for:.video) {camera = true}else{message = "Cần quyền camera trong Cài đặt iPhone."}
                    }} label:{Label("Camera",systemImage:"camera")}
                }.disabled(busy)
                Button {if voice.recording {voice.stop()}else{voiceBase = text;Task {await voice.start()}}} label:{Label(voice.recording ? "Dừng ghi âm" : "Nhập giọng nói",systemImage:voice.recording ? "stop.circle.fill" : "mic")}.disabled(busy)
                if !voice.error.isEmpty {Text(voice.error).foregroundStyle(.red)}
                Button("Trích xuất bằng AI") {extract()}.disabled(busy || voice.recording || text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
            }
            if busy {ProgressView("Đang xử lý…")}
            if !message.isEmpty {Text(message).font(.footnote)}
            if let preview {
                Section("Kết quả — chưa lưu") {
                    if previewKind == "property" {
                        Text(preview.title.isEmpty ? "Bản nháp thiếu tiêu đề" : preview.title)
                        NavigationLink("Kiểm tra / sửa / lưu BĐS") {PropertyEditor(record:preview)}
                    } else {NeedSummary(record:preview);NavigationLink("Chọn khách / sửa / lưu nhu cầu") {RequirementEditor(record:preview)}}
                }
            }
        }.onChange(of:photo) {_,item in if let item {run {if let data = try await item.loadTransferable(type:Data.self) {try await appendOCR(data)}}}}
        .onChange(of:text) {_,_ in preview = nil}
        .onChange(of:voice.text) {_,value in if !value.isEmpty {text = [voiceBase,value].filter{!$0.isEmpty}.joined(separator:"\n");preview = nil}}
        .onDisappear {voice.stop()}
        .sheet(isPresented:$camera) {CameraCapture {data in camera = false;if let data {run {try await appendOCR(data)}}}.ignoresSafeArea()}
    }
    private func appendOCR(_ data:Data)async throws {
        let found = try await ImageTextReader.read(data)
        try Validation.require(!found.isEmpty,"Không đọc được chữ trong ảnh. Thử ảnh rõ hơn.")
        text = [text,found].filter{!$0.isEmpty}.joined(separator:"\n");preview = nil;message = "Đã đọc chữ. Ảnh này không tự thêm vào ảnh BĐS."
    }
    private func run(_ operation:@escaping @MainActor ()async throws->Void) {busy = true;message = "";Task {defer{busy = false};do {try await operation()}catch{message = error is CRMError ? error.localizedDescription : "Không xử lý được dữ liệu. Thử lại hoặc dán nội dung trực tiếp."}}}
    private func extract() {
        let source = text,sourceURL = url,type = kind
        run {
            guard let config = try AIVault.read() else {throw CRMError.invalid("Vào API key / model AI để cấu hình trước.")}
            try Validation.require(source.count <= 30000,"Nội dung tối đa 30.000 ký tự; chia tin dài thành từng phần.")
            let result = try await AIClient.shared.generate(config,instruction:type == "property" ? AIIntake.propertyPrompt : AIIntake.needPrompt,input:.object(["text":.string(source)]))
            previewKind = type
            if type == "property" {preview = AIIntake.property(result,text:source,url:sourceURL)}
            else {var r = CustomerLogic.newNeed(customerId:"");r.value = r.value.merging(result);r["id"] = .string(UUID().uuidString);r["customerId"] = .string("");r["status"] = .string("ACTIVE");r["rawRequirementText"] = .string(source);preview = r}
            message = "Đã trích xuất. Kiểm tra các thông tin thiếu hoặc sai trước khi lưu."
        }
    }
}
