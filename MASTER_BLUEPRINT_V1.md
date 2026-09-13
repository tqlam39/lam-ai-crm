# MASTER BLUEPRINT V1 — LẮM AI REAL ESTATE CRM

> Phiên bản: 1.0  
> Mục tiêu: CRM Web App/PWA quản lý bất động sản cá nhân, tối ưu iPhone 16 Pro Max, AI-first, Google-first, chi phí vận hành thấp, kiến trúc module dễ chỉnh sửa.

---

## 1. Tầm nhìn sản phẩm

**LẮM AI REAL ESTATE CRM** là hệ thống duy nhất để:

- Quản lý kho bất động sản.
- Quản lý khách hàng và nhiều nhu cầu trên từng khách.
- Quản lý công việc, lịch hẹn và việc cần gấp.
- AI nhập dữ liệu từ tin Zalo/Facebook, văn bản, ảnh và giọng nói.
- AI Matching hai chiều: Khách → BĐS và BĐS → Khách.
- AI Sales Copilot tìm kiếm, phân tích, gợi ý hành động và tạo nội dung marketing.
- Chống trùng BĐS.
- Quản lý BĐS đã bán và lịch sử giao dịch.
- Chia sẻ thẻ BĐS nhanh qua Zalo.
- Dùng tốt trên iPhone, desktop, iPad và Android bằng PWA.

### Nguyên tắc bất biến

1. **iPhone-first**, đặc biệt tối ưu iPhone 16 Pro Max.
2. **Google-first**: Firebase, Gemini, Google Drive/Sheets/Maps khi phù hợp.
3. **Chi phí thấp/gần 0** ở quy mô sử dụng cá nhân.
4. **UI tách module**, có thể thay từng màn hình/card mà không ảnh hưởng database và AI.
5. **Data / Logic / AI / UI / Config tách biệt**.
6. AI không được tự bịa dữ liệu bắt buộc.
7. Dữ liệu quan trọng phải có xác nhận trước khi AI sửa/xóa.
8. Mobile không dùng giao diện kiểu bảng Excel thu nhỏ.

---

## 2. Kiến trúc tổng thể

```text
                iPhone / Desktop / iPad / Android
                              │
                         Web App / PWA
                              │
                     Next.js + React
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
       FIREBASE             GEMINI             GOOGLE
          │                   │                   │
     Firestore           Gemini API            Drive
     Firebase Auth       Vision/Parsing         Sheets
     Hosting             Reasoning              Maps
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │
                       AI CRM ENGINE
                              │
       ┌──────────┬───────────┼───────────┬──────────┐
       │          │           │           │          │
      BĐS       KHÁCH       NHU CẦU      TASK     ACTIVITY
       │          │           │           │          │
       └──────────┴───────────┼───────────┴──────────┘
                              │
                        AI MATCHING
                              │
                        SALES COPILOT
```

### Công nghệ đề xuất

- Frontend: Next.js + React + TypeScript.
- UI: Tailwind CSS + component primitives có thể thay thế độc lập.
- PWA: manifest + service worker + Add to Home Screen.
- Database chính: Cloud Firestore.
- Authentication: Firebase Authentication / Google Sign-In.
- AI chính: Gemini.
- Backup/export: Google Drive + JSON; Google Sheets cho báo cáo/export.
- Map: Google Maps hoặc lớp adapter để có thể đổi provider.
- Validation: Zod hoặc tương đương.
- State/query: tách khỏi component UI.

---

## 3. Kiến trúc module — BẮT BUỘC

```text
src/
├── app/
├── modules/
│   ├── dashboard/
│   ├── properties/
│   ├── customers/
│   ├── requirements/
│   ├── matching/
│   ├── tasks/
│   ├── calendar/
│   ├── ai-copilot/
│   ├── listings/
│   ├── share-card/
│   ├── maps/
│   ├── reports/
│   └── settings/
│
├── components/
│   ├── ui/
│   ├── mobile/
│   ├── forms/
│   └── shared/
│
├── services/
│   ├── firebase/
│   ├── gemini/
│   ├── drive/
│   ├── sheets/
│   └── maps/
│
├── domain/
│   ├── property/
│   ├── customer/
│   ├── requirement/
│   ├── matching/
│   └── task/
│
└── config/
    ├── property-types.ts
    ├── transaction-types.ts
    ├── property-statuses.ts
    ├── directions.ts
    ├── favorite-areas.ts
    ├── required-fields.ts
    └── ui-settings.ts
```

