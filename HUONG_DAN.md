# LẮM AI REAL ESTATE CRM

App Next.js + React + TypeScript theo MASTER_BLUEPRINT_V1. Giao diện tiếng Việt, ưu tiên iPhone, tách domain, cấu hình, dịch vụ và module giao diện.

## Chạy trên máy

1. Cài Node.js LTS từ https://nodejs.org nếu máy chưa có.
2. Mở terminal trong thư mục này.
3. Chạy `npm install`, sau đó `npm run dev`.
4. Mở http://localhost:3000.

Trong môi trường Windows hạn chế tiến trình con, chạy `node server.mjs`. Kiểm thử: `npm test`. Build thông thường: `npm run build`. Có script `node scripts/build-serial.cjs` để build tuần tự trong môi trường bị hạn chế; script chỉ áp dụng cho phiên bản Next được khóa trong package-lock.json.

**Không cần tài khoản để dùng chế độ trên máy.** Nhấn “Xem dữ liệu minh họa” trên Tổng quan nếu muốn thử. Những dữ liệu này được ghi rõ là mẫu. Ảnh mẫu là bảng nhãn, không đại diện cho bất động sản thực tế.

Dữ liệu chế độ trên máy được lưu trong localStorage của trình duyệt. Xóa dữ liệu trình duyệt sẽ xóa dữ liệu này. Ảnh lớn có thể vượt dung lượng trình duyệt; app báo lỗi thay vì báo lưu thành công. Sao lưu JSON định kỳ trong Cài đặt.

## Tạo Firebase lần đầu

1. Vào https://console.firebase.google.com và chọn **Create a project**. Đặt tên, ví dụ `lam-ai-crm`. Analytics có thể tắt nếu chưa cần.
2. Vào **Project settings → Your apps → Web** (biểu tượng `</>`), đăng ký ứng dụng web. Sao chép các giá trị Firebase config.
3. Sao chép `.env.example` thành `.env.local`. Điền các giá trị `NEXT_PUBLIC_FIREBASE_*` tương ứng. Firebase web config là cấu hình client; Gemini key tuyệt đối không dùng tiền tố NEXT_PUBLIC.
4. Vào **Authentication → Sign-in method**, bật Google, chọn email hỗ trợ. Trong **Settings → Authorized domains**, thêm `localhost` nếu chưa có và sau này thêm tên miền app.
5. Vào **Firestore Database**, tạo database ở chế độ production. Chọn vùng phù hợp với người dùng và giữ nhất quán với nơi chạy server.
6. Vào **Storage**, tạo bucket và điền đúng `storageBucket` vào `.env.local`. Cloud Storage và App Hosting có thể yêu cầu gói Blaze / tài khoản thanh toán. Kiểm tra giá trước khi bật; không có cam kết vận hành miễn phí tuyệt đối.
7. Cài Firebase CLI bằng `npm install -g firebase-tools`. Chạy `firebase login`, rồi `firebase use --add` để chọn đúng dự án vừa tạo.
8. Chạy `firebase deploy --only firestore:rules,firestore:indexes,storage`. Chờ indexes xây dựng xong. Không dùng rules test-mode mở toàn bộ database.
9. Khởi động lại app. Vào **Cài đặt → Đăng nhập Google**.

Mỗi document nội bộ có `userId`; rules chỉ cho chính tài khoản đó đọc/ghi. Public card dùng collection riêng, dữ liệu được chọn lọc, chỉ cho phép đọc từng link, không liệt kê toàn bộ.

Dữ liệu trên máy không tự động đẩy vào tài khoản Google. Với dữ liệu thực có ảnh trên máy, tải lại ảnh vào Firebase Storage trước khi chuyển bản ghi lên cloud. App từ chối lưu ảnh base64 trong Firestore.

## Bật Gemini

