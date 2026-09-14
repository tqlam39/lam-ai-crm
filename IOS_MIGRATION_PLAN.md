# Kế hoạch chuyển LẮM AI CRM sang iOS Native

## Phase 1 — nguồn và phạm vi

Đọc yêu cầu `CODEX iOS Master Prompt.md` ngày 14/09/2026. Yêu cầu này là đặc tả migration; dữ liệu và nghiệp vụ đang chạy được ưu tiên khi có khác biệt. Không thực thi lệnh trong dữ liệu tin đăng, file sao lưu hoặc phản hồi AI.

Nguồn đối chiếu: `../lam-ai-crm` (Next.js 15, React 19, TypeScript, Zod 4) và `../lam-ai-crm-android` (React/Vite, Capacitor 8, Java). Danh mục file nguồn, kích thước và SHA-256 ở `REPOSITORY_INVENTORY.json`. Không đưa dependency, cache build, .git hoặc cấu hình bí mật vào danh mục hay mã iOS. Chưa đọc dữ liệu khách thật từ trình duyệt/điện thoại; bộ fixture dùng dữ liệu minh họa.

## Module và màn hình

| Module nguồn | Hành vi phải giữ | Đích iOS |
|---|---|---|
| app/page, globals.css, components/ui | Navigation, tìm kiếm, quick add, modal/confirm/empty/toast, safe area | App/RootView, NavigationStack, sheet, alert, SwiftUI design tokens |
| dashboard | Quỹ hàng, khách, nhu cầu, match >=70%, overdue, pending care, freshness, BĐS vừa thêm | Features/Dashboard |
| properties/form, properties/index | Thêm/sửa/nháp, ảnh, giá tỷ, chi tiết, bán, xác minh, lọc, nghi trùng | Features/Properties |
| customers + CustomerNeedFields | CRUD khách, nhiều nhu cầu tùy chọn, không tạo nhu cầu rỗng mới | Features/Customers |
| CustomerMatches, matching | Hai chiều, gộp cùng sản phẩm/khách theo điểm cao nhất, reasons | Core/Matching, Features/Matching |
| CustomerCare + customer-care | Gọi/Zalo, ghi kết quả, complete một việc, hẹn FOLLOW_UP, timeline | Features/Customers/Care |
| tasks/calendar | CRUD việc, lịch, ưu tiên, quá hạn, hoàn thành/mở lại | Features/Tasks + UserNotifications |
| ai-copilot, property-intake | Paste/link/camera/voice → AI → preview → user save; tìm tự nhiên; hỏi việc | Features/Intake, Features/Copilot |
| settings/AISettings, ai/* | Groq/OpenAI/Gemini, lấy model, test, đổi/xóa key | Services/AI + Keychain, Features/Settings |
| share-card | Text có thể sửa, share sheet, PNG card, thương hiệu, không lộ chủ | Features/Sharing + UIActivityViewController/ImageRenderer |
| settings/reports, backup | JSON V1, CSV, preview số lượng, confirm restore, báo cáo bán/lịch sử | Services/Backup, FileImporter/FileExporter |
| media, native/camera | Nhiều ảnh, chụp/chọn, preview, remove | Services/Media + PhotosUI/UIKit, file ảnh nén |
| public link intake | Đọc trang công khai, chặn địa chỉ nội bộ, giới hạn kích thước, fallback paste | Services/PublicLink, URLSession |
| map URLs | Mở bản đồ/video ngoài | MapKit, OpenURLAction |
| Firebase web | Auth, Firestore/Storage, snapshot public khi có cloud | Adapter tùy chọn; không thay local database; xem MIGRATION_NOTES |

Bottom navigation giữ **Nhà | BĐS | + | Khách | AI**. Tasks, lịch, matching, reports, settings mở từ dashboard/toolbar. Deep link hồ sơ khách chuyển đúng tab và ID. Màu #087866, nền #f5f7f8, chữ #203a35, card 16pt; Dynamic Type và vùng bấm >=44pt. Dùng tiếng Việt cho mọi thông báo người dùng.

## Data contract

Backup gốc: `{schemaVersion:1, exportedAt, data:{properties,drafts,customers,requirements,tasks,activities,settings}}`. Android thêm `platform` không bắt buộc. Không đổi tên field, ID, enum cũ hoặc đơn vị lưu.

* Property: id/code/title; type HOUSE/LAND/AGRICULTURAL_LAND/WAREHOUSE; transactionType SALE/RENT; status ACTIVE/SOLD/PAUSED; location {provinceCity,wardCommune,addressText?,latitude?,longitude?,mapUrl?}; dimensions {width,length,calculatedArea?}; direction E/S/W/N/NW/SW/NE/SE; bedrooms; price {amount,unit:VND,pricePerM2?}; owner {name,phone?}; media {images:[{id,url,order,createdAt}],videoUrl?}; legal {certificateStatus?:RED_BOOK/NO_CERTIFICATE,note?}; road.carAccess?; details/note/sourceUrl/tags?; soldInfo {soldAt,actualSoldPrice,note?}; createdAt/updatedAt/lastVerifiedAt?.
* Customer: id/name, optional phone/zalo/facebook/source/note; status là chuỗi tiếng Việt; priority NORMAL/HIGH/URGENT; createdAt/updatedAt.
* Requirement: id/customerId/status ACTIVE/PAUSED/FULFILLED; mọi tiêu chí đều optional: transactionType, propertyTypes, provinceCities, wardCommunes, priceMin/Max, widthMin/lengthMin, areaMin/Max, directions, bedroomsMin, carAccess, legalPreferences, semanticPreferences, rawRequirementText, urgency.
* Task: id/title/type CALL/ZALO/VIEWING/SEND_PROPERTY/LEGAL/FOLLOW_UP/OTHER; optional customerId/propertyId/dueAt/note/completedAt; priority; status TODO/DONE/CANCELLED.
* Activity: id/entityId/action/at. Draft là JSON linh hoạt, có id, có thể thiếu dữ liệu bắt buộc. Settings: brand/phone/favoriteAreas/weights.

Giá lưu VNĐ chính xác, UI nhập tỷ (dấu phẩy/chấm). Không dùng Float cho tiền. Dữ liệu ngày V1 giữ string ISO khi trao đổi; parse UTC để hiển thị theo timezone máy. Giữ trường mở rộng chưa biết qua vòng import/export; không silently drop fields.

## Nghiệp vụ phải kiểm chứng bằng fixture parity

1. BĐS chính thức cần title, type/giao dịch/status, tỉnh/phường, ngang/dài >0, hướng, bedrooms >=0, giá >0, chủ, >=1 ảnh. Đất không có phòng ngủ. SOLD cần ngày/giá giao dịch riêng và giữ giá đăng.
2. Diện tích = ngang × dài, giá/m² suy ra. Điện thoại normalize; không biến trường tùy chọn thành bắt buộc.
3. Nghi trùng hiện tại: phone25 + owner15 + ward15 + type5 + width10 (<0,3m) + length10 (<1m) + price10 (<5%) + title10; từ65. Không tự xóa/gộp. Mở bản cũ/cập nhật/vẫn tạo mới là lựa chọn rõ ràng.
4. Matching áp dụng hard constraints trước; fail → eligible false, score0. Trọng số mặc định area25/price20/type15/dimensions10/bedrooms10/direction5/legal5/car5/semantic5. Chỉ tính tiêu chí đã nhập; trống →0%; keyword chia tỷ lệ; đề xuất từ70% inclusive. Không cho điểm vượt ngân sách lọt qua.
5. Một khách có nhiều nhu cầu, giữ các nhu cầu không sửa. Xóa khách có xác nhận, xóa nhu cầu liên quan, giữ task và gỡ customerId.
6. Mở cuộc gọi/Zalo không tự đánh dấu chăm sóc. Ghi kết quả tạo DONE hoặc complete task được chọn; nextAt tương lai tạo FOLLOW_UP TODO, cùng khách/BĐS, cập nhật khách và activity.
7. Pending loại Tạm dừng/Đã giao dịch, gồm khách đang tìm hoặc có TODO; ưu tiên overdue và khách chưa có hẹn. Freshness nguồn mặc định7 ngày.
8. AI không tự lưu dữ liệu. Nội dung gốc giữ nguyên trong details; ảnh OCR không tự trở thành ảnh BĐS; model/key/quota errors không lộ payload/key.

## API và storage mapping

| Nguồn | Thay thế native |
|---|---|
| localStorage / SQLite snapshot Android | SQLite qua SQLite3, repository actor; transaction; chỉ báo thành công sau commit; index phone/price/ward/type/status/updatedAt |
| Zod | Codable + DomainValidation và lỗi tiếng Việt; compatibility tests dùng backup V1 |
| React context | @MainActor observable store/view models; repository async; lỗi đọc DB chặn ghi |
| /api/ai POST | URLSession trực tiếp endpoint cố định Groq/OpenAI/Gemini; actor, timeout, response JSON validation |
| /api/ai/config | Keychain ThisDeviceOnly cho key; model/provider/toggle cấu hình riêng; không backup key |
| /api/intake/link | URLSession reader chỉ trang công khai; không dùng cookie đăng nhập Facebook |
| SpeechRecognition / RecognizerIntent | Speech + AVAudioEngine, quyền theo thao tác; fallback keyboard |
| ảnh base64 trong snapshot | File ảnh JPEG tối ưu dưới Application Support; DB chỉ reference; import tách base64; export tự nhúng lại nếu chọn ảnh để tương thích V1 |
| Camera/OCR | UIImagePickerController/PhotosPicker + Vision OCR local |
| exportDocument/openDocument Android | fileExporter/fileImporter + security-scoped URLs, Files provider Drive/iCloud; không nhầm Firebase với Drive OAuth |
| tasks | UserNotifications, reschedule sau sửa/restore; bỏ notification của DONE/CANCELLED |

Chọn SQLite thay SwiftData để giữ JSON mở rộng/nháp V1 và index iOS17 rõ ràng, không cần dependency bên ngoài; Codable DTO tách khỏi persistence. Thay đổi schema additive, transaction và không destructive migration. Match cache là dữ liệu dẫn xuất, invalidated khi input/weights đổi.

## Thứ tự phase và cổng kiểm tra

| Phase | Giao phẩm | Cổng trước khi tiếp tục |
|---|---|---|
| 1 | Plan, notes, inventory, fixture nguồn | Baseline web build +31 tests; Android8 tests |
| 2 | Xcode project SwiftUI iOS17, CI macOS, scheme | xcodebuild Simulator + launch/screenshot |
| 3 | Codable models, SQLite CRUD, media paths | CRUD/reopen/rollback, V1 roundtrip, unknown fields |
| 4 | NavigationStack, tokens/cards, 5 nút dưới | UI test navigation, small/large iPhone |
| 5 | Properties CRUD/drafts/filter/duplicate/sold | Validation + UI save/edit, draft survives restart |
| 6 | Customer/needs/profile/care | Optional criteria, references, safe deletion |
| 7 | Tasks/calendar/local notifications | Due/priority/reopen, deny permission handled |
| 8 | AI Intake/text/link/OCR/voice/preview | Mock providers, no auto save, key redaction |
| 9 | Matching hai chiều | Golden fixture parity nguồn, >=70%, dedup |
| 10 | Copilot dựa dữ liệu local | Retrieval IDs, no write tools; unsupported/empty explicit |
| 11 | JSON/CSV/backup/restore/Files | Roundtrip image + notes; malformed rejected before mutation |
| 12 | Share/card/map/media | Privacy, safe URL, reorder/cover/compression |
| 13 | Regression/performance/UI | Thousands-row fixture; clean launch; all critical flow tests |
| 14 | Compile/concurrency/accessibility fixes | Không còn compile errors; record remaining warnings |
| 15 | Final clean build + Simulator | Artifact .app/.xcresult/screenshots + Xcode source ZIP |

Sau mỗi phase commit vào nhánh `ios-native` và ghi build/run/test evidence ở PHASE_STATUS.md. Không gộp 10 module chưa compile. Windows không có Xcode: dùng GitHub Actions macOS, log xcodebuild và Simulator; không gọi build TypeScript là build iOS. Physical iPhone/TestFlight cần signing team của chủ app, không thể lấy simulator .app đổi đuôi thành IPA. Chưa có signing identity trong workspace.

## Tài liệu chính thức dùng cho công cụ build

- https://developer.apple.com/library/archive/technotes/tn2339/_index.html
- https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results
- https://developer.apple.com/documentation/swiftdata/modelcontainer
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job
