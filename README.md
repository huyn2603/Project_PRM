# FreelanceFlow — Firebase và push notification

Ứng dụng Flutter quản lý tài chính freelancer. Dữ liệu và đăng nhập đã được
chuyển sang Firebase:

- Firebase Authentication: đăng ký/đăng nhập Email & Password.
- Cloud Firestore: profile, dự án, token thiết bị và hộp thư notification.
- Firebase Cloud Messaging (FCM): push notification Android/iOS/Web.
- Cloud Functions: cảnh báo thanh toán, rủi ro và dự án quá hạn.
- Notification router: bấm thông báo sẽ mở đúng tab; thông báo dự án còn tự
  mở và cuộn tới card chứa `projectId`.

## 1. Chuẩn bị

Cài Flutter, Node.js 22 và Firebase CLI:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

Application ID hiện tại là `vn.freelanceflow.app` trên Android và iOS. Nếu
muốn dùng định danh khác, hãy đổi nó **trước** khi chạy `flutterfire configure`.

## 2. Tạo Firebase project

1. Mở <https://console.firebase.google.com> và tạo project.
2. Authentication > Sign-in method > bật **Email/Password**.
3. Firestore Database > Create database. Chọn region gần người dùng, ví dụ
   `asia-southeast1`.
4. Project Settings > Cloud Messaging: bảo đảm Firebase Cloud Messaging API
   được bật.

Trong thư mục chứa file `pubspec.yaml`, chạy:

```powershell
flutterfire configure
```

Chọn Firebase project vừa tạo và các platform cần dùng. Lệnh này sẽ ghi đè
`lib/firebase_options.dart` placeholder bằng cấu hình thật, đồng thời tạo/cập
nhật file native như `google-services.json` và `GoogleService-Info.plist`.

Sau đó liên kết Firebase CLI với project:

```powershell
firebase use --add
```

## 3. Deploy Firestore và backend notification

Cloud Function chạy lịch cần Firebase project hỗ trợ Cloud Functions/billing.

```powershell
cd functions
npm install
npm run build
cd ..

firebase deploy --only firestore:rules,firestore:indexes,storage
firebase deploy --only functions
```

Backend có hai function trong `functions/src/index.ts`:

- `notifyProjectChange`: gửi notification khi ghi nhận thêm thanh toán hoặc
  điểm rủi ro của project vượt 55.
- `notifyOverdueProjects`: chạy 08:00 hằng ngày theo múi giờ `Asia/Bangkok`,
  cập nhật project quá hạn và gửi notification.

Không đưa service-account JSON hay server key vào ứng dụng Flutter.

## 4. Chạy ứng dụng

```powershell
flutter pub get
flutter run
```

Nếu chưa chạy `flutterfire configure`, app sẽ hiện màn hình “Cần kết nối
Firebase” thay vì crash.

Sau khi đăng nhập và cho phép notification, FCM token được lưu tại:

```text
users/{uid}/devices/{tokenDocumentId}
```

Dự án của mỗi user nằm tại:

```text
users/{uid}/projects/{projectId}
```

## 5. Cấu hình iOS

Thực hiện trên macOS:

1. Mở `ios/Runner.xcworkspace` bằng Xcode.
2. Signing & Capabilities: chọn Apple Team.
3. Kiểm tra đã có Push Notifications.
4. Kiểm tra Background Modes có Background fetch và Remote notifications.
5. Apple Developer > Keys: tạo APNs Authentication Key.
6. Firebase Console > Project Settings > Cloud Messaging > Apple app:
   upload `.p8`, nhập Key ID và Team ID.

`Runner.entitlements` và `UIBackgroundModes` đã được thêm sẵn vào dự án.

## 6. Cấu hình Web (nếu dùng)

1. Firebase Console > Cloud Messaging > Web Push certificates: tạo VAPID key.
2. Copy `web/firebase-messaging-sw.js.example` thành
   `web/firebase-messaging-sw.js` và điền Firebase Web config.
3. Chạy app với VAPID public key:

```powershell
flutter run -d chrome --dart-define=FIREBASE_WEB_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

Đăng ký `firebase-messaging-sw.js` trong `web/index.html` nếu triển khai Web
Push production.

## 7. Payload dùng để điều hướng

FCM notification phải gửi kèm `data`, và mọi giá trị trong `data` là chuỗi:

```json
{
  "notification": {
    "title": "Thanh toán quá hạn",
    "body": "Dự án Cafe Lumina đã quá hạn 3 ngày"
  },
  "data": {
    "schemaVersion": "1",
    "type": "payment_overdue",
    "screen": "payments",
    "userId": "FIREBASE_AUTH_UID",
    "projectId": "PROJECT_DOCUMENT_ID",
    "notificationId": "NOTIFICATION_DOCUMENT_ID"
  }
}
```

Mapping hiện tại:

| `type` | `screen` | Màn hình |
|---|---|---|
| `payment_due`, `payment_overdue`, `payment_received`, `payment_completed` | `payments` | Thu nợ |
| `project_updated`, `project_risk`, `project_completed`, `project_milestone_completed` | `projects` | Dự án |
| `team_payout_available`, `team_payout_recorded` | `teamPayouts` | Chia tiền |
| `reserve_low` | `reserve` | Dự phòng |
| `monthly_report` | `stats` | Thống kê |
| `general` | `dashboard` | Tổng quan |

App xử lý đủ ba trạng thái:

- Foreground: FCM được chuyển thành local notification có channel ưu tiên cao.
- Background: xử lý qua `FirebaseMessaging.onMessageOpenedApp`.
- Terminated: xử lý qua `FirebaseMessaging.instance.getInitialMessage()`.

Nếu user chưa đăng nhập, app giữ notification pending và chỉ mở sau khi đăng
nhập đúng `userId`. Payload của user khác sẽ bị từ chối.

## 8. Test notification thủ công

1. Chạy app trên thiết bị thật hoặc Android emulator có Google Play Services.
2. Đăng ký/đăng nhập và cho phép notification.
3. Firestore Console > `users/{uid}/devices` > copy trường `token`.
4. Firebase Console > Messaging > Send test message > nhập token.
5. Trong Additional options > Custom data, thêm:

```text
type = project_risk
screen = projects
userId = UID đang đăng nhập
projectId = ID project có thật
notificationId = manual-test-1
```

Test lần lượt khi app đang mở, ở background và đã tắt. Trên Android, không dùng
Force stop trong Settings vì hệ điều hành sẽ chặn FCM cho tới khi mở app lại.

## 9. Kiểm tra mã nguồn

```powershell
flutter analyze
flutter test

cd functions
npm run build
```

Các file chính:

- `lib/services/auth_service.dart`: Firebase Auth.
- `lib/services/project_repository.dart`: CRUD Firestore.
- `lib/services/notification_service.dart`: permission, token, foreground và tap.
- `lib/models/notification_intent.dart`: allow-list điều hướng notification.
- `firestore.rules`: phân quyền dữ liệu theo UID.
- `storage.rules`: chỉ chủ tài khoản được tải ảnh đại diện (tối đa 5 MB).
- `functions/src/index.ts`: gửi FCM bằng Firebase Admin SDK.
