import Foundation
import Darwin

enum PublicLinkReader {
    static func validatedURL(_ text:String)throws->URL {
        guard let url = URL(string:text.trimmingCharacters(in:.whitespacesAndNewlines)),url.scheme == "https",let host = url.host,host.contains("."),url.user == nil,url.password == nil,url.port == nil || url.port == 443,!host.hasSuffix(".local"),!host.hasSuffix(".localhost"),host != "localhost" else {throw CRMError.invalid("Chỉ hỗ trợ link HTTPS công khai.")}
        return url
    }
    static func isPublic(_ address:String)->Bool {
        let parts = address.split(separator:".").compactMap{Int($0)}
        if parts.count == 4 {
            let a = parts[0],b = parts[1]
            return !(a == 0 || a == 10 || a == 127 || a >= 224 || (a == 100 && (64...127).contains(b)) || (a == 169 && b == 254) || (a == 172 && (16...31).contains(b)) || (a == 192 && [0,2,168].contains(b)) || (a == 198 && [18,19,51].contains(b)) || (a == 203 && b == 0))
        }
        return address.range(of:#"^[23][0-9a-f]{3}:"#,options:[.regularExpression,.caseInsensitive]) != nil && !address.lowercased().hasPrefix("2001:db8:") && !address.lowercased().hasPrefix("2001:0:") && !address.lowercased().hasPrefix("2002:")
    }
    private static func validateDNS(_ host:String)async throws {
        try await Task.detached {
            var result:UnsafeMutablePointer<addrinfo>?
            guard getaddrinfo(host,"443",nil,&result) == 0,let first = result else {throw CRMError.invalid("Không tìm thấy website.")}
            defer{freeaddrinfo(first)}
            var item:UnsafeMutablePointer<addrinfo>? = first
            while let current = item {
                var name = [CChar](repeating:0,count:Int(NI_MAXHOST))
                guard getnameinfo(current.pointee.ai_addr,current.pointee.ai_addrlen,&name,socklen_t(name.count),nil,0,NI_NUMERICHOST) == 0,isPublic(String(cString:name)) else {throw CRMError.invalid("Không đọc địa chỉ mạng nội bộ.")}
                item = current.pointee.ai_next
            }
        }.value
    }
    static func readable(_ html:String)->String {
        var text = html.replacingOccurrences(of:#"(?is)<!--.*?-->|<(script|style|noscript|nav|footer|header|form)\b[^>]*>.*?</\1>"#,with:" ",options:.regularExpression)
        text = text.replacingOccurrences(of:#"(?i)<(?:br|/p|/div|/li|/h[1-6])\b[^>]*>"#,with:"\n",options:.regularExpression).replacingOccurrences(of:#"<[^>]*>"#,with:" ",options:.regularExpression)
        for (entity,value) in [("&amp;","&"),("&nbsp;"," "),("&quot;","\""),("&#39;","'"),("&lt;","<"),("&gt;",">")] {text = text.replacingOccurrences(of:entity,with:value)}
        return String(text.replacingOccurrences(of:#"[ \t]+"#,with:" ",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines).prefix(30000))
    }
    static func read(_ value:String)async throws->String {
        var url = try validatedURL(value)
        let config = URLSessionConfiguration.ephemeral;config.timeoutIntervalForRequest = 15;config.timeoutIntervalForResource = 20;config.httpShouldSetCookies = false
        let session = URLSession(configuration:config,delegate:NoAIRedirect(),delegateQueue:nil);defer{session.invalidateAndCancel()}
        for _ in 0..<4 {
            try await validateDNS(url.host!)
            var request = URLRequest(url:url);request.setValue("text/html,text/plain",forHTTPHeaderField:"Accept")
            let (bytes,response) = try await session.bytes(for:request)
            guard let response = response as? HTTPURLResponse else {throw CRMError.invalid("Không đọc được website.")}
            if (300...399).contains(response.statusCode),let location = response.value(forHTTPHeaderField:"Location"),let next = URL(string:location,relativeTo:url)?.absoluteURL {url = try validatedURL(next.absoluteString);continue}
            guard response.statusCode == 200,let mime = response.mimeType,["text/html","text/plain"].contains(mime) else {throw CRMError.invalid("Trang yêu cầu đăng nhập hoặc không cho đọc. Dán nội dung bài hoặc dùng ảnh chụp.")}
            var data = Data()
            for try await byte in bytes {data.append(byte);if data.count > 2_000_000 {throw CRMError.invalid("Trang quá lớn. Hãy dán nội dung cần nhập.")}}
            let raw = String(decoding:data,as:UTF8.self),text = mime == "text/html" ? readable(raw) : String(raw.prefix(30000))
            let facebook = url.host == "facebook.com" || url.host?.hasSuffix(".facebook.com") == true || url.host == "fb.com"
            guard text.count >= 60,!(facebook && (url.path.contains("/login") || url.path.contains("/checkpoint") || text.prefix(1000).range(of:"log into facebook|log in or sign up|đăng nhập hoặc đăng ký",options:[.regularExpression,.caseInsensitive]) != nil)) else {throw CRMError.invalid("Không lấy được bài công khai. Dán nội dung hoặc chọn ảnh chụp bài viết.")}
            return text
        }
        throw CRMError.invalid("Link chuyển hướng quá nhiều. Dùng link trực tiếp đến bài viết.")
    }
}
