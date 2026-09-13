# LẮM AI CRM

Ứng dụng quản lý bất động sản, khách hàng và chăm sóc khách.

Firebase project: `lam-ai-crm`.
Repository dự kiến: https://github.com/tqlam39/lam-ai-crm

Đọc HUONG_DAN.md để chạy và cấu hình. App cần Next.js server, Firebase Authentication, Firestore và Storage; không triển khai dạng HTML tĩnh.

Trước lần triển khai đầu tiên:
- Cấu hình năm biến NEXT_PUBLIC_FIREBASE_* từ Web App trong Firebase Project settings.
- Bật Google Authentication, Firestore và Storage; triển khai rules/indexes đi kèm.
- apphosting.yaml đang tham chiếu GEMINI_API_KEY và ALLOWED_FIREBASE_UIDS: chỉ giữ các mục này khi đã tạo secrets và cấp backend quyền đọc. Nếu chỉ nhập key riêng trong app, bỏ các tham chiếu secret này trước khi deploy.
- Khóa GPT/Groq nhập trong app hiện chỉ ở bộ nhớ server, hết hạn 24 giờ hoặc mất khi server khởi động lại; không đồng bộ khóa giữa thiết bị.
- Dữ liệu localhost không tự xuất hiện trên tên miền mới. Sao lưu trước và xử lý ảnh cục bộ trước khi chuyển lên Storage.
- Chưa hoàn tất triển khai hoặc kiểm thử với Firebase thật. Không chứa mật khẩu, khóa AI hay dữ liệu khách trong bản mã nguồn này.
