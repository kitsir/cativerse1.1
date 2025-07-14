import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cativerse/pages/root_app.dart';

class AddCatForm extends StatefulWidget {
  @override
  _AddCatFormState createState() => _AddCatFormState();
}

class _AddCatFormState extends State<AddCatForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _breedController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<File> _images = [];
  bool _isLoading = false;
  String _gender = 'male'; // Default value, 'male' or 'female'

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked != null && picked.length <= 4) {
      List<File> tempImages = [];
      for (var img in picked) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: img.path,
          aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 80,
          uiSettings: [
            AndroidUiSettings(toolbarTitle: 'ปรับแต่งรูปแมว'),
            IOSUiSettings(title: 'ปรับแต่งรูปแมว'),
          ],
        );
        if (cropped != null) tempImages.add(File(cropped.path));
      }
      setState(() => _images = tempImages);
    } else if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เลือกรูปได้ไม่เกิน 4 รูป')),
      );
    }
  }

  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> urls = [];
    for (var image in images) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('cat_images/$fileName.jpg');
      final task = await ref.putFile(image);
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _images.isEmpty) {
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('กรุณาเลือกรูปแมวก่อน')),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final imageUrls = await _uploadImages(_images);
      await FirebaseFirestore.instance.collection('cats').add({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'breed': _breedController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrls': imageUrls,
        'gender': _gender, // เก็บข้อมูลเพศ
        'ownerId': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่มข้อมูลแมวเรียบร้อยแล้ว!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => RootApp()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputStyle(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('เพิ่มข้อมูลแมว', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _images.isEmpty
                      ? Center(child: Icon(Icons.add_photo_alternate, size: 50))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _images[i],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: _inputStyle('ชื่อแมว'),
                validator: (v) => v!.isEmpty ? 'กรุณาใส่ชื่อแมว' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: _inputStyle('อายุแมว (ปี)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'กรุณาใส่อายุแมว' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _breedController,
                decoration: _inputStyle('สายพันธุ์'),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputStyle('ลักษณะ / พฤติกรรม'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              // เพิ่ม Radio Button สำหรับเพศ
              Row(
                children: [
                  Text("เพศแมว:", style: TextStyle(fontSize: 16)),
                  Radio<String>(
                    value: 'male',
                    groupValue: _gender,
                    onChanged: (String? value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  Text("ชาย"),
                  Radio<String>(
                    value: 'female',
                    groupValue: _gender,
                    onChanged: (String? value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  Text("หญิง"),
                ],
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: Icon(Icons.save),
                      label: Text('บันทึก'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
