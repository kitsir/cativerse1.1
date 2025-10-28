import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/root_app.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/formscreen.dart';
import 'pages/edit_profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cativerse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFD5C61)),
        useMaterial3: true,
      ),
      // ✅ ลงทะเบียนเส้นทางให้ครบ และทำ alias /home → RootApp
      routes: {
        '/login': (_) => LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/root': (_) => const RootApp(),
        '/home': (_) => const RootApp(), // ⬅️ เผื่อที่ไหนยังเรียก /home อยู่
        '/cats/add': (_) => AddCatForm(),
        '/profile/edit': (_) => EditProfilePage(),
      },
      // ✅ กันพิมพ์ route ผิด
      onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const RootApp()),
      // ✅ เปิดตามสถานะ auth
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.active) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snap.data != null ? const RootApp() : LoginPage();
        },
      ),
    );
  }
}
