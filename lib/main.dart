import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // ضروري جداً لتعريف kIsWeb
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/providers/user_provider.dart';
import 'data/services/notification_service.dart';
import 'views/splash/splash_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/auth/login_screen.dart';

/// Must be a top-level function (runs in its own isolate).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // التأكد من تهيئة Firebase في الخلفية
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // تهيئة Firebase مع استخدام try-catch لتجنب أي خطأ في تعريف المنصة
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // حل بديل في حال فشل الكشف التلقائي عن المنصة
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    }
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // تهيئة خدمة الإشعارات
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const SmartInstituteApp(),
    ),
  );
}

class SmartInstituteApp extends StatelessWidget {
  const SmartInstituteApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Smart Institute App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: SplashScreen.routeName,
        routes: {
          SplashScreen.routeName: (_) => const SplashScreen(),
          OnboardingScreen.routeName: (_) => const OnboardingScreen(),
          LoginScreen.routeName: (_) => const LoginScreen(),
        },
      );
}
