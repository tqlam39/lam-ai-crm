# CÀI VÀ CHUYỂN DỮ LIỆU SANG ANDROID

1. Trên app web cũ, vào Cài đặt → Tải bản sao lưu JSON. Giữ file này trước khi chuyển.
2. Chép APK LAM-AI-CRM-Android vào điện thoại Android 7 trở lên; mở APK, cho phép cài từ ứng dụng đang mở tệp khi Android hỏi.
3. Mở LẮM AI CRM → Cài đặt → Khôi phục / nhập dữ liệu từ Drive. Chọn bản JSON đã xuất, kiểm tra số BĐS/khách/công việc, rồi xác nhận.
4. Kiểm tra ảnh, nhu cầu khách và lịch sử chăm sóc. Ảnh nhúng trong JSON dùng offline; ảnh là link web cần mạng. Đừng xóa bản web/bản sao lưu cũ trước khi kiểm tra xong.
5. Trong Cài đặt → API key, nhập lại key GPT/Groq/Gemini; chọn model phù hợp. AI cần mạng. Key không đi theo bản sao lưu.
6. Sao lưu mới: Cài đặt → Sao lưu vào Drive / điện thoại → mở menu trình chọn tệp → chọn Google Drive → Lưu. Cài/đăng nhập Google Drive trước nếu không thấy Drive. Có thể chọn Downloads rồi tải file lên Drive bằng ứng dụng Drive.

Đây là APK thử nghiệm cài trực tiếp, không phải bản Google Play. Bản APK cần kiểm tra thực tế camera, giọng nói, lưu/khôi phục Drive trên điện thoại của bạn. Muốn cập nhật APK mà giữ database cần cùng mã ứng dụng và chữ ký. Không gỡ bản đang có trước khi sao lưu dữ liệu.

Không có đồng bộ giữa nhiều điện thoại; Drive giữ các bản sao có ngày giờ. Mở lại app sẽ đọc database SQLite trên máy. Gỡ app hoặc xóa dữ liệu sẽ xóa database/khóa AI cục bộ.