### Quy tắc module

Mỗi module nghiệp vụ nên có:

```text
module-name/
├── components/
├── pages/
├── forms/
├── hooks/
├── services/
├── types/
├── validators/
└── index.ts
```

Không gọi Firebase/Gemini trực tiếp từ component giao diện. UI gọi service/domain layer.

---

# 4. PROPERTY DATA CONTRACT V1

## 4.1 Loại bất động sản

Mã nội bộ cố định, giao diện tiếng Việt:

| Code | Hiển thị |
|---|---|
| `HOUSE` | Nhà |
| `LAND` | Đất nền |
| `AGRICULTURAL_LAND` | Đất nông nghiệp |
| `WAREHOUSE` | Kho xưởng |

## 4.2 Hình thức giao dịch

| Code | Hiển thị |
|---|---|
| `SALE` | Mua bán |
| `RENT` | Cho thuê |

## 4.3 Trạng thái

| Code | Hiển thị |
|---|---|
| `ACTIVE` | Đang bán |
| `SOLD` | Đã bán |
| `PAUSED` | Tạm ngưng |

> Khi giao dịch là Cho thuê, UI có thể diễn giải trạng thái phù hợp trong tương lai nhưng không tự thay đổi enum lõi nếu chưa nâng version Data Contract.

## 4.4 Hướng — danh mục cố định

- Đông
- Nam
- Tây
- Bắc
- Tây Bắc
- Tây Nam
- Đông Bắc
- Đông Nam

Mã đề xuất: `E`, `S`, `W`, `N`, `NW`, `SW`, `NE`, `SE`.

## 4.5 Địa bàn

- Cho phép nhập/chọn **Tỉnh/Thành**.
- Mặc định: **TP Cần Thơ**.
- Khu vực yêu thích hiển thị đầu tiên:
  - Phường Phú Lợi.
  - Phường Mỹ Xuyên.
  - Phường Sóc Trăng.
  - Xã Trần Đề.
- Vẫn cho phép tìm/chọn các phường/xã khác.
- Không hard-code khu vực yêu thích vào component; đọc từ config/settings.

## 4.6 Trường bắt buộc khi lưu chính thức

### Mọi BĐS

- Loại BĐS.
- Hình thức giao dịch.
- Trạng thái.
- Tỉnh/Thành.
- Khu vực/phường/xã.
- **Hướng.**
- **Giá.**
- **Ngang.**
- **Dài.**
- **Ảnh: tối thiểu 1.**
- **Chủ sở hữu.**

### Phòng ngủ

- Nhà: bắt buộc nhập, >= 0.
- Đất nền: tự động 0.
- Đất nông nghiệp: tự động 0.
- Kho xưởng: mặc định 0, cho phép sửa nếu có khu ở/văn phòng.

## 4.7 Trường không bắt buộc

- Link video.
- Tọa độ latitude/longitude.
- Link Google Maps.
- Số điện thoại chủ.
- Link nguồn tin.
- Ghi chú.
- Pháp lý chi tiết.
- Lộ giới.
- Tiện ích.
- Tag.

## 4.8 Trường tính tự động

- Diện tích dự kiến = ngang × dài.
- Giá/m² = giá / diện tích khi đủ dữ liệu.
- Giá hiển thị thân thiện:
  - 850000000 → 850 triệu.
  - 1290000000 → 1,29 tỷ.
- Ngày tạo.
- Ngày cập nhật.
- Freshness score.
- Duplicate score khi kiểm tra.

---

## 5. Property Schema đề xuất