1. Tạo API key tại https://aistudio.google.com/apikey.
2. Điền `GEMINI_API_KEY` trong `.env.local` (chỉ server đọc). Không gửi key vào chat, Git hay đặt vào trường client.
3. Trong Firebase Authentication → Users, sao chép UID của tài khoản bạn vừa đăng nhập. Điền vào `ALLOWED_FIREBASE_UIDS`; nhiều UID ngăn cách bằng dấu phẩy.
4. Điền tên model Gemini hiện còn được hỗ trợ trong `GEMINI_MODEL`. Giá trị ví dụ trong file env là `gemini-2.5-flash`; thay nếu tài khoản/API của bạn không hỗ trợ model này.
5. Khởi động lại app. Vào AI Copilot để dán tin, phân tích screenshot, nhập nhu cầu, tìm theo ngôn ngữ tự nhiên hoặc hỏi công việc.

Endpoint `/api/ai` xác thực Firebase ID token, kiểm tra UID được phép, giới hạn yêu cầu theo phút và có timeout. Dữ liệu nhận từ AI luôn qua màn hình xem lại; schema chặn lưu chính thức nếu thiếu thông tin. Giới hạn theo phút hiện ở bộ nhớ từng tiến trình; với nhiều server cần bộ đếm dùng chung. Không ghi payload AI vào log.

Giọng nói dùng khả năng nhận dạng của trình duyệt nếu có; trên iPhone có thể dùng micro của bàn phím. Gemini/nhận dạng giọng nói cần mạng và quyền thiết bị phù hợp.

## Đưa lên mạng và cài lên iPhone

App có endpoint server cho Gemini, vì vậy **không thể chỉ tải thư mục tĩnh lên Firebase Hosting** rồi mong AI hoạt động.

Cách phù hợp cho Next.js: dùng **Firebase App Hosting** (vẫn trong hệ sinh thái Firebase):

1. Đưa mã nguồn lên repository GitHub riêng của bạn, không đưa `.env.local` lên Git.
2. Trong Firebase → App Hosting, tạo backend kết nối repository và chọn thư mục chứa `package.json` làm root.
3. Cấu hình các biến `NEXT_PUBLIC_FIREBASE_*` ở build và runtime. File `apphosting.yaml` có mẫu runtime secrets; tạo secrets `GEMINI_API_KEY` và `ALLOWED_FIREBASE_UIDS`, cấp backend quyền đọc. Thêm `GEMINI_MODEL` nếu cần.
4. Deploy backend. App Hosting chạy build Next.js bình thường; script build tuần tự chỉ dùng cho môi trường hạn chế trên máy.
5. Thêm tên miền HTTPS đã triển khai vào Firebase Auth authorized domains.
6. Mở app bằng Safari trên iPhone → Chia sẻ → **Thêm vào Màn hình chính**.

Nếu muốn Firebase Hosting truyền thống, cần cấu hình rewrite sang Cloud Run/Functions chạy Next.js; phần đó chưa có trong cấu hình này. Đặt ngân sách/cảnh báo chi phí và kiểm tra quyền project trước khi đưa dữ liệu thật lên.

Tài liệu chính thức:
- https://firebase.google.com/docs/app-hosting/get-started
- https://firebase.google.com/docs/app-hosting/costs
- https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024
- https://ai.google.dev/api/generate-content

## Các luồng đã triển khai

- Dashboard: quỹ hàng, khách, việc quá hạn, match, nhắc xác minh.
- BĐS: thêm/sửa, 8 hướng, khu vực yêu thích, ảnh, diện tích tự tính, kiểm tra bắt buộc, lưu nháp, nghi trùng, lọc, trạng thái, giá bán thực tế, lịch sử.
- Khách: thêm/sửa/xóa có xác nhận, nhiều nhu cầu, giai đoạn, liên kết task, timeline.
- Matching hai chiều: điều kiện cứng, trọng số cấu hình, giải thích bằng tiêu chí; sở thích hiện đối sánh từ khóa.
- Công việc/lịch hẹn: thêm/sửa, loại việc, ưu tiên, ngày giờ, hoàn thành/mở lại.
- Gemini: nhập text/ảnh, nhu cầu, tìm kiếm ngôn ngữ tự nhiên, tổng quan công việc, viết tin Facebook.
- Chia sẻ: chỉnh/copy nội dung, native share sang app hỗ trợ, tải ảnh PNG, tạo và thu hồi link public khi kết nối Firebase.
- Cài đặt: thương hiệu, khu vực, trọng số. Xuất JSON, CSV mở bằng Sheets, khôi phục JSON có xác nhận và kiểm tra.
- PWA: manifest, icon, safe-area, điều hướng dưới, cache tài nguyên tĩnh và màn hình mất mạng.

