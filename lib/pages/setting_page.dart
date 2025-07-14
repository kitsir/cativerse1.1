import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // เปลี่ยน path ให้ถูกต้อง

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildTile(
            icon: Icons.person,
            title: "Account",
            subtitle: "Manage your account",
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.notifications,
            title: "Notifications",
            subtitle: "Notification preferences",
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.lock,
            title: "Privacy",
            subtitle: "Privacy and security",
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.color_lens,
            title: "Appearance",
            subtitle: "Light / Dark mode",
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.info,
            title: "About",
            subtitle: "App version, developers",
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.logout,
            title: "Logout",
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Confirm Logout"),
                  content: Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      child: Text("Cancel"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: Text("Logout"),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm ?? false) {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
          _buildTile(
            icon: Icons.dangerous,
            title: "Delete Account",
            onTap: () async {
              final TextEditingController passwordController = TextEditingController();

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Delete Account"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("This will permanently delete your account."),
                      SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Confirm your password",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text("Cancel"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: Text("Delete", style: TextStyle(color: Colors.red)),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm ?? false) {
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  String email = user?.email ?? "";

                  // re-authenticate
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: email,
                    password: passwordController.text,
                  );

                  await user?.reauthenticateWithCredential(credential);
                  await user?.delete();

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.message}")),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12)) : null,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}