```ts
interface Property {
  id: string;
  code: string;
  title: string;

  type: 'HOUSE' | 'LAND' | 'AGRICULTURAL_LAND' | 'WAREHOUSE';
  transactionType: 'SALE' | 'RENT';
  status: 'ACTIVE' | 'SOLD' | 'PAUSED';

  location: {
    provinceCity: string;      // default: TP Cần Thơ
    wardCommune: string;
    hamlet?: string;
    street?: string;
    projectArea?: string;
    addressText?: string;
    latitude?: number;
    longitude?: number;
    mapUrl?: string;
  };

  dimensions: {
    width: number;
    length: number;
    rearWidth?: number;
    calculatedArea?: number;
    officialArea?: number;
  };

  direction: 'E' | 'S' | 'W' | 'N' | 'NW' | 'SW' | 'NE' | 'SE';
  bedrooms: number;
  bathrooms?: number;

  legal?: {
    landType?: string;
    residentialArea?: number;
    separateCertificate?: boolean;
    completedConstruction?: boolean;
    note?: string;
  };

  road?: {
    roadWidth?: number;
    carAccess?: boolean;
    frontage?: boolean;
    alley?: boolean;
  };

  price: {
    amount: number;
    unit: 'VND';
    pricePerM2?: number;
    negotiable?: boolean;
  };

  owner: {
    name: string;
    phone?: string;
    directOwnerContact?: boolean;
    sourceType?: 'OWNER' | 'BROKER' | 'REFERRAL' | 'OTHER';
  };

  media: {
    images: MediaImage[];
    videoUrl?: string;
  };

  note?: string;
  tags?: string[];
  sourceUrl?: string;

  soldInfo?: {
    soldAt?: string;
    actualSoldPrice?: number;
    note?: string;
  };

  createdAt: string;
  updatedAt: string;
  lastVerifiedAt?: string;
  freshnessScore?: number;
}
```

---

# 6. BĐS đã bán

Không xóa BĐS sau khi bán.

Khi chuyển trạng thái sang **Đã bán**, mở form:

- Ngày bán.
- Giá bán thực tế.
- Ghi chú giao dịch/đã bán.

Giữ lại:

- Giá đăng ban đầu.
- Ảnh.
- Chủ sở hữu.
- Lịch sử cập nhật.
- Khách đã xem/match.
- Hoạt động liên quan.

Mục tiêu dài hạn: AI phân tích giá chào → giá bán thật → thời gian thanh khoản.

---

# 7. Chống trùng sản phẩm

## 7.1 Không dùng kiểm tra ID đơn giản

Duplicate Engine tạo điểm tương đồng từ:

- SĐT chủ sở hữu.
- Chủ sở hữu.
- Tọa độ/khoảng cách.
- Phường/xã/khu vực/đường.
- Ngang.
- Dài.
- Diện tích.
- Giá.
- Loại BĐS.
- Nội dung mô tả.
- Ảnh nếu triển khai image fingerprint sau này.

## 7.2 Luồng lưu

```text
Nhập BĐS
   ↓
Validate bắt buộc
   ↓
Normalize dữ liệu
   ↓
Duplicate Engine
   ↓
Có nghi trùng?
   ├── Không → Lưu
   └── Có → Hiện danh sách nghi trùng
              ↓
       [Xem cũ] [Gộp] [Vẫn lưu]
```

Không tự động xóa/gộp bằng AI.

---

# 8. Customer Data Model

```ts
interface Customer {
  id: string;
  name: string;
  phone?: string;
  zalo?: string;
  facebook?: string;
  source?: string;
  status: string;
  priority?: 'NORMAL' | 'HIGH' | 'URGENT';
  note?: string;
  createdAt: string;
  updatedAt: string;
}
```

Một khách có thể có **nhiều Requirement**.

---

# 9. Requirement — nhu cầu khách

```ts
interface Requirement {
  id: string;
  customerId: string;

  transactionType?: 'SALE' | 'RENT';
  propertyTypes?: string[];
  provinceCities?: string[];
  wardCommunes?: string[];

  priceMin?: number;
  priceMax?: number;
  widthMin?: number;
  lengthMin?: number;
  areaMin?: number;
  areaMax?: number;

  directions?: string[];
  bedroomsMin?: number;
  carAccess?: boolean;
  legalPreferences?: string[];

  semanticPreferences?: string[];
  rawRequirementText?: string;

  urgency?: 'NORMAL' | 'HIGH' | 'URGENT';
  desiredPurchaseDate?: string;
  status: 'ACTIVE' | 'PAUSED' | 'FULFILLED';
}
```

---

# 10. AI Matching Engine

## 10.1 Matching hai chiều

1. **Khách → BĐS**.
2. **BĐS → Khách**.

## 10.2 Pipeline

