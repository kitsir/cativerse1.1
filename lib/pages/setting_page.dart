// lib/pages/setting_page.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/breed_and_vaccines.dart'; // ตัวช่วยอ่าน/อัปโหลด lookups

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // ===== Upload state =====
  bool _loadingUpload = false;
  String? _pickedPath;
  String? _uploadStatus;

  // ===== Current lookups stats =====
  int _breedCount = 0;
  int _vaccineCount = 0;
  bool _loadingStats = true;

  // ===== Auth =====
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadLookupStats();
  }

  Future<void> _loadLookupStats() async {
    setState(() => _loadingStats = true);
    try {
      final db = FirebaseFirestore.instance;

      // ใช้ .get() + .size เพื่อให้รองรับได้กว้าง ไม่ติด aggregate API
      final breedsSnap = await db
          .collection('lookups')
          .doc('catBreeds')
          .collection('items')
          .get();

      final vaccinesSnap = await db
          .collection('lookups')
          .doc('vaccineTypes')
          .collection('items')
          .get();

      setState(() {
        _breedCount = breedsSnap.size;
        _vaccineCount = vaccinesSnap.size;
      });
    } catch (_) {
      setState(() {
        _breedCount = 0;
        _vaccineCount = 0;
      });
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _pickJson() async {
    setState(() {
      _uploadStatus = null;
      _pickedPath = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _pickedPath = result.files.single.path!);
    }
  }

  Future<void> _upload() async {
    if (_pickedPath == null) {
      setState(() => _uploadStatus = 'ยังไม่ได้เลือกไฟล์ .json');
      return;
    }
    setState(() {
      _loadingUpload = true;
      _uploadStatus = null;
    });
    try {
      final file = File(_pickedPath!);
      final bundle = await BreedVaccineBundle.fromFile(file);
      await LookupUploader.uploadBundle(bundle);

      setState(() => _uploadStatus =
          'อัปโหลดสำเร็จ: สายพันธุ์ ${bundle.breeds.length} รายการ, วัคซีน ${bundle.vaccines.length} รายการ');

      await _loadLookupStats();
    } catch (e) {
      setState(() => _uploadStatus = 'เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _loadingUpload = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('ยืนยันออกจากระบบหรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ออกจากระบบ')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ออกจากระบบแล้ว')),
        );
        Navigator.of(context).pop(); // กลับหน้าก่อนหน้า
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ออกจากระบบล้มเหลว: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = _pickedPath != null && !_loadingUpload;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings · อัปโหลดข้อมูล Lookups')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== User card + Logout =====
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.account_circle_outlined, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_auth.currentUser?.displayName ?? 'ผู้ใช้',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(_auth.currentUser?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('ออกจากระบบ'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ===== Lookups stats =====
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.storage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _loadingStats
                        ? const Text('กำลังตรวจสอบข้อมูล lookups ...')
                        : Text('Breeds: $_breedCount • Vaccines: $_vaccineCount'),
                  ),
                  IconButton(
                    tooltip: 'รีเฟรช',
                    onPressed: _loadLookupStats,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ===== File picker =====
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('เลือกไฟล์ JSON (breeds + vaccines)'),
            subtitle: Text(_pickedPath ?? 'ยังไม่ได้เลือกไฟล์'),
            trailing: OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('เลือกไฟล์'),
              onPressed: _loadingUpload ? null : _pickJson,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'รูปแบบ JSON ที่รองรับ: ดูตัวอย่างในไฟล์ helper — breed_and_vaccines.dart',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),

          // ===== Upload button =====
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _loadingUpload
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: Text(_loadingUpload ? 'กำลังอัปโหลด...' : 'อัปโหลดขึ้น Firestore'),
              onPressed: canUpload ? _upload : null,
            ),
          ),

          if (_uploadStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_uploadStatus!),
            ),
          ],

          const SizedBox(height: 24),
          Text(
            'คอลเลกชันที่ใช้: lookups/catBreeds/items และ lookups/vaccineTypes/items',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
