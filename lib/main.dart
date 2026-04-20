// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io'; // Required for Platform check
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

// --- Background Notification Handler ---
// This must be a top-level function (outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Hook up the background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Request Permission for Notifications
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('User granted notification permission');

    // 4. Safe Topic Subscription
    // Wrapped in a try-catch to prevent "APNS token not set" crash on iOS Simulators
    try {
      if (Platform.isIOS) {
        // Give iOS a brief moment to receive the APNS token from Apple
        String? token = await FirebaseMessaging.instance.getAPNSToken();
        if (token != null) {
          await FirebaseMessaging.instance.subscribeToTopic('alerts');
          debugPrint('Subscribed to alerts topic');
        } else {
          debugPrint('APNS token not ready yet, subscription deferred');
        }
      } else {
        // Android handles this automatically
        await FirebaseMessaging.instance.subscribeToTopic('alerts');
        debugPrint('Subscribed to alerts topic');
      }
    } catch (e) {
      debugPrint('Topic subscription failed: $e');
      // This catch prevents the app from dying on Simulators
    }
  }

  runApp(const ColdChainApp());
}

class ColdChainApp extends StatelessWidget {
  const ColdChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cold Chain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Starts with the animated splash screen we created
      home: const SplashScreen(),
    );
  }
}