```text
Ngôn ngữ tự nhiên
       ↓
Gemini Requirement Parser
       ↓
Structured Requirement
       ↓
Hard Filter Firestore
       ↓
Candidate Set
       ↓
Weighted Scoring
       ↓
Semantic Evaluation
       ↓
TOP MATCHES
       ↓
AI giải thích lý do
```

## 10.3 Hard constraints

Các câu như:

- “tối đa 1,5 tỷ”
- “chỉ Phú Lợi”
- “phải xe hơi tới”
- “ít nhất 3 phòng ngủ”

có thể trở thành điều kiện loại trực tiếp. Không được để AI cho điểm cao một BĐS vi phạm điều kiện cứng.

## 10.4 Weighted score mặc định

Có thể cấu hình, không hard-code trong UI:

| Yếu tố | Điểm gợi ý |
|---|---:|
| Khu vực | 25 |
| Giá | 20 |
| Loại BĐS | 15 |
| Diện tích/kích thước | 10 |
| Phòng ngủ | 10 |
| Hướng | 5 |
| Pháp lý | 5 |
| Ô tô/lộ | 5 |
| Semantic preference | 5 |
| **Tổng** | **100** |

---

# 11. AI Data Intake

Các nguồn nhập:

- Dán tin Zalo.
- Dán tin Facebook.
- Văn bản tự do.
- Screenshot/ảnh.
- Giọng nói.
- Form thủ công.
- Import JSON/Excel ở phase sau.

## Luồng chuẩn

```text
INPUT
 ↓
Gemini parse
 ↓
JSON có cấu trúc
 ↓
Normalize
 ↓
Validate
 ↓
Highlight trường thiếu
 ↓
Duplicate check
 ↓
Preview
 ↓
User xác nhận
 ↓
Firestore
```

### Quy tắc AI

- Không đoán hướng.
- Không đoán giá.
- Không đoán kích thước.
- Không đoán chủ sở hữu.
- Không tự tạo ảnh.
- Không tự xác nhận BĐS đang bán nếu nguồn không rõ.
- Trường thiếu phải để `null`/undefined và báo người dùng.
- Cho phép **Lưu nháp** khi chưa đủ dữ liệu.
- Không cho **Lưu chính thức** nếu thiếu trường bắt buộc.

---

# 12. Gemini Strategy

Dùng lớp `AIProvider` để không khóa code vào một model duy nhất.

```ts
interface AIProvider {
  parseProperty(input: unknown): Promise<PropertyDraft>;
  parseRequirement(text: string): Promise<RequirementDraft>;
  explainMatch(input: MatchContext): Promise<string>;
  generateListing(input: ListingContext): Promise<string>;
  summarizeCustomer(input: CustomerContext): Promise<string>;
}
```

Gemini là provider mặc định.

Tách nhiệm vụ:

- Model nhanh/rẻ: parsing, normalize, caption đơn giản.
- Model mạnh hơn: reasoning/matching phức tạp khi cần.
- Vision: ảnh/screenshot.

Không giả định gói Gemini consumer đồng nghĩa API không giới hạn; app phải có quota/error handling.

---

# 13. AI Sales Copilot

AI không truy cập Firestore tùy ý. Chỉ dùng tool layer có kiểm soát.

### Tool dự kiến

```text
searchProperties
getProperty
createPropertyDraft
updateProperty
searchCustomers
getCustomer
createCustomer
createRequirement
matchPropertiesForCustomer
findCustomersForProperty
createTask
updateTask
getUrgentTasks
createAppointment
generateListing
summarizeCustomer
detectDuplicate
getStaleProperties
```

### Hành động cần xác nhận

- Xóa BĐS.
- Xóa khách.
- Đổi giá.
- Chuyển sang Đã bán.
- Gộp duplicate.
- Gửi nội dung ra ngoài nếu sau này tích hợp API gửi tin.

---

# 14. Task / Công việc

```ts
interface Task {
  id: string;
  title: string;
  type: 'CALL' | 'ZALO' | 'VIEWING' | 'SEND_PROPERTY' | 'LEGAL' | 'FOLLOW_UP' | 'OTHER';
  customerId?: string;
  propertyId?: string;
  dueAt?: string;
  priority: 'NORMAL' | 'HIGH' | 'URGENT';
  status: 'TODO' | 'DONE' | 'CANCELLED';
  note?: string;
}
```

