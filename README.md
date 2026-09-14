# LẮM AI CRM Android

Bản Android dùng React + Capacitor, SQLite trên điện thoại, Google Drive để sao lưu/khôi phục qua trình chọn tệp Android (Storage Access Framework). Không cần Firebase, không chạy Next.js server.

## Chạy và build
Node.js 22+, Java 21, Android SDK 36. Chạy npm ci, npm test, npm run android:build. Mở thư mục android bằng Android Studio hoặc chạy android/gradlew assembleDebug. GitHub Actions android.yml build APK thử nghiệm trên nhánh android.

## Chuyển dữ liệu từ web
Ở app web cũ: Cài đặt → Tải bản sao lưu JSON. Đưa file vào Drive hoặc điện thoại. Trong Android: Cài đặt → Khôi phục / nhập dữ liệu từ Drive → chọn file → xem số lượng → xác nhận. Dữ liệu hiện tại sẽ bị thay thế nên sao lưu trước. Ảnh base64 nằm trong bản sao, ảnh URL ngoài vẫn cần mạng. API key cần nhập lại.

## Sao lưu Drive
Cài và đăng nhập ứng dụng Google Drive. Trong CRM chọn Sao lưu vào Drive / điện thoại, chọn Drive trong menu trình chọn tệp hệ thống. Chờ ghi hoàn tất và kiểm tra tệp đã đồng bộ trong ứng dụng Drive. Không có đồng bộ đa thiết bị hoặc tự động nền. File JSON chứa dữ liệu khách/ảnh, nên giữ trong thư mục Drive riêng tư.

## Dữ liệu
Database SQLite riêng trong sandbox app; ghi snapshot theo transaction, chia thành các hàng nhỏ để không vượt CursorWindow. Tối đa 100 MB cho snapshot/bản sao lưu; ảnh mỗi tệp tối đa 5 MB. Giới hạn này nhằm tránh thiếu bộ nhớ khi khôi phục JSON. Không dùng Firebase và không giới hạn tải 100 bản ghi. Gỡ ứng dụng/xóa dữ liệu Android sẽ xóa dữ liệu cục bộ; sao lưu trước. Android auto backup được tắt để tránh sao lưu khóa AI; dùng nút xuất rõ ràng trong app.

## AI và thiết bị
API key mã hóa bằng Android Keystore; không xuất key, không gọi máy chủ riêng. GPT/Groq/Gemini gọi trực tiếp endpoint chính thức, cần mạng và model hỗ trợ JSON/ảnh. Link chỉ nhận HTTPS công khai, tối đa 2 MB; Facebook có thể chặn. Camera dùng plugin native, giọng nói dùng dịch vụ nhận dạng Android hoặc micro bàn phím. Chia sẻ ảnh/nội dung qua Android share sheet. Bản offline không tạo link web công khai; dùng gửi nội dung/ảnh.

## Kiểm thử và bản cài
APK assembleDebug dành cho cài thử trực tiếp, không phải bản phát hành Google Play. Giữ cùng applicationId và chữ ký khi cập nhật để giữ database. Build CI mới có thể có khóa debug khác: đừng gỡ app để cập nhật khi chưa sao lưu. Cần kiểm thử thực tế camera, voice, Drive và khôi phục trên điện thoại của người dùng trước khi chuyển dùng chính.
