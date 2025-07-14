// account_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:cativerse/pages/setting_page.dart';
import 'package:cativerse/pages/formscreen.dart';
import 'package:cativerse/pages/edit_profile_page.dart';
import 'package:cativerse/theme/colors.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String avatarUrl = '';
  String username = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          avatarUrl = data['avatar'] ?? '';
          username = data['username'] ?? '';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: grey.withOpacity(0.2),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ClipPath(
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
                                : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        username.isNotEmpty ? '@$username' : 'User',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SettingsPage()),
                                  );
                                },
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
                              SizedBox(height: 10),
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
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AddCatForm()),
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
                                  child: Icon(
                                    Icons.pets,
                                    size: 45,
                                    color: white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
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
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => EditProfilePage()),
                                  );
                                  _loadUserProfile();
                                },
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
                              SizedBox(height: 10),
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
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