Dashboard ưu tiên:

1. Quá hạn.
2. Gấp.
3. Có match mới mạnh.
4. Khách lâu chưa chăm.
5. BĐS lâu chưa xác minh.

---

# 15. Freshness Engine

Mỗi BĐS có `lastVerifiedAt`.

Dashboard có:

- > 7 ngày chưa xác minh.
- > 15 ngày.
- > 30 ngày.

Freshness score không thay thế trạng thái. Mục tiêu là nhắc xác minh lại:

- Giá.
- Còn bán/cho thuê hay không.
- Chủ còn nhu cầu không.
- Pháp lý/thông tin có thay đổi không.

---

# 16. Share Card / Zalo

`share-card` là module độc lập.

Mỗi BĐS có:

- Copy nội dung.
- Chia sẻ link public card.
- Tạo ảnh card để gửi Zalo.

### Nội dung card mặc định

```text
🏡 [TIÊU ĐỀ]

📍 [KHU VỰC]
📐 [NGANG] × [DÀI] – [DIỆN TÍCH]
🧭 [HƯỚNG]
🛏 [PHÒNG NGỦ nếu phù hợp]
💰 [GIÁ]
📷 [SỐ ẢNH]

▶ Video (nếu có)
📍 Bản đồ (nếu có)

Lắm BĐS Sóc Trăng
0946 261 719
```

Không đưa tên/SĐT chủ sở hữu vào thẻ public mặc định.

---

# 17. UI/UX DESIGN SYSTEM V1

## 17.1 Hướng thiết kế

Lấy cảm hứng từ giao diện CRM mobile tham chiếu người dùng đã chọn:

- Header xanh.
- Nền sáng.
- Card trắng bo góc.
- Shadow nhẹ.
- Icon module trực quan.
- Dashboard theo card.
- Card BĐS/nhu cầu có ảnh + thông tin cô đọng.
- Badge Matching % nổi bật.
- Bottom navigation cố định.
- Nút `+` lớn ở giữa.

Không sao chép nguyên giao diện/hình ảnh/tài sản của sản phẩm tham chiếu.

## 17.2 Bottom Navigation iPhone

```text
[ Nhà ] [ BĐS ] [  +  ] [ Khách ] [ AI ]
```

Nút `+` mở Quick Add Sheet:

- Dán tin BĐS.
- Chụp/chọn ảnh → AI.
- Nhập BĐS thủ công.
- Thêm khách.
- Thêm nhu cầu.
- Tạo việc.
- Nhập bằng giọng nói.

## 17.3 Property Card Mobile

Thông tin ưu tiên nhìn ngay:

- Ảnh đại diện.
- Loại BĐS.
- Khu vực.
- Ngang × dài.
- Diện tích.
- Hướng.
- Phòng ngủ nếu là Nhà.
- Giá.
- Trạng thái.
- Chủ sở hữu/nắm chủ ở chế độ nội bộ.
- Match count / match score.

Action nhanh:

- Chia sẻ/Zalo.
- Gọi nếu có số phù hợp.
- Xem chi tiết.
- Menu `...`.

## 17.4 iPhone 16 Pro Max requirements

- Mobile-first từ breakpoint nhỏ nhất.
- Tôn trọng safe-area top/bottom.
- Bottom nav không che nội dung.
- Touch target tối thiểu khoảng 44×44pt.
- Không đặt các nút quan trọng sát Dynamic Island/home indicator.
- Form ưu tiên một tay.
- Numeric keyboard cho giá/ngang/dài.
- Camera/photo picker dễ truy cập.
- Không có horizontal scrolling cho form chính.
- Text quan trọng không quá nhỏ.
- Sticky save/action khi form dài.

---

# 18. Dashboard Mobile V1

```text
LẮM AI CRM                         🔍 ⚙️
TP Cần Thơ

[ 👥 Khách ] [ 🏡 Quỹ hàng ] [ 🎯 Matching ] [ ✅ Công việc ]

┌────────────────────────────────┐
│ TỔNG QUỸ HÀNG                  │
│ 2.086 BĐS                      │
│ Nhà / Đất nền / Đất NN / Kho  │
└────────────────────────────────┘

🔥 VIỆC CẦN XỬ LÝ
[Task cards]

🎯 MATCH MỚI
[Match cards]

🏡 BĐS VỪA THÊM
[Property cards]
```

