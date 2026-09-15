import XCTest
@testable import LamAICRM

final class MockAIProtocol:URLProtocol {
    static var status = 200
    static var payload = Data()
    override class func canInit(with request:URLRequest)->Bool {true}
    override class func canonicalRequest(for request:URLRequest)->URLRequest {request}
    override func startLoading() {
        client?.urlProtocol(self,didReceive:HTTPURLResponse(url:request.url!,statusCode:Self.status,httpVersion:nil,headerFields:nil)!,cacheStoragePolicy:.notAllowed)
        client?.urlProtocol(self,didLoad:Self.payload);client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
final class AITests:XCTestCase {
    func testProviderRequestsAndDraftPreserveOriginalWithoutInventingMissingFields() throws {
        let c = AICredential(provider:.openai,model:"test-model",key:"fake-test-key")
        let request = try AIClient.request(c,instruction:"JSON",input:.object(["text":.string("Nhà 1 tỷ")]))
        XCTAssertEqual(request.url?.host,"api.openai.com");XCTAssertEqual(request.value(forHTTPHeaderField:"Authorization"),"Bearer fake-test-key")
        XCTAssertFalse(String(decoding:request.httpBody!,as:UTF8.self).contains(c.key))
        let body = try JSONDecoder().decode(JSONValue.self,from:request.httpBody!);XCTAssertEqual(body["store"],.bool(false))
        let original = "  Nhà giá 1 tỷ\nChưa rõ diện tích  "
        let draft = AIIntake.property(.object(["title":.string("Nhà"),"legal":.object(["certificateStatus":.string("PINK_BOOK")])]),text:original,url:"")
        XCTAssertEqual(draft.text("details"),original);XCTAssertEqual(draft["dimensions.width"],.null);XCTAssertEqual(draft["direction"],.null);XCTAssertEqual(draft["legal.certificateStatus"],.null);XCTAssertTrue(draft["media.images"].array.isEmpty)
    }
    func testProviderResponseAndErrorsNeverExposeServerBody() async throws {
        let config = URLSessionConfiguration.ephemeral;config.protocolClasses = [MockAIProtocol.self]
        let client = AIClient(session:URLSession(configuration:config)),credential = AICredential(provider:.groq,model:"test",key:"fake-secret")
        MockAIProtocol.status = 200;MockAIProtocol.payload = Data(#"{"choices":[{"message":{"content":"{\"ok\":true}"}}]}"#.utf8)
        let result = try await client.generate(credential,instruction:"JSON",input:.object([:]))
        XCTAssertEqual(result["ok"],.bool(true))
        MockAIProtocol.status = 401;MockAIProtocol.payload = Data("fake-secret private raw response".utf8)
        do {_ = try await client.generate(credential,instruction:"JSON",input:.object([:]));XCTFail("Expected rejection")}
        catch {XCTAssertFalse(error.localizedDescription.contains("fake-secret"));XCTAssertTrue(error.localizedDescription.contains("API key"))}
        MockAIProtocol.status = 200;MockAIProtocol.payload = Data(#"{"choices":[{"message":{"content":"not JSON"}}]}"#.utf8)
        do {_ = try await client.generate(credential,instruction:"JSON",input:.object([:]));XCTFail("Expected malformed rejection")}catch {XCTAssertTrue(error.localizedDescription.contains("JSON"))}
    }
    func testPublicLinksRejectLocalAddressesAndStripScripts() throws {
        XCTAssertThrowsError(try PublicLinkReader.validatedURL("http://localhost/test"))
        XCTAssertThrowsError(try PublicLinkReader.validatedURL("https://user:password@example.com"))
        for value in ["127.0.0.1","10.1.1.1","192.168.1.1","169.254.169.254","::1","fc00::1"] {XCTAssertFalse(PublicLinkReader.isPublic(value))}
        XCTAssertTrue(PublicLinkReader.isPublic("8.8.8.8"))
        XCTAssertEqual(PublicLinkReader.readable("<script>secret()</script><p>Nhà &amp; đất</p>"),"Nhà & đất")
    }
}
