// File tạm để dự án vẫn biên dịch trước khi kết nối Firebase.
// Chạy `flutterfire configure` sẽ ghi đè file này bằng cấu hình thật.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => ios,
      _ => throw UnsupportedError(
          'Firebase chưa được cấu hình cho nền tảng này.',
        ),
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBi2wDfKj6tRXWGUk9rMEZk4l526aBtKFw',
    appId: '1:299415540344:web:49b36a6364ccaaced9138d',
    messagingSenderId: '299415540344',
    projectId: 'prm-prj-72dea',
    authDomain: 'prm-prj-72dea.firebaseapp.com',
    storageBucket: 'prm-prj-72dea.firebasestorage.app',
    measurementId: 'G-VRMTDQM2PQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpkjcTb2txheA4SpZywAZOh4yQ91YQHmM',
    appId: '1:299415540344:android:8eef5ed6d0bb2f89d9138d',
    messagingSenderId: '299415540344',
    projectId: 'prm-prj-72dea',
    storageBucket: 'prm-prj-72dea.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAKsSlXmGCamoES3DJzbOuGYZqrOySrqLk',
    appId: '1:299415540344:ios:2c999958032fcc42d9138d',
    messagingSenderId: '299415540344',
    projectId: 'prm-prj-72dea',
    storageBucket: 'prm-prj-72dea.firebasestorage.app',
    iosBundleId: 'vn.freelanceflow.app',
  );
}
