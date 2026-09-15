import SwiftUI
import Vision
import Speech
import AVFoundation
import UIKit

enum ImageTextReader {
    static func read(_ data:Data) async throws->String {
        guard data.count <= 30_000_000 else {throw CRMError.invalid("Ảnh quá lớn; chọn ảnh dưới 30 MB.")}
        return try await Task.detached(priority:.userInitiated) {
            let request = VNRecognizeTextRequest();request.recognitionLevel = .accurate;request.usesLanguageCorrection = true
            let languages = try request.supportedRecognitionLanguages();request.recognitionLanguages = ["vi-VN","en-US"].filter{languages.contains($0)}
            try VNImageRequestHandler(data:data,options:[:]).perform([request])
            return request.results?.compactMap{$0.topCandidates(1).first?.string}.joined(separator:"\n") ?? ""
        }.value
    }
}

@MainActor final class VoiceIntake:ObservableObject {
    @Published var text = ""
    @Published var recording = false
    @Published var error = ""
    private let engine = AVAudioEngine()
    private var recognition:SFSpeechRecognitionTask?
    private var request:SFSpeechAudioBufferRecognitionRequest?
    private var tapped = false
    private var starting = false
    private var generation = 0
    func start() async {
        guard !recording && !starting else{return}
        starting = true;defer{starting = false};generation += 1;let ticket = generation
        let allowed = await withCheckedContinuation {continuation in SFSpeechRecognizer.requestAuthorization{continuation.resume(returning:$0 == .authorized)}}
        guard generation == ticket else{return}
        let microphone = await AVAudioApplication.requestRecordPermission()
        guard generation == ticket else{return}
        guard allowed && microphone else {error = "Cần quyền micro và nhận dạng giọng nói. Có thể nhập bằng bàn phím.";return}
        guard let recognizer = SFSpeechRecognizer(locale:Locale(identifier:"vi-VN")),recognizer.isAvailable else {error = "Nhận dạng tiếng Việt chưa khả dụng. Thử lại khi có mạng.";return}
        do {
            let audio = AVAudioSession.sharedInstance();try audio.setCategory(.record,mode:.measurement,options:.duckOthers);try audio.setActive(true)
            let input = engine.inputNode,format = input.outputFormat(forBus:0)
            guard format.sampleRate > 0,format.channelCount > 0 else {throw CRMError.invalid("Micro chưa sẵn sàng.")}
            let request = SFSpeechAudioBufferRecognitionRequest();request.shouldReportPartialResults = true;self.request = request
            input.installTap(onBus:0,bufferSize:1024,format:format){buffer,_ in request.append(buffer)};tapped = true
            text = "";error = "";recording = true
            recognition = recognizer.recognitionTask(with:request){[weak self] result,failure in
                Task {@MainActor in
                    if let result {self?.text = result.bestTranscription.formattedString}
                    if result?.isFinal == true || failure != nil {self?.stop()}
                }
            }
            engine.prepare();try engine.start()
        } catch {self.error = "Không bắt đầu được ghi âm. Kiểm tra micro.";stop()}
    }
    func stop() {
        generation += 1
        recording = false;engine.stop();if tapped {engine.inputNode.removeTap(onBus:0);tapped = false}
        request?.endAudio();request = nil;let task = recognition;recognition = nil;task?.cancel()
        try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation)
    }
}

struct CameraCapture:UIViewControllerRepresentable {
    var completed:(Data?)->Void
    func makeCoordinator()->Coordinator {Coordinator(completed:completed)}
    func makeUIViewController(context:Context)->UIImagePickerController {
        let picker = UIImagePickerController();picker.sourceType = .camera;picker.delegate = context.coordinator;return picker
    }
    func updateUIViewController(_ controller:UIImagePickerController,context:Context) {}
    final class Coordinator:NSObject,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
        let completed:(Data?)->Void
        init(completed:@escaping(Data?)->Void) {self.completed = completed}
        func imagePickerControllerDidCancel(_ picker:UIImagePickerController) {completed(nil)}
        func imagePickerController(_ picker:UIImagePickerController,didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey:Any]) {completed((info[.originalImage] as? UIImage)?.jpegData(compressionQuality:0.85))}
    }
}