## Phạm vi hiện tại cần biết

Đây là bản triển khai chạy được để dùng thử và tiếp tục cấu hình; **chưa coi toàn bộ Definition of Done của Blueprint đã được nghiệm thu production**.

- Chưa có dự án Firebase/Gemini của người dùng nên đăng nhập, rules, upload, link public và AI chưa được kiểm thử end-to-end với tài khoản thật.
- Màn hình cloud hiện tải tối đa 100 bản ghi mỗi nhóm để hạn chế đọc. Matching/tìm kiếm/dashboard dựa trên tập đã tải. Service đã có query BĐS theo trang; cần nối thêm phân trang UI và mở rộng query/index trước khi dùng kho lớn. Xuất JSON cloud chủ động đọc đầy đủ qua từng trang. CSV hiện xuất quỹ hàng đã tải.
- Không tự động backup Google Drive hay ghi Google Sheets qua OAuth; hiện tải JSON/CSV để bạn lưu/nhập vào các dịch vụ đó.
- Chống trùng có điểm và cho xem các lý do/vẫn lưu riêng; chưa có gộp trường/ảnh và chưa có image fingerprint hoặc khoảng cách tọa độ.
- Copilot hiện chỉ phân tích/chuẩn bị draft; chưa có đầy đủ tool thực thi sửa dữ liệu trong hội thoại hay semantic reranking Gemini.
- Chưa có đồng bộ offline có hàng đợi. Khi app đã mở, chế độ trên máy vẫn lưu được; mở mới khi mất mạng có màn hình offline, không hứa đủ chức năng.
- Public link là snapshot, không tự đổi theo BĐS gốc. Link vừa tạo có thể thu hồi ngay trong màn hình; chưa có danh sách quản trị mọi link đã tạo.
- Khôi phục cloud giới hạn một batch tối đa 450 thay đổi, không dành cho migration dung lượng lớn. Nên phục hồi thử ở chế độ trên máy trước.

## Cấu trúc

`src/domain`: schema, normalization, duplicate, matching, freshness.
`src/config`: enum và cấu hình dùng chung.
`src/services`: Firebase, media adapter, repository, Gemini provider.
`src/modules`: dashboard, properties, customers/requirements, tasks/calendar, matching, copilot, share-card, settings/reports.
`src/components/ui`: dialog, field, empty state, confirmation.
`src/app`: app shell, API server, trang public.

`MASTER_BLUEPRINT_V1.md` trong thư mục này giữ nguyên bản thiết kế gốc. Các giới hạn nêu trên không thay đổi enum hay hợp đồng dữ liệu gốc.

## Cập nhật form thủ công

Giá đăng và giá bán thực tế được nhập theo **tỷ đồng** (ví dụ `1,5` hoặc `1.5`). Bên dưới ô nhập hiển thị số VNĐ tương ứng; dữ liệu lưu vẫn dùng VNĐ để giữ đúng matching và báo cáo. Trường **Thông tin chi tiết** hỗ trợ nhiều dòng, lưu riêng với ghi chú và hiển thị trong màn hình chi tiết BĐS. Xem `PROPERTY_DATA_CONTRACT_V1.1.md`.

## Bộ lọc khoảng giá và GPT/Groq

