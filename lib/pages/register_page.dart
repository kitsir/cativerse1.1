// lib/pages/register_page.dart (พร้อมอัปโหลดรูปโปรไฟล์ และ sync imageUrl)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _avatar;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _avatar = File(picked.path);
      });
    }
  }

  Future<String> _uploadAvatar(File file, String uid) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance
        .ref()
        .child('avatars/$uid/$fileName.jpg');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  InputDecoration _minimalInput(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      );

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'จำเป็นต้องกรอก' : null;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1) สร้างผู้ใช้
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = cred.user!.uid;

      // 2) อัปโหลดรูป (ถ้ามี)
      String avatarUrl = '';
      if (_avatar != null) {
        avatarUrl = await _uploadAvatar(_avatar!, uid);
      }

      // 3) เขียนโปรไฟล์ลง Firestore (เก็บทั้ง avatar และ imageUrl ให้ตรงกัน)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'avatar': avatarUrl,
        'imageUrl': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4) อัปเดตโปรไฟล์ใน FirebaseAuth (optional)
      try {
        final displayName =
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                .trim();
        if (displayName.isNotEmpty) {
          await cred.user!.updateDisplayName(displayName);
        }
        if (avatarUrl.isNotEmpty) {
          await cred.user!.updatePhotoURL(avatarUrl);
        }
      } catch (_) {
        // non-fatal
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'สมัครสมาชิกล้มเหลว')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สมัครสมาชิกล้มเหลว: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        _avatar != null ? FileImage(_avatar!) : null,
                    child: _avatar == null
                        ? Icon(Icons.camera_alt,
                            size: 32, color: Colors.grey[600])
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _minimalInput('ชื่อ'),
                  validator: _req,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _minimalInput('นามสกุล'),
                  validator: _req,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: _minimalInput('เบอร์โทร'),
                  validator: _req,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: _minimalInput('ยูสเซอร์เนม'),
                  validator: _req,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: _minimalInput('อีเมล'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'กรุณากรอกอีเมล';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'รูปแบบอีเมลไม่ถูกต้อง';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: _minimalInput('รหัสผ่าน'),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร' : null,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: canSubmit ? _register : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('สมัครสมาชิก',
                            style: TextStyle(color: Colors.white)),
                      ),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('กลับไปหน้าเข้าสู่ระบบ',
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
