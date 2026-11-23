import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handler notifikasi saat aplikasi di background / ditutup (FCM).
/// Harus top-level. Notifikasi dengan payload "notification" ditampilkan
/// otomatis oleh sistem Android/iOS, jadi tidak perlu kode tambahan di sini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Notifikasi background diterima: ${message.messageId}');
}

/// Layanan notifikasi gabungan (FR-14, FR-15, FR-16).
///
/// - Android/iOS : pop-up lokal lewat flutter_local_notifications.
/// - Web / gagal : otomatis memakai SnackBar sebagai cadangan.
/// - Semua langkah dibungkus try-catch agar aplikasi tidak berhenti
///   walau notifikasi tidak tersedia (mis. saat dites di Chrome).
class NotificationService {
  // Singleton: satu instance dipakai bersama (main.dart & halaman lain)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  bool _localReady = false;
  int _nextId = 0;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'wisata_channel',
    'Wisata Nusantara',
    description: 'Notifikasi informasi wisata dan cuaca',
    importance: Importance.high,
  );

  /// Dipanggil sekali dari main() setelah Firebase.initializeApp.
  Future<void> initNotification(
    GlobalKey<ScaffoldMessengerState> messengerKey,
  ) async {
    _messengerKey = messengerKey;

    try {
      final messaging = FirebaseMessaging.instance;

      // Handler background hanya didukung di perangkat (bukan web)
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        await _initLocalNotifications();
      }

      // 1. Minta izin notifikasi (wajib untuk Android 13+ & iOS)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!granted) {
        debugPrint('Izin notifikasi tidak diberikan.');
        return;
      }

      // 2. Ambil FCM Token untuk tes kirim pesan dari Firebase Console
      if (!kIsWeb) {
        final token = await messaging.getToken();
        debugPrint('=== FCM TOKEN PERANGKAT INI ===');
        debugPrint(token);
        debugPrint('===============================');
      }

      // 3. Notifikasi saat aplikasi sedang dibuka (foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'Info Wisata Nusantara';
        final body = message.notification?.body ?? 'Ada pembaruan terbaru!';
        showNotification(title: title, body: body);
      });

      // 4. Notifikasi di-tap saat aplikasi di background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('Notifikasi dibuka: ${message.messageId}');
      });
    } catch (e) {
      debugPrint(
        'Gagal inisialisasi notifikasi (abaikan jika tes di Chrome): $e',
      );
    }
  }

  Future<void> _initLocalNotifications() async {
    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );

      await _local.initialize(settings: initializationSettings);

      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);

      _localReady = true;
    } catch (e) {
      _localReady = false;
      debugPrint('Notifikasi lokal tidak tersedia, memakai SnackBar: $e');
    }
  }

  /// Menampilkan notifikasi: pop-up sistem bila tersedia, jika tidak SnackBar.
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (_localReady) {
      try {
        const details = NotificationDetails(
          android: AndroidNotificationDetails(
            'wisata_channel',
            'Wisata Nusantara',
            channelDescription: 'Notifikasi informasi wisata dan cuaca',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        );

        await _local.show(
          id: _nextId++,
          title: title,
          body: body,
          notificationDetails: details,
        );
        return;
      } catch (e) {
        debugPrint('Gagal menampilkan notifikasi lokal: $e');
      }
    }

    _showSnackBar(title, body);
  }

  void _showSnackBar(String title, String body) {
    _messengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Uji notifikasi lokal.
  Future<void> showTestNotification() {
    return showNotification(
      title: 'Wisata Nusantara',
      body: 'Notifikasi berhasil ditampilkan!',
    );
  }

  /// FR-16: peringatan cuaca di lokasi wisata (mis. hujan / cuaca ekstrem).
  Future<void> showWeatherWarning(String condition, {String? lokasi}) {
    final tempat = lokasi ?? 'lokasi wisata';
    return showNotification(
      title: 'Peringatan Cuaca',
      body: 'Kondisi cuaca di $tempat: $condition',
    );
  }
}