import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct CRMDocument:FileDocument {
    static var readableContentTypes:[UTType] {[.json,.commaSeparatedText]}
    var data:Data
    init(data:Data) {self.data = data}
    init(configuration:ReadConfiguration)throws {data = configuration.file.regularFileContents ?? Data()}
    func fileWrapper(configuration:WriteConfiguration)throws->FileWrapper {FileWrapper(regularFileWithContents:data)}
}
enum BackupService {
    static let maxBytes = 150_000_000
    static func parse(_ bytes:Data)throws->Database {
        try Validation.require(bytes.count <= maxBytes,"Bản sao lưu vượt 150 MB.")
        do {return try JSONDecoder().decode(BackupEnvelope.self,from:bytes).data}
        catch let error as CRMError {throw error}
        catch {throw CRMError.invalid("File không phải bản sao lưu JSON CRM V1 hợp lệ.")}
    }
    static func export(_ source:Database,includeImages:Bool)async throws->Data {
        try await Task.detached(priority:.userInitiated) {
            var data = source
            if includeImages {
                for collection in ["properties","drafts"] {for i in data[collection].indices {
                    var record = data[collection][i];var images = record["media.images"].array
                    for j in images.indices {
                        let reference = images[j]["url"].text
                        if reference.hasPrefix("crm-media/") {
                            guard let url = MediaFiles.url(reference),let image = try? Data(contentsOf:url) else {throw CRMError.invalid("Thiếu ảnh trên máy; chưa tạo bản sao lưu. Kiểm tra BĐS: "+record.title)}
                            images[j]["url"] = .string("data:image/jpeg;base64,"+image.base64EncodedString())
                        }
                    }
                    if record["media.images"] != .null {record["media.images"] = .array(images)}
                    data[collection][i] = record
                }}
            }
            let encoder = JSONEncoder();encoder.outputFormatting = [.sortedKeys]
            let bytes = try encoder.encode(BackupEnvelope(data:data))
            try Validation.require(bytes.count <= maxBytes,"Bản sao lưu vượt 150 MB. Chọn ít ảnh hơn hoặc xuất database không kèm ảnh.")
            return bytes
        }.value
    }
    @MainActor static func prepareImport(_ source:Database)async throws->Database {
        try Validation.database(source)
        var data = source
        for collection in ["properties","drafts"] {for i in data[collection].indices {
            var record = data[collection][i];var images = record["media.images"].array
            for j in images.indices {
                let reference = images[j]["url"].text
                if reference.hasPrefix("data:") {
                    let parts = reference.split(separator:",",maxSplits:1).map(String.init)
                    guard parts.count == 2,["data:image/jpeg;base64","data:image/png;base64","data:image/webp;base64"].contains(parts[0]),let bytes = Data(base64Encoded:parts[1]) else {throw CRMError.invalid("Ảnh nhúng trong bản sao lưu không hợp lệ.")}
                    images[j]["url"] = try MediaFiles.saveImage(bytes)["url"]
                    await Task.yield()
                } else if reference.hasPrefix("crm-media/") {
                    guard let url = MediaFiles.url(reference),FileManager.default.fileExists(atPath:url.path) else {throw CRMError.invalid("Bản sao lưu chỉ có đường dẫn ảnh, nhưng ảnh không có trên iPhone này. Chọn bản sao lưu kèm ảnh.")}
                }
            }
            if record["media.images"] != .null {record["media.images"] = .array(images)}
            data[collection][i] = record
        }}
        return data
    }
    static func externalImages(_ data:Database)->Int {(data.properties+data.drafts).flatMap{$0["media.images"].array}.filter{let url = $0["url"].text;return url.hasPrefix("http://") || url.hasPrefix("https://")}.count}
    static func csv(_ data:Database)->Data {
        func cell(_ value:String)->String {let unsafe = value.trimmingCharacters(in:.whitespacesAndNewlines).first.map{"=+@-".contains($0)} ?? false;return "\""+(unsafe ? "'" : "")+value.replacingOccurrences(of:"\"",with:"\"\"")+"\""}
        var rows = [["Mã","Tiêu đề","Khu vực","Giá VND","Ngang","Dài","Trạng thái"]]
        rows += data.properties.map {p in [p.text("code"),p.title,p.text("location.wardCommune"),p["price.amount"].decimal.map{NSDecimalNumber(decimal:$0).stringValue} ?? "",p["dimensions.width"].decimal.map{NSDecimalNumber(decimal:$0).stringValue} ?? "",p["dimensions.length"].decimal.map{NSDecimalNumber(decimal:$0).stringValue} ?? "",p.text("status")]}
        return Data(("\u{FEFF}"+rows.map{$0.map(cell).joined(separator:",")}.joined(separator:"\r\n")).utf8)
    }
}
