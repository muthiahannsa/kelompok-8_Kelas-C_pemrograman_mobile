import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth/auth_provider.dart';
import 'auth/auth_wrapper.dart';
import 'auth/notification_service.dart';
import 'wisata/wisata_provider.dart';
<<<<<<< HEAD
import 'wisata/rating_provider.dart';
import 'cuaca/weather_service.dart';
=======
import 'theme/app_theme.dart';
import 'cuaca/weather_service.dart';
import 'wisata/rating_provider.dart';
>>>>>>> b801540 (Memastikan struktur data Firestore tetap cocok dengan data lama)

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().initNotification(rootScaffoldMessengerKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WisataProvider()),
        ChangeNotifierProvider(create: (_) => WeatherService()),
        ChangeNotifierProvider(create: (_) => RatingProvider()),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        title: 'Wisata Nusantara',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthWrapper(),
      ),
    );
  }
}