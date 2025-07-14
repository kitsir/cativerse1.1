// register_page.dart (พร้อมอัปโหลดรูปโปรไฟล์)
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

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _avatar = File(picked.path);
      });
    }
  }

  Future<String> _uploadAvatar(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('avatars/$fileName.jpg');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String avatarUrl = '';
      if (_avatar != null) {
        avatarUrl = await _uploadAvatar(_avatar!);
      }
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'avatar': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('สมัครสมาชิกล้มเหลว: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _minimalInput(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      );

  @override
  Widget build(BuildContext context) {
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
                    backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                    child: _avatar == null ? Icon(Icons.camera_alt, size: 32, color: Colors.grey[600]) : null,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _minimalInput('ชื่อ'),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _minimalInput('นามสกุล'),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกนามสกุล' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: _minimalInput('เบอร์โทร'),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกเบอร์โทร' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: _minimalInput('ยูสเซอร์เนม'),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกยูสเซอร์เนม' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: _minimalInput('อีเมล'),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกอีเมล' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: _minimalInput('รหัสผ่าน'),
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร' : null,
                ),
                SizedBox(height: 24),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('สมัครสมาชิก', style: TextStyle(color: Colors.white)),
                      ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('กลับไปหน้าเข้าสู่ระบบ', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
