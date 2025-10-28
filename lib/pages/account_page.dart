// lib/pages/account_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';

import 'package:cativerse/pages/setting_page.dart';
import 'package:cativerse/pages/formscreen.dart';
import 'package:cativerse/pages/edit_profile_page.dart';
import 'package:cativerse/theme/colors.dart';

// โชว์สุขภาพ
import 'package:cativerse/pages/cat_health_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Future<void> _openHealthForUser(BuildContext context, String uid) async {
    final db = FirebaseFirestore.instance;
    QuerySnapshot<Map<String, dynamic>> q = await db
        .collection('cats')
        .where('ownerId', isEqualTo: uid)
        .get();

    if (q.docs.isEmpty) {
      q = await db.collection('cats').where('userId', isEqualTo: uid).get();
    }

    if (q.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีโปรไฟล์แมว — เพิ่มแมวก่อนนะ')),
      );
      return;
    }

    if (q.docs.length == 1) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CatHealthPage(catId: q.docs.first.id)),
      );
      return;
    }

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          itemCount: q.docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final d = q.docs[i];
            final data = d.data();
            final name = (data['name'] ?? '').toString();
            final breed = (data['breed'] ?? '').toString();
            final avatar = (data['imageUrl'] ?? data['avatar'] ?? '').toString();
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : const AssetImage('assets/images/cat_placeholder.png')
                        as ImageProvider,
              ),
              title: Text(name.isEmpty ? 'แมวของฉัน' : name),
              subtitle: breed.isEmpty ? null : Text(breed),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CatHealthPage(catId: d.id)),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: grey.withOpacity(0.2),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final uid = user.uid;
    final docStream =
        FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: docStream,
      builder: (context, snap) {
        String avatarUrl = user.photoURL ?? '';
        String username = '';
        String displayName = user.displayName ?? (user.email ?? 'User');

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          final img = (data['imageUrl'] as String?)?.trim() ?? '';
          final ava = (data['avatar'] as String?)?.trim() ?? '';
          avatarUrl = img.isNotEmpty ? img : (ava.isNotEmpty ? ava : avatarUrl);
          username = (data['username'] as String?)?.trim() ?? '';
          final fn = (data['firstName'] as String?)?.trim() ?? '';
          final ln = (data['lastName'] as String?)?.trim() ?? '';
          final full = ('$fn $ln').trim();
          if (full.isNotEmpty) displayName = full;
        }

        final size = MediaQuery.of(context).size;

        return Scaffold(
          backgroundColor: grey.withOpacity(0.2),
          body: ClipPath(
            clipper: OvalBottomBorderClipper(),
            child: Container(
              width: size.width,
              height: size.height * 0.6,
              decoration: BoxDecoration(
                color: white,
                boxShadow: [
                  BoxShadow(
                    color: grey.withOpacity(0.1),
                    spreadRadius: 10,
                    blurRadius: 10,
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 30, right: 30, bottom: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : const AssetImage('assets/images/default_avatar.png')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      username.isNotEmpty ? '@$username' : (user.email ?? ''),
                      style: TextStyle(fontSize: 14, color: grey.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 20),

                    // ===== แถวไอคอน 3 ปุ่ม =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // SETTINGS
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingPage(),
                                ),
                              ),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: grey.withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 10,
                                    )
                                  ],
                                ),
                                child: Icon(
                                  Icons.settings,
                                  size: 35,
                                  color: grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "SETTING",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: grey.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),

                        // ADD YOUR PETS
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>  AddCatForm(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primary_one, primary_two],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: grey.withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 10,
                                    )
                                  ],
                                ),
                                child: Icon(Icons.pets, size: 45, color: white),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "ADD YOUR PETS",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: grey.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),

                        // EDIT INFO
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfilePage(),
                                ),
                              ),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: grey.withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 10,
                                    )
                                  ],
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 35,
                                  color: grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "EDIT INFO",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: grey.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ⭐ ปุ่มไปหน้าข้อมูลสุขภาพ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => _openHealthForUser(context, uid),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: grey.withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 10,
                                    )
                                  ],
                                ),
                                child: Icon(
                                  Icons.health_and_safety_outlined,
                                  size: 35,
                                  color: grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "HEALTH",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: grey.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
