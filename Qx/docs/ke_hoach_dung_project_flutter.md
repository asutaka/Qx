# Kế Hoạch Triển Khai Chi Tiết: Di Chuyển Lên Flutter (Flutter Migration Plan)

Tài liệu này trình bày các bước chi tiết để xây dựng ứng dụng di động **Quiz Arena** sử dụng Flutter, kế thừa toàn bộ tính năng và phong cách thiết kế từ nguyên mẫu Web Prototype (Neon Glassmorphism, BGM, Cờ Quốc gia, Cửa hàng Trang phục & Quảng cáo mô phỏng).

---

## 🏗️ Cấu Trúc Thư Mục Dự Án (Project Structure)

Để đảm bảo tính mở rộng và quản lý code khoa học, dự án Flutter sẽ được tổ chức theo mô hình phân lớp (Clean Architecture / Feature-oriented):

```text
lib/
├── core/
│   ├── theme/
│   │   ├── colors.dart         # Định nghĩa bảng màu Neon (Accent Cyan, Pink, Dark background)
│   │   └── typography.dart     # Cấu hình Google Fonts (Outfit & Space Grotesk)
│   └── constants/
│       └── shop_items.dart     # Danh sách vật phẩm shop (Hat, Shoes, Character, Effect)
├── data/
│   ├── models/
│   │   ├── question.dart       # Model câu hỏi OTDB
│   │   ├── game_state.dart     # Model trạng thái người chơi lưu local
│   │   └── rank_item.dart      # Model xếp hạng
│   ├── services/
│   │   ├── api_service.dart    # Giao tiếp với Open Trivia Database API
│   │   ├── database_service.dart# Quản lý SQLite (sqflite) lưu trữ thay thế localStorage
│   │   └── translation_service.dart # Sử dụng Google ML Kit dịch ngoại tuyến
│   └── ad_helper.dart          # Quản lý Google Mobile Ads SDK (Rewarded/Interstitial)
├── logic/
│   ├── game_bloc.dart          # BLoC quản lý trạng thái Single & Battle Mode
│   └── shop_bloc.dart          # BLoC quản lý mua sắm, trang bị vật phẩm
└── presentation/
    ├── screens/
    │   ├── lobby_screen.dart   # Màn hình chính (Sảnh chờ)
    │   ├── quiz_screen.dart    # Màn hình Single Mode (100 câu hỏi)
    │   ├── battle_screen.dart  # Màn hình Battle Mode (Đường đua 1v1)
    │   ├── shop_screen.dart    # Cửa hàng trang phục
    │   ├── settings_screen.dart# Cấu hình âm thanh, tên, quốc tịch, ngôn ngữ
    │   └── rank_screen.dart    # Bảng xếp hạng
    └── widgets/
        ├── glass_container.dart# Widget hiệu ứng kính mờ Neon
        ├── runner_widget.dart  # Widget nhân vật hoạt họa kèm mũ, giày, hiệu ứng
        └── ad_overlay.dart     # Widget xem quảng cáo mô phỏng hoặc ad gốc
```

---

## 📦 Các Thư Viện Cần Thiết (`pubspec.yaml`)

Thêm các dependency sau vào file `pubspec.yaml` của bạn để đáp ứng các tính năng tương đương với bản Web:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Quản lý trạng thái
  flutter_bloc: ^8.1.3         # Hoặc sử dụng provider/riverpod tùy chọn

  # Giao diện & Fonts
  google_fonts: ^6.1.0         # Tải và áp dụng Outfit, Space Grotesk
  flutter_svg: ^2.0.9          # Hiển thị icon SVG nếu cần

  # Kết nối mạng & Cơ sở dữ liệu
  http: ^1.2.0                 # Gọi API lấy câu hỏi
  sqflite: ^2.3.0              # Cơ sở dữ liệu SQLite lưu trữ dữ liệu local
  path: ^1.9.0                 # Hỗ trợ cấu hình đường dẫn database

  # SDK Di động thực tế (Phase 3)
  google_mlkit_translation: ^0.12.0  # Dịch ngoại tuyến offline bằng Google ML Kit
  google_mobile_ads: ^5.0.0          # Google AdMob (Rewarded & Interstitial Ads)
```

---

## 🚀 Các Bước Triển Khai Từng Bước (Step-by-Step Implementation)

### Bước 1: Khởi Tạo Dự Án & Cấu Hình Môi Trường
1. Khởi tạo dự án bằng Terminal:
   ```bash
   flutter create quiz_arena --platforms=android,ios,web
   ```
2. Thêm các dependencies vào `pubspec.yaml` và chạy lệnh `flutter pub get`.
3. Nhập các font chữ từ Google Fonts (Outfit, Space Grotesk) hoặc cấu hình thông qua gói `google_fonts` trong `ThemeData`.

### Bước 2: Tái Tạo Hiệu Ứng Neon Glassmorphism (`presentation/widgets/glass_container.dart`)
Tái cấu trúc lớp kính mờ từ CSS bằng cách kết hợp `BackdropFilter` và `BoxDecoration` có viền gradient phát sáng:

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color borderColor;

  const GlassContainer({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.borderColor = Colors.white12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
```