Không ưu tiên biểu đồ nếu biểu đồ không giúp ra quyết định. Dashboard trước hết phải trả lời: **Hôm nay cần làm gì?**

---

# 19. Property Form Mobile V1

Thứ tự nhập ưu tiên:

1. Loại BĐS.
2. Mua bán / Cho thuê.
3. Tỉnh/Thành — default TP Cần Thơ.
4. Khu vực — favorite chips ở đầu.
5. Ngang + Dài.
6. Diện tích tự tính.
7. Hướng.
8. Phòng ngủ.
9. Giá.
10. Chủ sở hữu.
11. Ảnh.
12. Pháp lý/đặc điểm mở rộng.
13. Link video.
14. Tọa độ/map.
15. Ghi chú.
16. Trạng thái.

### Favorite area chips

```text
⭐ Phú Lợi   ⭐ Mỹ Xuyên   ⭐ Sóc Trăng   ⭐ Trần Đề
[ Khu vực khác... ]
```

### Hướng

Dùng button/chip grid trên mobile thay vì dropdown dài.

---

# 20. Firestore Collections V1

```text
users/
properties/
customers/
requirements/
matches/
tasks/
appointments/
activities/
templates/
settings/
areas/
aiLogs/
```

### Nguyên tắc

- Không lưu ảnh binary trong document Firestore.
- Document không phình to do nhúng history vô hạn.
- History/activity tách collection.
- Query phổ biến phải được thiết kế index từ đầu.
- Không đọc toàn bộ collection để filter ở client.

---

# 21. Media Strategy

`MediaImage` chỉ lưu metadata/reference:

```ts
interface MediaImage {
  id: string;
  url: string;
  thumbnailUrl?: string;
  order: number;
  isCover?: boolean;
  createdAt: string;
}
```

Storage phải đi qua adapter:

```ts
interface MediaStorageProvider {
  upload(file: File): Promise<MediaImage>;
  remove(id: string): Promise<void>;
}
```

Nhờ vậy có thể dùng giải pháp Google/Firebase phù hợp hiện tại và đổi storage sau mà không sửa module BĐS.

---

# 22. Google Drive / Sheets

## Drive

Dùng cho:

- Backup định kỳ.
- Export JSON.
- Tài liệu/file bổ sung nếu cần.

Không dùng Google Drive làm database giao dịch chính.

## Sheets

Dùng cho:

- Export quỹ hàng.
- Export khách/nhu cầu.
- Báo cáo/chia sẻ nhanh.
- Import có kiểm tra ở phase sau.

Không dùng Sheets làm database chính.

---

# 23. Search

Hỗ trợ 2 lớp:

### Structured Search

- Loại.
- Mua bán/cho thuê.
- Trạng thái.
- Khu vực.
- Giá.
- Ngang/dài/diện tích.
- Hướng.
- Phòng ngủ.
- Chủ sở hữu.

### Natural Language Search

Ví dụ:

> “nhà Phú Lợi dưới 1 tỷ 5 hướng đông”

Gemini parse thành filter có cấu trúc rồi query database. Không gửi toàn bộ database lên model.

---

# 24. Settings / Config Center

Cho phép chỉnh mà không sửa nhiều code:

- Khu vực yêu thích.
- Trường hiển thị trên Property Card.
- Trường bắt buộc nếu Data Contract cho phép cấu hình.
- Trọng số Matching.
- Menu bật/tắt.
- Thứ tự module.
- Template chia sẻ.
- Template tin đăng.
- Thông tin thương hiệu.
- AI model/provider.

**Các enum lõi của Data Contract không được đổi tùy tiện bằng UI nếu thay đổi có thể phá dữ liệu.** Muốn đổi phải version schema.

---

# 25. Security & Privacy

- Firebase Security Rules bắt buộc.
- Không expose Gemini API key ở client nếu key cần bảo vệ; gọi qua server-side endpoint phù hợp.
- Public share card không chứa dữ liệu chủ sở hữu mặc định.
- Log AI không lưu dữ liệu nhạy cảm không cần thiết.
- Mọi mutation quan trọng ghi Activity Log.
- Role system chuẩn bị sẵn dù V1 chỉ có một người dùng chính.

