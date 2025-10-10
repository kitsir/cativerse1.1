import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ⬇️ ใช้โครงที่คุณจัดไว้ (ทุกหน้าอยู่ใต้ pages)
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
      routes: {
        '/login': (_) => LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/root': (_) => const RootApp(),
        '/cats/add': (_) => AddCatForm(),
        '/profile/edit': (_) => EditProfilePage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.active) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.data != null ? const RootApp() : LoginPage();
        },
      ),
    );
  }
}
