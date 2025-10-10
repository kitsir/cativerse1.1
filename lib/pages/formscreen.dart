import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import '../models/cat_models.dart';
import '../data/breed_and_vaccines.dart';
import 'cat_health_page.dart'; // มีไฟล์นี้อยู่แล้วในโฟลเดอร์ pages

class AddCatForm extends StatefulWidget {
  AddCatForm({super.key});
  @override
  State<AddCatForm> createState() => _AddCatFormState();
}

class _AddCatFormState extends State<AddCatForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _descC = TextEditingController();
  String? _breed;
  String _gender = 'male';
  DateTime? _birthdate;
  bool _isLoading = false;
  final List<File> _localImages = [];
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedVaccines = [];

  Future<void> _pickImage() async {
    final picks = await _picker.pickMultiImage(imageQuality: 85);
    if (picks.isNotEmpty) {
      setState(() => _localImages.addAll(picks.map((e) => File(e.path))));
    }
  }

  Future<List<String>> _uploadImages(String catId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final urls = <String>[];
    for (var i = 0; i < _localImages.length; i++) {
      final file = _localImages[i];
      final ref = FirebaseStorage.instance
          .ref('cat_images/$uid/$catId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      await ref.putFile(file);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _save() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_localImages.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเลือกรูปอย่างน้อย 1 รูป')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('cats').add({
        'ownerId': uid,
        'name': _nameC.text.trim(),
        'breed': _breed,
        'gender': _gender,
        'birthdate': _birthdate != null ? Timestamp.fromDate(_birthdate!) : null,
        'description': _descC.text.trim(),
        'imageUrls': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      final imgUrls = await _uploadImages(doc.id);
      await doc.update({'imageUrls': imgUrls});

      // seed vaccine subcollection from multi-select
      for (final v in _selectedVaccines) {
        await doc.collection('vaccineRecords').add({
          'date': FieldValue.serverTimestamp(),
          'type': v,
          'notes': 'เลือกตอนสร้าง',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกสำเร็จ')));
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CatHealthPage(catId: doc.id),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มโปรไฟล์แมว')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameC,
              decoration: const InputDecoration(labelText: 'ชื่อแมว'),
              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _breed,
              items: kCatBreeds.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _breed = v),
              decoration: const InputDecoration(labelText: 'สายพันธุ์'),
              validator: (v) => v == null ? 'กรุณาเลือกสายพันธุ์' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('เพศผู้')),
                DropdownMenuItem(value: 'female', child: Text('เพศเมีย')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'male'),
              decoration: const InputDecoration(labelText: 'เพศ'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(now.year - 1),
                  firstDate: DateTime(now.year - 30),
                  lastDate: now,
                );
                if (picked != null) setState(() => _birthdate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'วันเกิด'),
                child: Text(_birthdate != null
                    ? _birthdate!.toString().split(' ').first
                    : 'แตะเพื่อเลือก'),
              ),
            ),
            const SizedBox(height: 12),
            MultiSelectDialogField<String>(
              items: kVaccineOptions.map((e) => MultiSelectItem(e, e)).toList(),
              title: const Text('วัคซีนพื้นฐาน'),
              buttonText: const Text('เลือกวัคซีนที่ได้รับ'),
              initialValue: _selectedVaccines,
              onConfirm: (vals) => _selectedVaccines = vals,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descC,
              decoration: const InputDecoration(labelText: 'คำอธิบาย'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _localImages)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.file(f, width: 100, height: 100, fit: BoxFit.cover),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _localImages.remove(f)),
                      ),
                    ],
                  ),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('เลือกรูป'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_isLoading ? 'กำลังบันทึก...' : 'บันทึก'),
            ),
          ],
        ),
      ),
    );
  }
}
