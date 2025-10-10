import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/seed_lookups.dart';

// ⬇️ เปลี่ยนชื่อคลาสเป็น SettingsPage ให้ตรงกับ account_page.dart
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('บัญชีผู้ใช้', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user.email ?? 'ผู้ใช้ไม่ทราบอีเมล'),
              subtitle: const Text('อีเมลที่ใช้เข้าสู่ระบบ'),
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('แก้ไขโปรไฟล์'),
            onTap: () => Navigator.pushNamed(context, '/profile/edit'),
          ),
          const Divider(height: 24),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('เครื่องมือผู้ดูแล (Dev/Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Seed Lookup Data'),
            subtitle: const Text('สร้างรายการสายพันธุ์/วัคซีนใน Firestore (กดครั้งเดียวพอ)'),
            onTap: () async {
              try {
                await seedLookups();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seed ข้อมูลเรียบร้อย')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Seed ไม่สำเร็จ: $e')),
                  );
                }
              }
            },
          ),
          const Divider(height: 24),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('อื่น ๆ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ออกจากระบบ'),
            onTap: () => _signOut(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
