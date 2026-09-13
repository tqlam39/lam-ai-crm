# PROPERTY DATA CONTRACT V1.2

Bổ sung `legal.certificateStatus?: 'RED_BOOK' | 'NO_CERTIFICATE'` theo yêu cầu người dùng.

- RED_BOOK → Sổ đỏ.
- NO_CERTIFICATE → Chưa có sổ.
- Không có giá trị → Chưa rõ / chưa cung cấp; không suy đoán từ dữ liệu cũ.
- `legal.note` giữ nguyên để ghi chú thêm. Bản ghi V1/V1.1 vẫn hợp lệ, không cần migration.
- `details` của bản nháp AI giữ nguyên văn nội dung đã nhập để trích xuất. Với đầu vào chỉ có ảnh, dùng phần văn bản AI đọc được, có người dùng xem lại.
- Link nguồn được lưu vào `sourceUrl`. Không thay đổi enum hoặc trường bắt buộc khác.
