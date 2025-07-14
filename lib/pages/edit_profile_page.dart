// edit_profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cativerse/theme/colors.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  String _currentAvatarUrl = '';
  File? _newAvatar;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _firstNameController.text = data['firstName'] ?? '';
      _lastNameController.text = data['lastName'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _usernameController.text = data['username'] ?? '';
      setState(() {
        _currentAvatarUrl = data['avatar'] ?? '';
      });
    }
  }

  Future<void> _pickNewAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() {
        _newAvatar = File(picked.path);
      });
    }
  }

  Future<String> _uploadAvatar(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('avatars/$fileName.jpg');
    final snapshot = await ref.putFile(file);
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    String avatarUrl = _currentAvatarUrl;
    if (_newAvatar != null) {
      avatarUrl = await _uploadAvatar(_newAvatar!);
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'username': _usernameController.text.trim(),
      'avatar': avatarUrl,
    });

    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickNewAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _newAvatar != null
                            ? FileImage(_newAvatar!) as ImageProvider
                            : (_currentAvatarUrl.isNotEmpty
                                ? NetworkImage(_currentAvatarUrl)
                                : AssetImage('assets/images/default_avatar.png') as ImageProvider),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _firstNameController,
                    decoration: _inputDecoration('ชื่อ'),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    decoration: _inputDecoration('นามสกุล'),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: _inputDecoration('เบอร์โทร'),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: _inputDecoration('ยูสเซอร์เนม'),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('บันทึก', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }
}
