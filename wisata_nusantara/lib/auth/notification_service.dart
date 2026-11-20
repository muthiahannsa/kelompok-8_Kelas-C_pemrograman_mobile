import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initNotification(GlobalKey<ScaffoldMessengerState> messengerKey) async {
    try {
      // 1. Minta izin notifikasi ke pengguna (Wajib untuk Android 13+ & iOS)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Ambil Token perangkat (Token ini dipakai untuk tes kirim pesan dari Firebase Console)
        if (!kIsWeb) {
          String? token = await _fcm.getToken();
          debugPrint('=== FCM TOKEN PERANGKAT INI ===');
          debugPrint(token);
          debugPrint('===============================');
        }

        // 3. Tangkap notifikasi saat aplikasi sedang dibuka (Foreground)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final title = message.notification?.title ?? 'Info Wisata Nusantara';
          final body = message.notification?.body ?? 'Ada pembaruan terbaru!';

          // Tampilkan pesan pop-up di dalam aplikasi
          messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('$title: $body'),
              backgroundColor: Colors.blueAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Gagal inisialisasi notifikasi (abaikan jika tes di Chrome): $e');
    }
  }
}