- Quỹ BĐS: nhập **Giá từ** và **Giá đến** theo tỷ đồng. Chấp nhận `1,5` hoặc `1.5`, bao gồm cả hai đầu khoảng. Để trống một đầu nếu không giới hạn. Có nút nhanh 1–1,5 tỷ và bỏ khoảng giá.
- Cài đặt → **API key GPT / Groq / Gemini**: chọn nhà cung cấp, nhập tên model và key, bấm **Lưu và sử dụng**. Ô key trống giữ nguyên key đã nhập của nhà cung cấp đó. Có nút xóa key.
- Key nằm trong bộ nhớ máy chủ, gắn riêng với cookie HttpOnly của trình duyệt, tối đa 24 giờ. Không lưu trong localStorage, Firestore, JSON sao lưu hay ZIP. Khởi động lại server cần nhập lại key. Cách này dành cho bản chạy trên một máy chủ; nếu triển khai nhiều instance cần kho secret dùng chung theo tài khoản.
- Dùng key riêng không yêu cầu Firebase. Nếu không có key theo phiên, app vẫn hỗ trợ Gemini qua biến môi trường với xác thực Firebase/UID như trước.
- Chọn model hỗ trợ Chat Completions và JSON cho OpenAI/Groq; model phải hỗ trợ ảnh nếu gửi screenshot. App báo lỗi rõ khi key/model/hạn mức không hợp lệ. Nhấn Phân tích trong AI Copilot sẽ gửi nội dung bạn nhập tới nhà cung cấp đã chọn.
- Kết nối được kiểm tra bằng mock response; chưa gọi API trả phí với key thật của người dùng.

Tài liệu API tham chiếu: https://developers.openai.com/api/reference/resources/chat và https://console.groq.com/docs/api-reference.

## Groq: không cần tự biết tên model

Trong Cài đặt, chọn Groq, nhập API key, có thể để trống Tên model rồi bấm **Lưu và kiểm tra**. App gọi Models API của Groq, chọn model trò chuyện từ danh sách được trả về và gửi một yêu cầu JSON kiểm tra trước khi lưu. Nếu key/model không hoạt động, cấu hình hiện có được giữ. Nút **Lấy model từ Groq** cho phép tải danh sách để chọn model thủ công. Lệnh kiểm tra có thể tính vào hạn mức API của bạn.

AI Copilot hỗ trợ nhập tin, nhập nhu cầu, tìm kiếm bằng ngôn ngữ tự nhiên và hỏi công việc. Ví dụ ở chế độ tìm kiếm: “Tìm nhà giá từ 1 đến 1,5 tỷ, ít nhất 3 phòng ngủ”. AI phân tích yêu cầu thành điều kiện; app lọc tập BĐS đã tải. API key và model là hai thông tin riêng; không phải trả tiền/mua một model riêng chỉ để nhập tên model. Quyền sử dụng và hạn mức phụ thuộc tài khoản Groq.

Tham chiếu Models API: https://console.groq.com/docs/models. Luồng tự chọn/kiểm tra đã qua kiểm thử giả lập; cần key thật trong giao diện để xác nhận quyền của tài khoản người dùng.

## Nhu cầu ngay trong form khách hàng

Thêm/Sửa khách hàng có phần Nhu cầu tìm bất động sản: chọn nhiều loại (nhà, đất nền, kho xưởng, đất nông nghiệp), nhiều hướng, khoảng giá từ–đến theo tỷ đồng và phường/xã. Tất cả tiêu chí đều tùy chọn; để trống không tạo điều kiện giới hạn. Khách chỉ có tên vẫn lưu được. Có thể thêm nhiều nhu cầu khác nhau; các nhu cầu này dùng chung với Matching. Form nhu cầu riêng cũng dùng giá theo tỷ đồng. Dữ liệu ngân sách vẫn lưu VNĐ.

## So khớp từ tab Khách hàng

Mỗi thẻ khách có nút **So khớp BĐS** kèm số sản phẩm phù hợp. Mở khách để xem **BĐS phù hợp với khách**: ảnh, giá, điểm và lý do khớp, kèm mở chi tiết/chia sẻ sản phẩm. Có thể xem tất cả nhu cầu đang tìm hoặc chọn một nhu cầu; sản phẩm phù hợp nhiều nhu cầu chỉ hiển thị một lần, theo điểm cao nhất. Dùng cùng engine và điều kiện với chiều BĐS → khách; BĐS đã bán/tạm ngưng và nhu cầu không hoạt động bị loại. Kết quả cập nhật theo dữ liệu CRM đang được tải.

## Ngưỡng đề xuất matching

