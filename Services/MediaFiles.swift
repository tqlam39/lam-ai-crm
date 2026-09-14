import SwiftUI
import PhotosUI

enum MediaFiles {
    static func directory() throws -> URL {
        let base = try FileManager.default.url(for:.applicationSupportDirectory,in:.userDomainMask,appropriateFor:nil,create:true).appendingPathComponent("LamCRM/Media",isDirectory:true)
        try FileManager.default.createDirectory(at:base,withIntermediateDirectories:true)
        return base
    }
    static func url(_ reference:String)->URL? {
        guard reference.hasPrefix("crm-media/"), reference.dropFirst(10).range(of:#"^[A-Za-z0-9-]+\.jpg$"#,options:.regularExpression) != nil else {return nil}
        return try? directory().appendingPathComponent(String(reference.dropFirst(10)))
    }
    @MainActor static func saveImage(_ bytes:Data) throws -> JSONValue {
        guard bytes.count <= 30*1024*1024, let image = UIImage(data:bytes) else { throw CRMError.invalid("Ảnh không đọc được hoặc lớn hơn 30 MB.") }
        let scale = min(1,1600/max(image.size.width,image.size.height))
        let size = CGSize(width:max(1,image.size.width*scale),height:max(1,image.size.height*scale))
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        let prepared = UIGraphicsImageRenderer(size:size,format:format).image { c in UIColor.white.setFill();c.fill(CGRect(origin:.zero,size:size));image.draw(in:CGRect(origin:.zero,size:size)) }
        guard let jpeg = prepared.jpegData(compressionQuality:0.82) else {throw CRMError.invalid("Không xử lý được ảnh.")}
        let id = UUID().uuidString
        try jpeg.write(to:directory().appendingPathComponent(id+".jpg"),options:[.atomic,.completeFileProtectionUntilFirstUserAuthentication])
        return .object(["id":.string(id),"url":.string("crm-media/"+id+".jpg"),"order":.number(0),"createdAt":.string(Database.now)])
    }
}

struct CRMImage: View {
    let reference:String
    @State private var bytes:Data?
    var body:some View {
        Group {
            if let bytes,let image = UIImage(data:bytes) {Image(uiImage:image).resizable().scaledToFill()}
            else if let remote = URL(string:reference),["https","http"].contains(remote.scheme ?? "") {AsyncImage(url:remote) {phase in if let image = phase.image {image.resizable().scaledToFill()} else {placeholder}}}
            else {placeholder}
        }.task(id:reference) {
            bytes = await Task.detached {
                if let url = MediaFiles.url(reference) { return try? Data(contentsOf:url) }
                if reference.hasPrefix("data:image/"),let encoded = reference.components(separatedBy:",").last { return Data(base64Encoded:encoded) }
                return nil
            }.value
        }
    }
    private var placeholder:some View { ZStack {Color.gray.opacity(0.12);Image(systemName:"photo").foregroundStyle(.secondary)} }
}
