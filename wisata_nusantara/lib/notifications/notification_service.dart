
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  // Firebase harus sudah diinisialisasi oleh entry point
  // sebelum handler background ini digunakan.
}

class NotificationService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'wisata_channel',
    'Wisata Nusantara',
    description: 'Notifikasi informasi wisata dan cuaca',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Inisialisasi notifikasi lokal
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    // Membuat notification channel Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);

    // Meminta izin notifikasi
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Mengambil FCM Token
    final token = await _messaging.getToken();
    print('FCM TOKEN: $token');

    // Menangani pesan ketika aplikasi sedang terbuka
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      if (notification != null) {
        showNotification(
          title: notification.title ?? 'Wisata Nusantara',
          body: notification.body ?? 'Ada informasi baru.',
        );
      }
    });

    // Menangani klik notifikasi ketika aplikasi berada
    // di background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Notifikasi dibuka: ${message.messageId}');
    });

    // Menangani notifikasi yang membuka aplikasi
    // dari kondisi terminated
    final initialMessage =
        await _messaging.getInitialMessage();

    if (initialMessage != null) {
      print('Aplikasi dibuka dari notifikasi.');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'wisata_channel',
      'Wisata Nusantara',
      channelDescription:
          'Notifikasi informasi wisata dan cuaca',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // Fungsi untuk menguji notifikasi lokal
  Future<void> showTestNotification() async {
    await showNotification(
      title: 'Wisata Nusantara',
      body: 'Notifikasi berhasil ditampilkan!',
    );
  }

  // Contoh simulasi peringatan cuaca
  Future<void> showWeatherWarning(String condition) async {
    await showNotification(
      title: 'Peringatan Cuaca',
      body: 'Kondisi cuaca di lokasi wisata: $condition',
    );
  }
}