Chỉ đề xuất kết quả đạt **từ 70% trở lên** và đáp ứng điều kiện bắt buộc. Áp dụng thống nhất ở Dashboard, Matching, BĐS → khách và Khách → BĐS. Trọng số hiện có vẫn dùng để chấm điểm; ngưỡng tập trung trong `MATCH_RECOMMENDATION_THRESHOLD`.

## Nhập AI từ nội dung, link, camera và giọng nói

- Tab AI có mục **Nhập liệu nhanh**: link website/bài Facebook công khai, Camera, Chọn ảnh và Nhập bằng giọng nói.
- **Đọc nội dung** tải văn bản của trang vào ô nhập để xem/sửa, không tự gọi AI. **Phân tích** gửi nội dung này đến nhà cung cấp AI đã chọn và mở bản nháp.
- Thông tin chi tiết của bản nháp giữ nguyên văn nội dung ô nhập, bao gồm xuống dòng. Với đầu vào chỉ có ảnh, AI chép văn bản đọc được vào chi tiết, cần người dùng kiểm tra.
- Link được lưu riêng ở `sourceUrl`. Không lấy ảnh trên trang hay screenshot làm ảnh đại diện BĐS tự động.
- Chọn pháp lý: Sổ đỏ / Chưa có sổ / Chưa rõ. Ghi chú pháp lý cũ được giữ riêng. Không tự suy đoán chứng nhận khi thiếu dữ kiện.
- Reader chỉ hỗ trợ trang HTML/text công khai, tối đa 2 MB, giới hạn nội dung 30.000 ký tự và tối đa 3 lần chuyển hướng. Có kiểm tra địa chỉ mạng công khai ở mỗi lượt và ghim IP khi kết nối. Không dùng tài khoản Facebook/cookie và không vượt trang đăng nhập. Trang chặn bot hoặc tải nội dung bằng JavaScript có thể không đọc được; dùng dán tin/screenshot khi đó.
- Camera dùng bộ chọn ảnh của thiết bị (`capture=environment`). Trên máy tính có thể mở bộ chọn file thay vì camera. Ảnh được chuyển JPEG và giới hạn cạnh 2.000 pixel trước khi gửi AI; chọn model có hỗ trợ ảnh.
- Giọng nói dùng SpeechRecognition tiếng Việt của trình duyệt, có nút dừng và hiển thị lời đang nghe. Yêu cầu quyền micro và hỗ trợ của trình duyệt; nếu không hỗ trợ thì dùng micro trên bàn phím iPhone. Tính năng không hứa hoạt động offline.
- Thao tác camera/micro thực cần được kiểm tra trên thiết bị người dùng; chưa xác nhận bằng quyền camera/micro thật trong phiên phát triển.

## Chăm sóc khách từ bất động sản
- Mở chi tiết BĐS để xem khách được đề xuất từ 70%, mỗi khách xuất hiện một lần theo điểm cao nhất. Khách tạm dừng / đã giao dịch không được đề xuất.
- Chọn Hồ sơ khách để chuyển sang tab Khách hàng và mở đúng khách; Gọi khách / Zalo mở ứng dụng liên hệ, không tự gửi tin và không tự đánh dấu đã chăm sóc.
- Chọn Ghi chăm sóc / hẹn tiếp, nhập kết quả và tùy chọn ngày giờ tiếp theo. Có thể chọn một việc đang chờ để hoàn thành. Lịch sử được lưu thành việc đã hoàn thành; lịch tiếp theo thành việc FOLLOW_UP cần làm, liên kết khách và BĐS.
- Hồ sơ khách có ghi chú kết quả, lịch sử và việc đang chờ. Tab Công việc hiển thị ghi chú, liên kết khách, thời điểm hoàn thành.
- Tổng quan hiển thị khách đang tìm hoặc có việc chờ; ưu tiên việc đến hạn/quá hạn và khách chưa có lịch. Thanh nhắc trên mọi tab đưa về danh sách này khi mở app. Khách Tạm dừng / Đã giao dịch được ẩn khỏi danh sách chăm sóc.
- Dữ liệu chăm sóc dùng cùng cơ chế lưu hiện tại (trình duyệt hoặc Firebase khi đã kết nối). Không có thông báo đẩy khi đóng app; Zalo phụ thuộc số / link Zalo hợp lệ của khách.
