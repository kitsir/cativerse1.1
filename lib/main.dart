import 'package:cativerse/pages/root_app.dart';
import 'package:cativerse/pages/login_page.dart';
import 'package:cativerse/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
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
      initialRoute: '/', // ตั้งค่า route เริ่มต้น
      routes: {
        '/': (context) => AuthWrapper(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => RootApp(),
      },
    );
  }
}

// 🔐 ตรวจสอบสถานะผู้ใช้ว่า login อยู่ไหม
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ถ้า login แล้วให้ไปหน้า Home
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          return user != null ? RootApp() : LoginPage();
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
