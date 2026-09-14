# Khác biệt và quyết định migration

1. Matching: tài liệu minh họa giá vượt5% nhưng nguồn là hard constraint. Giữ nguồn; không đổi điểm cho phép vượt giá. Legal matching nguồn dựa legal.note; certificateStatus không tự suy từ sổ riêng/sổ hồng. Mọi thay đổi nghiệp vụ sau này phải có test/ghi rõ.
2. Enum trạng thái BĐS nguồn chỉ ACTIVE/SOLD/PAUSED. Hết hàng là yêu cầu thêm, không được remap PAUSED hoặc xóa bản cũ. Dự kiến thêm giá trị OUT_OF_STOCK vào iOS và ghi đây là mở rộng; xuất V1 về bản cũ phải cảnh báo không tương thích, không tự đổi giá trị.
3. Nguồn chưa có các field bathroom/floors/khóm/đường/loại đất/thổ cư/hoàn công/sổ riêng/broker/holder/buyer/commission. Thêm optional với tên có tài liệu; không gán dữ liệu phỏng đoán cho records cũ. UI form chia section; nguồn bắt buộc ngang/dài/hướng/chủ/ảnh vẫn giữ.
4. Customer status nguồn là chuỗi tự do, UI Đang tìm/Đã tư vấn/Đang xem/Đàm phán/Đã giao dịch/Tạm dừng; master dùng một số nhãn khác. Giữ raw value cũ; nhóm hiển thị có alias, không rewrite dữ liệu chỉ vì đổi label.
5. Freshness nguồn7 ngày, tài liệu ví dụ30 ngày. Giữ7 mặc định, cho cấu hình. Không sửa lastVerifiedAt khi chỉ mở màn hình.
6. Source web có Firebase cloud/publicShare; Android đã bỏ công khai URL và dùng share text/card. iOS ưu tiên offline như Android. Public URL cần dịch vụ host được cấu hình, không giả lập link hoạt động. Firebase đã từng được cấu hình từng phần nhưng chưa xác minh deployment; đánh dấu integration tùy chọn chưa nghiệm thu, không tuyên bố xóa bỏ khỏi phạm vi.
7. Drive hiện dùng Files provider, không phải Firebase/Google OAuth trong CRM. UI hướng dẫn bật Drive ở Files; chỉ user export/restore. Không tự bật cloud sync.
8. Ảnh V1 có thể data URL, HTTPS hoặc đường dẫn sample. Import lưu ảnh nhúng vào file riêng mà vẫn giữ id/order/createdAt; backup có ảnh nhúng lại theo format cũ. URL ngoài chưa tải không hứa offline. Không xóa ảnh gốc trước khi DB transaction thành công.
9. Không có Xcode/macOS/Swift trong máy Windows. CI macOS phải build và chạy Simulator thực trước khi đánh dấu phase iOS đạt. Build physical iPhone cần Apple signing, không thể cung cấp IPA ký hợp lệ từ APK hay bundle Simulator.
10. Không đưa mật khẩu/API key/cấu hình phiên GitHub vào source hay artifact. API provider config nằm ngoài Database; key Keychain ThisDeviceOnly; backup chỉ dữ liệu CRM cho user xuất.

Các mục chưa triển khai được theo phase phải được giữ trạng thái chưa xong, không dùng TODO rỗng hay fake success để lấp chức năng.