---

# 26. Activity / Audit Log

Theo dõi:

- Tạo BĐS.
- Sửa giá.
- Đổi trạng thái.
- Chuyển Đã bán.
- Thay chủ/người liên hệ.
- Gộp duplicate.
- Tạo/xử lý task.
- AI đề xuất và user xác nhận hành động quan trọng.

Không dùng Activity Log làm nơi lưu toàn bộ snapshot nếu gây chi phí lớn; chỉ lưu dữ liệu cần audit.

---

# 27. PWA / Offline

- Add to Home Screen trên iPhone.
- App shell cache.
- Hiển thị trạng thái online/offline.
- Cho phép draft khi mất mạng nếu khả thi.
- Queue thao tác an toàn để đồng bộ lại.
- Không hứa offline hoàn toàn cho mọi chức năng AI.
- Gemini/Maps/share online cần mạng.

---

# 28. Marketing / Listing Generator

Từ Property data tạo:

- Facebook.
- Zalo.
- Marketplace.
- TikTok caption.
- Bản ngắn.
- Bản dành cho nhà đầu tư.
- Bản dành cho người mua ở.

Quy tắc:

- AI chỉ sử dụng dữ liệu có trong Property/brand settings.
- Không tự thêm pháp lý/tiện ích/khoảng cách không có nguồn.
- Cho phép user chỉnh trước khi copy/chia sẻ.

---

# 29. UI Components quan trọng phải tách riêng

```text
MobileHeader
BottomNavigation
QuickAddSheet
DashboardSummaryCard
PropertyCardMobile
PropertyCardDesktop
CustomerCardMobile
RequirementCard
TaskCard
MatchBadge
MatchCard
FavoriteAreaPicker
DirectionPicker
PriceInput
DimensionInput
OwnerInput
MediaPicker
PropertyStatusBadge
SharePropertyCard
AiInputBar
AiConfirmationDialog
DuplicateWarningSheet
FreshnessBadge
```

Mục tiêu: đổi `PropertyCardMobile` không làm thay đổi Property schema hoặc Matching Engine.

---

# 30. Quy tắc code cho AI Studio/Coding Agent

1. Đọc toàn bộ MASTER BLUEPRINT trước khi code.
2. Không tự thay đổi architecture.
3. Không đổi enum/Data Contract nếu chưa có yêu cầu rõ ràng.
4. Không hard-code Firebase/Gemini trong UI component.
5. Không tạo component khổng lồ chứa UI + DB + AI logic.
6. Mỗi module có types, validators, service riêng.
7. Mobile-first.
8. Tất cả UI người dùng là tiếng Việt.
9. Mọi form phải có validation rõ ràng.
10. Không lưu chính thức Property thiếu required fields.
11. Cho phép Draft khi thiếu dữ liệu.
12. Duplicate check trước khi lưu chính thức.
13. AI không được tự đoán required field.
14. Mọi destructive/critical mutation phải confirmation.
15. Code phải dễ thay UI module mà không sửa domain logic.
16. Không tự thêm dependency lớn nếu chưa cần.
17. Mỗi phase phải build/run được trước khi chuyển phase tiếp theo.
18. Không viết lại module đã ổn nếu chỉ cần bổ sung tính năng nhỏ.
19. Có loading, empty, error states.
20. Tôn trọng iPhone safe areas và touch targets.

---

# 31. Roadmap triển khai

## PHASE 1 — Foundation

- Next.js/PWA.
- Firebase project/config.
- Authentication.
- Design system.
- Mobile shell.
- Bottom navigation.
- Config layer.
- Firestore base services.

## PHASE 2 — Property Core

- Property schema.
- Property form.
- Favorite areas.
- Required validation.
- Media.
- Property list/card.
- Detail/edit.
- Status + sold info + notes.
- Search/filter.

## PHASE 3 — Customer & Requirement

- Customer CRUD.
- Requirement CRUD.
- Customer timeline.
- Pipeline.
- Quick actions.

## PHASE 4 — Tasks & Dashboard

- Task system.
- Việc cần gấp.
- Overdue.
- Calendar/appointments.
- Dashboard actionable cards.
- Freshness engine.

