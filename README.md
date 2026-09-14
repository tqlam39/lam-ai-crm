# LẮM AI CRM — iOS Native

Migration từ web/Android sang SwiftUI, iPhone iOS17+. Tiến độ thực tế ở `PHASE_STATUS.md`; không coi project skeleton là CRM hoàn chỉnh.

## Mở trên Mac

1. Cài Xcode, mở lần đầu để cài thành phần iOS Simulator.
2. Nếu đã có `LamAICRM.xcodeproj` trong gói nguồn, mở trực tiếp project đó.
3. Nếu chỉ có `project.yml`, cài XcodeGen (`brew install xcodegen`), chạy `xcodegen generate` trong thư mục này rồi mở project được tạo.
4. Chọn scheme `LamAICRM`, chọn iPhone Simulator, Product → Test.

CI tạo project, chạy `xcodebuild test`, cài và mở `.app` trên Simulator, lưu ảnh chụp và `.xcresult`. Workflow: `.github/workflows/ios.yml`, nhánh `ios-native` trong repo `tqlam39/lam-ai-crm`.

## Cài iPhone thật

Simulator `.app` không cài được lên iPhone thật. Cần chọn Apple Development Team trong Signing & Capabilities của Xcode, kết nối thiết bị và dùng provisioning phù hợp. Không có signing certificate hoặc tài khoản Apple Developer được thêm vào repository. Chưa có bản TestFlight/IPA ký để phân phối.

## An toàn dữ liệu khi chuyển

Giữ bản JSON sao lưu web/Android trước khi chuyển. Không tự xóa bản nguồn, không tự ghi đè database thật trong quá trình phát triển. Key AI không nằm trong JSON; sẽ nhập vào Keychain của app iOS. Chức năng Files/Drive không yêu cầu Firebase.

Danh mục nguồn kiểm tra: `REPOSITORY_INVENTORY.json`. Kế hoạch chức năng và nguyên tắc tương thích: `IOS_MIGRATION_PLAN.md`; xung đột đặc tả: `MIGRATION_NOTES.md`.
