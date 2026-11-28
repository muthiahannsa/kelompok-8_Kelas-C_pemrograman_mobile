import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../wisata/wisata_model.dart';
import '../wisata/wisata_widgets.dart';

/// Handler notifikasi saat aplikasi di background / ditutup (FCM).
/// Harus top-level. Notifikasi dengan payload "notification" ditampilkan
/// otomatis oleh sistem Android/iOS, jadi tidak perlu kode tambahan di sini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Notifikasi background diterima: ${message.messageId}');
}

/// Model item riwayat notifikasi untuk panel in-app.
class AppNotification {
  final String title;
  final String body;
  final String type; // 'fcm', 'cuaca', 'test'
  final DateTime timestamp;
  final String? wisataId;
  final bool isRead;

  const AppNotification({
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.wisataId,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      title: title,
      body: body,
      type: type,
      timestamp: timestamp,
      wisataId: wisataId,
      isRead: isRead ?? this.isRead,
    );
  }
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

  static const String _defaultTopic = 'wisata_updates';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Riwayat notifikasi selama sesi aplikasi berjalan.
  final ValueNotifier<List<AppNotification>> historyNotifier =
      ValueNotifier<List<AppNotification>>([]);

  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _localReady = false;
  String? _fcmToken;
  int _nextId = 0;

  String? get fcmToken => _fcmToken;

  int get unreadCount =>
      historyNotifier.value.where((item) => !item.isRead).length;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'wisata_channel',
    'Wisata Nusantara',
    description: 'Notifikasi informasi wisata dan cuaca',
    importance: Importance.high,
  );

  /// Dipanggil sekali dari main() setelah Firebase.initializeApp.
  Future<void> initNotification(
    GlobalKey<ScaffoldMessengerState> messengerKey, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    _messengerKey = messengerKey;
    _navigatorKey = navigatorKey;

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

      // 2. Ambil FCM Token, pantau refresh, dan subscribe topic (khusus mobile)
      if (!kIsWeb) {
        // Tetap memakai getToken/onTokenRefresh agar kompatibel dengan tes token Firebase Console.
        // ignore: deprecated_member_use
        _fcmToken = await messaging.getToken();
        debugPrint('=== FCM TOKEN PERANGKAT INI ===');
        debugPrint(_fcmToken);
        debugPrint('===============================');

        // ignore: deprecated_member_use
        messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('FCM Token diperbarui: $newToken');
        });

        try {
          await messaging.subscribeToTopic(_defaultTopic);
        } catch (e) {
          debugPrint('Gagal subscribe topic $_defaultTopic: $e');
        }
      }

      // 3. Notifikasi saat aplikasi sedang dibuka (foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'Info Wisata Nusantara';
        final body = message.notification?.body ?? 'Ada pembaruan terbaru!';
        final wisataId = _extractWisataId(message.data);
        showNotification(
          title: title,
          body: body,
          type: 'fcm',
          wisataId: wisataId,
        );
      });

      // 4. Notifikasi di-tap saat aplikasi di background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleOpenedRemoteMessage(message);
      });
    } catch (e) {
      debugPrint(
        'Gagal inisialisasi notifikasi (abaikan jika tes di Chrome): $e',
      );
    }
  }

  /// Cek notifikasi yang membuka aplikasi dari kondisi mati total (terminated).
  Future<void> checkInitialMessage() async {
    if (kIsWeb) return;
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        await _handleOpenedRemoteMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('Gagal membaca initial message FCM: $e');
    }
  }

  Future<void> _handleOpenedRemoteMessage(RemoteMessage message) async {
    final wisataId = _extractWisataId(message.data);
    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title != null || body != null) {
      _recordNotification(
        title: title ?? 'Info Wisata Nusantara',
        body: body ?? 'Ada pembaruan terbaru!',
        type: 'fcm',
        wisataId: wisataId,
        isRead: true,
      );
    }
    await openWisataById(wisataId);
  }

  String? _extractWisataId(Map<String, dynamic> data) {
    final raw = data['wisataId']?.toString().trim();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  Future<void> _initLocalNotifications() async {
    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );

      await _local.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          openWisataById(response.payload);
        },
      );

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
    String type = 'fcm',
    String? wisataId,
  }) async {
    _recordNotification(
      title: title,
      body: body,
      type: type,
      wisataId: wisataId,
    );

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
          payload: wisataId,
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

  void _recordNotification({
    required String title,
    required String body,
    required String type,
    String? wisataId,
    bool isRead = false,
  }) {
    final item = AppNotification(
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      wisataId: wisataId,
      isRead: isRead,
    );
    historyNotifier.value = [item, ...historyNotifier.value];
  }

  /// Menandai semua riwayat notifikasi sudah dibaca.
  void markAllAsRead() {
    final current = historyNotifier.value;
    if (current.every((item) => item.isRead)) return;
    historyNotifier.value =
        current.map((item) => item.copyWith(isRead: true)).toList();
  }

  /// Membuka detail wisata (WeatherScreen) bila notifikasi membawa wisataId.
  Future<void> openWisataById(String? wisataId) async {
    final id = wisataId?.trim();
    if (id == null || id.isEmpty) return;

    final context = _navigatorKey?.currentContext;
    if (context == null || !context.mounted) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('wisata').doc(id).get();
      final data = doc.data();
      if (!doc.exists || data == null || !context.mounted) return;

      final wisata = Wisata.fromFirestore(doc.id, data);
      openWisataDetail(context, wisata);
    } catch (e) {
      debugPrint('Gagal membuka wisata dari notifikasi ($id): $e');
    }
  }

  /// Uji notifikasi lokal.
  Future<void> showTestNotification() {
    return showNotification(
      title: 'Wisata Nusantara',
      body: 'Notifikasi berhasil ditampilkan!',
      type: 'test',
    );
  }

  /// FR-16: peringatan cuaca di lokasi wisata (mis. hujan / cuaca ekstrem).
  Future<void> showWeatherWarning(
    String condition, {
    String? lokasi,
    String? wisataId,
  }) {
    final tempat = lokasi ?? 'lokasi wisata';
    return showNotification(
      title: 'Peringatan Cuaca',
      body: 'Kondisi cuaca di $tempat: $condition',
      type: 'cuaca',
      wisataId: wisataId,
    );
  }
}