## PHASE 5 — AI Intake

- Gemini provider.
- Paste text → parse.
- Image/screenshot → parse.
- Voice input → structured draft.
- Preview/validation.
- Duplicate detection.

## PHASE 6 — AI Matching

- Hard filter.
- Weighted scoring.
- Semantic evaluation.
- Customer → Property.
- Property → Customer.
- Match explanation.
- Match badges/cards.

## PHASE 7 — AI Sales Copilot

- Tool layer.
- Natural-language search.
- Daily recommendations.
- Customer summary.
- Property intelligence.
- Confirmation gates.

## PHASE 8 — Sharing & Marketing

- Zalo share card.
- Public property card/link.
- Listing generator.
- Video/map actions.
- Brand templates.

## PHASE 9 — Backup / Import / Export

- JSON export/import.
- Google Drive backup.
- Google Sheets export.
- Data recovery process.

## PHASE 10 — Hardening

- Security rules.
- Index optimization.
- Performance.
- iPhone UX QA.
- Offline behavior.
- Error recovery.
- Audit log.
- Backup restore test.

---

# 32. Definition of Done V1

V1 được coi là sử dụng thực tế khi người dùng có thể:

1. Mở CRM từ icon trên iPhone.
2. Đăng nhập Google.
3. Thêm BĐS thủ công nhanh.
4. Dán tin và để Gemini tạo draft.
5. Chụp/chọn ảnh và gắn vào BĐS.
6. Không lưu chính thức nếu thiếu required fields.
7. Phát hiện sản phẩm nghi trùng.
8. Tìm/lọc quỹ hàng nhanh.
9. Quản lý khách và nhiều nhu cầu.
10. Match Khách → BĐS.
11. Match BĐS → Khách.
12. Thấy việc cần làm ngay trên Dashboard.
13. Quản lý BĐS Đang bán / Đã bán / Tạm ngưng.
14. Lưu ghi chú và giá bán thực tế khi Đã bán.
15. Lưu link video và tọa độ khi có.
16. Chia sẻ thẻ BĐS qua Zalo.
17. Hỏi AI bằng ngôn ngữ tự nhiên.
18. Export/backup dữ liệu.
19. Thay một UI card/module mà không phải sửa database/AI engine.

---

# 33. Quyết định kiến trúc đã CHỐT

- CRM mới là **Web App/PWA**, không lấy Android Native làm nền tảng chính.
- **iPhone 16 Pro Max first**.
- **Firebase/Firestore là data core V1**.
- **Gemini là AI provider mặc định**.
- Google Drive/Sheets dùng cho backup/export, không làm database chính.
- UI module hóa hoàn toàn.
- Loại BĐS: Nhà / Đất nền / Đất nông nghiệp / Kho xưởng.
- Giao dịch: Mua bán / Cho thuê.
- Trạng thái: Đang bán / Đã bán / Tạm ngưng.
- Hướng cố định 8 hướng.
- Default tỉnh/thành: TP Cần Thơ.
- Favorite areas: Phú Lợi / Mỹ Xuyên / Sóc Trăng / Trần Đề.
- Required: hướng, giá, ngang, dài, phòng ngủ theo rule loại BĐS, ảnh, chủ sở hữu + các field lõi loại/giao dịch/trạng thái/vị trí.
- Link video và tọa độ không bắt buộc.
- Có ghi chú BĐS và ghi chú khi đã bán.
- Chống duplicate trước khi lưu chính thức.
- Matching hai chiều.
- Có Zalo share card.
- Giao diện theo hướng mobile CRM: header xanh, card sáng, bottom nav + nút `+` trung tâm.

---

# 34. Nguyên tắc nâng version

Mọi thay đổi làm ảnh hưởng schema/enum/required fields phải tạo phiên bản mới:

```text
PROPERTY DATA CONTRACT V1
        ↓
PROPERTY DATA CONTRACT V1.1
        ↓
Migration nếu cần
```

Không sửa âm thầm schema đã có dữ liệu thật.

---

## KẾT THÚC MASTER BLUEPRINT V1

Tài liệu này là **nguồn sự thật kiến trúc (single source of truth)** cho quá trình triển khai. Khi yêu cầu mới xung đột với tài liệu, phải cập nhật Blueprint/Data Contract trước rồi mới code.
