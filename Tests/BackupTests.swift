import XCTest
import UIKit
@testable import LamAICRM

final class BackupTests:XCTestCase {
    @MainActor func testBackupEmbedsAndRestoresLocalImageWithoutLosingRecordFields() async throws {
        let image = UIGraphicsImageRenderer(size:CGSize(width:10,height:10)).image {ctx in UIColor.red.setFill();ctx.fill(CGRect(x:0,y:0,width:10,height:10))}
        let media = try MediaFiles.saveImage(image.pngData()!)
        defer {if let url = MediaFiles.url(media["url"].text) {try? FileManager.default.removeItem(at:url)}}
        var draft = PropertyLogic.newDraft();draft["title"] = .string("Nháp có ảnh");draft["extra.original"] = .string("Giữ nguyên");draft["media.images"] = .array([media])
        var d = Database();d.drafts = [draft]
        let exported = try await BackupService.export(d,includeImages:true)
        let decoded = try BackupService.parse(exported)
        XCTAssertTrue(decoded.drafts[0]["media.images"].array[0]["url"].text.hasPrefix("data:image/jpeg;base64,"))
        let restored = try await BackupService.prepareImport(decoded)
        let reference = restored.drafts[0]["media.images"].array[0]["url"].text
        defer {if let url = MediaFiles.url(reference) {try? FileManager.default.removeItem(at:url)}}
        XCTAssertNotEqual(reference,media["url"].text);XCTAssertEqual(restored.drafts[0].id,draft.id);XCTAssertEqual(restored.drafts[0].text("extra.original"),"Giữ nguyên")
        XCTAssertEqual(restored.drafts[0]["media.images"].array[0]["id"],media["id"])
        XCTAssertNotNil(MediaFiles.url(reference).flatMap{try? Data(contentsOf:$0)})
    }
    func testMalformedBackupAndCSVFormulaProtection() throws {
        XCTAssertThrowsError(try BackupService.parse(Data("{\"schemaVersion\":99}".utf8)))
        var d = Database();d.properties = [CRMRecord(["id":.string("x"),"title":.string("=HYPERLINK(\"x\")"),"owner":.object(["phone":.string("private-phone")]),"note":.string("private-note")])]
        let csv = String(decoding:BackupService.csv(d),as:UTF8.self)
        XCTAssertTrue(csv.contains("'=HYPERLINK"));XCTAssertFalse(csv.contains("private-phone"));XCTAssertFalse(csv.contains("private-note"))
    }
}
