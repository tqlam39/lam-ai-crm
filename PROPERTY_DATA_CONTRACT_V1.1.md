# PROPERTY DATA CONTRACT V1.1

Thay đổi theo yêu cầu người dùng: giá trong form dùng tỷ đồng; bổ sung trường thông tin chi tiết.

- `Property.details?: string`: mô tả chi tiết tùy chọn, tách biệt `note` (ghi chú). Áp dụng cho cả bản nháp và bản ghi chính thức.
- Dữ liệu V1 cũ không cần migration; khi không có `details`, form hiển thị trống.
- `price.amount` và `soldInfo.actualSoldPrice` vẫn là số nguyên VNĐ. Chỉ đổi đơn vị nhập/hiển thị trong form sang tỷ đồng. Chấp nhận dấu phẩy hoặc dấu chấm thập phân.
- Enum và các trường bắt buộc V1 giữ nguyên. Backup JSON V1 vẫn tương thích; bản sao lưu mới có thêm trường tùy chọn `details`.