### Bước 3: Đưa Core Data Models & API Services Vào Thư Mục
1. Sao chép và tổ chức lại các file model Dart mẫu có sẵn từ thư mục `docs/` (`trivia_category.dart`, `trivia_difficulty.dart`, `trivia_api_service.dart`) sang các thư mục tương ứng:
   * `trivia_category.dart` và `trivia_difficulty.dart` -> `lib/data/models/`
   * `trivia_api_service.dart` -> `lib/data/services/`
2. Viết class `DatabaseHelper` kế thừa SQLite để thay thế hoàn toàn `localStorage`, hỗ trợ lưu trữ:
   * Vàng hiện tại (`gold`), vàng tích lũy (`accumulatedGold`), kỷ lục điểm (`singleHighScore`).
   * Mã quốc tịch (`country`), mức âm lượng (`volume`), ngôn ngữ mục tiêu (`targetLanguage`).
   * Các danh sách vật phẩm đã sở hữu và vật phẩm đang trang bị.

### Bước 4: Viết State Management Logic (BLoC hoặc Provider)
Quản lý trạng thái thông qua các State chính:
* `LobbyState`: Hiển thị thông tin người chơi, quản lý đếm ngược 900 giây của nút **Daily Gift & Ads**.
* `QuizState`: Trạng thái chơi Single Mode (số câu hỏi, thời gian đếm ngược, kích hoạt các lifeline cứu trợ).
* `BattleState`: Quản lý đường đua Battle Mode (tính toán khoảng cách vị trí chạy, đếm ngược thời gian thực, cập nhật điểm số Player và Bot).

### Bước 5: Thiết Kế Màn Hình Trận Đấu (Battle Mode Screen)
Để tạo hiệu ứng chạy đua thời gian thực động:
1. Dùng widget `Stack` để chồng 2 đường chạy (Player Lane và Bot Lane).
2. Mỗi lane dùng một `LayoutBuilder` để lấy chiều rộng tối đa của đường đua.
3. Nhân vật sẽ được bao bọc bởi một widget `AnimatedPositioned` với thuộc tính `left` tỷ lệ thuận với số điểm hiện tại:
   ```dart
   double progressPercent = playerScore / 10.0;
   double leftOffset = progressPercent * (maxRaceWidth - runnerWidth);
   ```
4. **Vẽ các phụ kiện (Cosmetics):**
   * Sử dụng widget `Stack` phía trên ảnh chân dung nhân vật.
   * Nếu có trang bị mũ, vẽ một `Positioned` đặt mũ emoji hoặc ảnh PNG lên đầu nhân vật.
   * Nếu có hiệu ứng chạy, vẽ một Widget hoạt họa phát sáng (VD: `Opacity` nhấp nháy hoặc hạt hiệu ứng lửa bốc lên sau lưng nhân vật).

### Bước 6: Thiết Kế Nút Daily Gift 2 Chức Năng (Claim & Rewarded Ad)
Tái tạo nút xem quảng cáo nhận quà đếm ngược 15 phút:
1. Nếu `DateTime.now() - lastDailyClaim >= 24h`: Hiển thị nút **Claim 1,000**.
2. Nếu đã nhận quà:
   * Kiểm tra cooldown 15 phút (`900` giây) tính từ lần xem quảng cáo trước đó.
   * Nếu đã hết 15 phút: Hiển thị nút **Xem QC +500 🎬** (thiết kế màu hồng/tím gradient phát sáng). Click vào sẽ hiện màn hình giả lập quảng cáo 5 giây.
   * Nếu đang trong thời gian đếm ngược: Vô hiệu hóa nút và dùng một `Stream` hoặc `Timer` đếm ngược hiển thị: **`Xem QC +500 (14m 30s)`**.

---

## 🧪 Quy Trình Kiểm Thử (Testing & QA)

> [!TIP]
> Việc kiểm thử trên Flutter cực kỳ linh hoạt nhờ các công cụ hỗ trợ trực tiếp từ CLI và UI của Flutter SDK.

1. **Kiểm thử giao diện nhanh (Flutter Web):**
   * Chạy lệnh: `flutter run -d chrome`.
   * Thử nghiệm nhanh các sự kiện hover, nhấp chuột, hiệu ứng chuyển động và kiểm tra responsive kích thước màn hình.
2. **Kiểm thử Native (Điện thoại Android thật):**
   * Kết nối điện thoại bật USB Debugging.
   * Chạy lệnh: `flutter run -d <tên_thiết_bị>`.
   * Sử dụng tính năng **Hot Reload** (ấn `r` trên terminal) để cập nhật code thay đổi giao diện gần như tức thì mà không phải build lại ứng dụng.
3. **Kiểm thử tự động (Automation):**
   * Viết file kiểm thử unit test cho `TriviaApiService` trong thư mục `test/` để đảm bảo API phân tách câu hỏi đúng.
   * Viết widget test để giả lập nhấp nút cứu trợ 50/50 và xem đáp án có bị ẩn đi 2 phương án sai hay không.
