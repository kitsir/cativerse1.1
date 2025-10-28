// lib/pages/formscreen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// ตัวเลือกสายพันธุ์ (ย้ายออกมาไว้ top-level ห้ามประกาศ class ซ้อนใน State)
class _BreedOption {
  final String id;      // เช่น "beng"
  final String nameEn;  // เช่น "Bengal"
  final String nameTh;  // เช่น "เบงกอล"
  const _BreedOption(this.id, this.nameEn, this.nameTh);

  String get label => nameTh.isNotEmpty ? '$nameEn ($nameTh)' : nameEn;
}

class AddCatForm extends StatefulWidget {
  const AddCatForm({super.key});

  @override
  State<AddCatForm> createState() => _AddCatFormState();
}

class _AddCatFormState extends State<AddCatForm> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _desc = TextEditingController();

  /// เก็บ “ชื่ออังกฤษ” ของสายพันธุ์
  String? _breed;
  String _gender = 'female'; // male | female
  DateTime? _birthday;

  // ===== images (multi) =====
  final _picker = ImagePicker();
  final List<XFile> _picked = [];
  final List<Uint8List> _thumbs = []; // พรีวิวเร็ว

  bool _saving = false;

  // ===== health draft =====
  final List<Map<String, dynamic>> _vaccines = [];
  final List<Map<String, dynamic>> _illness = [];
  final List<Map<String, dynamic>> _checkups = [];
  final List<Map<String, dynamic>> _treatments = [];
  final List<Map<String, dynamic>> _births = []; // เพศผู้จะไม่บันทึก

  // ===== cache futures =====
  late Future<List<_BreedOption>> _breedsFuture;
  late Future<List<String>> _vaccineTypesFuture;

  @override
  void initState() {
    super.initState();
    _breedsFuture = _loadBreeds();
    _vaccineTypesFuture = _loadVaccineTypes();
  }

  // ===== Firestore helpers =====
  Future<List<_BreedOption>> _loadBreeds() async {
    final qs = await FirebaseFirestore.instance
        .collection('lookups')
        .doc('catBreeds')
        .collection('items')
        .orderBy(FieldPath.documentId)
        .get();

    // doc: { id, name_en, name_th }
    return qs.docs.map((d) {
      final m = d.data();
      final en = (m['name_en'] ?? '').toString().trim();
      final th = (m['name_th'] ?? '').toString().trim();
      final id = (m['id'] ?? d.id).toString().trim();
      return _BreedOption(id, en.isNotEmpty ? en : id, th);
    }).toList();
  }

  Future<List<String>> _loadVaccineTypes() async {
    final qs = await FirebaseFirestore.instance
        .collection('lookups')
        .doc('vaccineTypes')
        .collection('items')
        .orderBy(FieldPath.documentId)
        .get();

    // แสดง: CODE — desc (ถ้าไม่มี desc ใช้ name / CODE)
    return qs.docs.map((d) {
      final m = d.data();
      final code = (m['code'] ?? d.id).toString().trim();
      final desc = (m['desc'] ?? m['name'] ?? '').toString().trim();
      return desc.isNotEmpty ? '$code — $desc' : code;
    }).toList();
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // ===== image picker =====
  Future<void> _pickMultiImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    for (final f in files) {
      final bytes = await f.readAsBytes();
      _picked.add(f);
      _thumbs.add(bytes);
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (d != null) setState(() => _birthday = d);
  }

  // ========== add health inline ==========
  Future<void> _addVaccine() async {
    final types = await _vaccineTypesFuture;
    if (types.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีชนิดวัคซีนใน lookups/vaccineTypes/items')),
      );
      return;
    }

    String? type; // “FPV — ลำไส้อักเสบติดต่อ (Panleukopenia)”
    DateTime date = DateTime.now();
    final notes = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('เพิ่มวัคซีน'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'ชนิดวัคซีน'),
                  items: types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => type = v,
                ),
                TextField(controller: notes, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text('วันที่: ${_fmt(date)}')),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );
                      if (p != null) setSt(() => date = p);
                    },
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('เพิ่ม')),
          ],
        ),
      ),
    );

    if (type != null) {
      setState(() {
        _vaccines.add({
          'date': Timestamp.fromDate(date),
          'type': type, // เก็บ string ที่เลือกไว้เลย
          'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
        });
      });
    }
  }

  Future<void> _addIllness() async {
    final dC = TextEditingController();
    final tC = TextEditingController();
    final nC = TextEditingController();
    DateTime date = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('เพิ่มประวัติเจ็บป่วย'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: dC, decoration: const InputDecoration(labelText: 'การวินิจฉัย')),
                TextField(controller: tC, decoration: const InputDecoration(labelText: 'การรักษา')),
                TextField(controller: nC, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text('วันที่: ${_fmt(date)}')),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );
                      if (p != null) setSt(() => date = p);
                    },
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('เพิ่ม')),
          ],
        ),
      ),
    );

    if (ok == true) {
      setState(() {
        _illness.add({
          'date': Timestamp.fromDate(date),
          'diagnosis': dC.text.trim(),
          'treatment': tC.text.trim().isEmpty ? null : tC.text.trim(),
          'notes': nC.text.trim().isEmpty ? null : nC.text.trim(),
        });
      });
    }
  }

  Future<void> _addCheckup() async {
    final cC = TextEditingController();
    final wC = TextEditingController();
    final nC = TextEditingController();
    DateTime date = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('เพิ่มการตรวจสุขภาพ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: cC, decoration: const InputDecoration(labelText: 'คลินิก/รพ.สัตว์')),
                TextField(
                  controller: wC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'น้ำหนัก (กก.)'),
                ),
                TextField(controller: nC, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text('วันที่: ${_fmt(date)}')),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );
                      if (p != null) setSt(() => date = p);
                    },
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('เพิ่ม')),
          ],
        ),
      ),
    );

    if (ok == true) {
      setState(() {
        _checkups.add({
          'date': Timestamp.fromDate(date),
          'clinic': cC.text.trim().isEmpty ? null : cC.text.trim(),
          'weightKg': double.tryParse(wC.text.trim()),
          'notes': nC.text.trim().isEmpty ? null : nC.text.trim(),
        });
      });
    }
  }

  Future<void> _addTreatment() async {
    final nameCtrl = TextEditingController();
    final medCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final clinicCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime date = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('เพิ่มการรักษา'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ชื่อการรักษา')),
                TextField(controller: medCtrl, decoration: const InputDecoration(labelText: 'ยา/เวชภัณฑ์')),
                TextField(controller: doseCtrl, decoration: const InputDecoration(labelText: 'ขนาดยา/ความถี่')),
                TextField(controller: clinicCtrl, decoration: const InputDecoration(labelText: 'คลินิก/โรงพยาบาลสัตว์')),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'บันทึกเพิ่มเติม')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text('วันที่: ${_fmt(date)}')),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );
                      if (p != null) setSt(() => date = p);
                    },
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('เพิ่ม')),
          ],
        ),
      ),
    );

    setState(() {
      _treatments.add({
        'name': nameCtrl.text.trim(),
        'medicine': medCtrl.text.trim(),
        'dose': doseCtrl.text.trim(),
        'clinic': clinicCtrl.text.trim(),
        'note': noteCtrl.text.trim(),
        'date': Timestamp.fromDate(date),
      });
    });
  }

  Future<void> _addBirth() async {
    if (_gender == 'male') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แมวเพศผู้ไม่สามารถมีประวัติการคลอดได้')),
      );
      return;
    }

    final total = TextEditingController();
    final notes = TextEditingController();
    DateTime date = DateTime.now();
    bool healthyAll = true;
    bool other = false;
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('เพิ่มประวัติการคลอด'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: Text('วันที่: ${_fmt(date)}')),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );
                      if (p != null) setSt(() => date = p);
                    },
                  ),
                ]),
                TextField(
                  controller: total,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'จำนวนลูกทั้งหมด (ตัว)'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: healthyAll,
                  onChanged: (v) => setSt(() => healthyAll = v ?? true),
                  title: const Text('แข็งแรงดีทุกตัว'),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: other,
                  onChanged: (v) => setSt(() => other = v ?? false),
                  title: const Text('อื่นๆ (ระบุในหมายเหตุ)'),
                  contentPadding: EdgeInsets.zero,
                ),
                TextField(controller: notes, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
                if (error != null) ...[
                  const SizedBox(height: 6),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () {
                final t = int.tryParse(total.text.trim()) ?? 0;
                if (t <= 0) {
                  setSt(() => error = 'กรอกจำนวนลูกทั้งหมดให้ถูกต้อง');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      setState(() {
        _births.add({
          'date': Timestamp.fromDate(date),
          'kittens': int.tryParse(total.text.trim()) ?? 0,
          'healthyAll': healthyAll,
          'other': other,
          'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
        });
      });
    }
  }

  // ========== save ==========
  Future<void> _save() async {
    if (_saving) return;

    if (_picked.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเลือกรูปภาพแมวก่อนบันทึก')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_gender == 'male' && _births.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพศผู้ไม่สามารถบันทึกประวัติการคลอดได้')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // อัปโหลดรูปทั้งหมด
      final storage = FirebaseStorage.instance;
      final List<String> imageUrls = [];
      for (int i = 0; i < _picked.length; i++) {
        final f = _picked[i];
        final ref = storage.ref('cats/$uid/${DateTime.now().millisecondsSinceEpoch}-$i-${f.name}');
        await ref.putFile(File(f.path));
        imageUrls.add(await ref.getDownloadURL());
      }

      // create cat
      final catRef = await FirebaseFirestore.instance.collection('cats').add({
        'ownerId': uid,
        'name': _name.text.trim(),
        'breed': _breed ?? '', // เก็บเป็นชื่ออังกฤษ
        'gender': _gender,
        'birthday': _birthday != null ? Timestamp.fromDate(_birthday!) : null,
        'description': _desc.text.trim(),
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // write health subcollections
      final batch = FirebaseFirestore.instance.batch();
      void addAll(String col, List<Map<String, dynamic>> list) {
        for (final m in list) {
          batch.set(catRef.collection(col).doc(), m);
        }
      }

      addAll('vaccineRecords', _vaccines);
      addAll('illnessRecords', _illness);
      addAll('checkupRecords', _checkups);
      addAll('treatmentRecords', _treatments);
      if (_gender != 'male') addAll('birthRecords', _births);

      await batch.commit();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกล้มเหลว: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มโปรไฟล์แมว')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==== รูปภาพ — ปุ่มเดียวบนสุด เลือกได้หลายรูป ====
            InkWell(
              onTap: _pickMultiImages,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library, size: 36),
                      SizedBox(height: 6),
                      Text('เลือก/เพิ่มรูปภาพ (หลายรูปได้)'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_thumbs.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < _thumbs.length; i++)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _thumbs[i],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _thumbs.removeAt(i);
                                _picked.removeAt(i);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            const Divider(height: 24),

            // ชื่อ
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'ชื่อแมว'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรอกชื่อแมว' : null,
            ),
            const SizedBox(height: 12),

            // สายพันธุ์: แสดง “อังกฤษ (ไทย)”
            FutureBuilder<List<_BreedOption>>(
              future: _breedsFuture,
              builder: (c, s) {
                if (s.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(minHeight: 2);
                }
                if (s.hasError) {
                  return Text('โหลดสายพันธุ์ผิดพลาด: ${s.error}',
                      style: const TextStyle(color: Colors.red));
                }
                final breeds = s.data ?? const <_BreedOption>[];
                return DropdownButtonFormField<String>(
                  value: _breed,
                  decoration: const InputDecoration(labelText: 'สายพันธุ์'),
                  items: breeds
                      .map((b) => DropdownMenuItem(
                            value: b.nameEn, // บันทึกชื่ออังกฤษ
                            child: Text(b.label), // แสดง อังกฤษ (ไทย)
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _breed = v),
                  validator: (v) => v == null || v.isEmpty ? 'เลือกสายพันธุ์' : null,
                );
              },
            ),
            const SizedBox(height: 12),

            // เพศ
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'เพศ'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('เพศผู้')),
                DropdownMenuItem(value: 'female', child: Text('เพศเมีย')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'female'),
            ),
            const SizedBox(height: 12),

            // วันเกิด
            InkWell(
              onTap: _pickBirthday,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'วันเกิด แตะเพื่อเลือก'),
                child: Text(_birthday != null ? _fmt(_birthday!) : ''),
              ),
            ),
            const SizedBox(height: 12),

            // คำอธิบาย
            TextFormField(
              controller: _desc,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'คำอธิบาย'),
            ),
            const Divider(height: 32),

            // ===== บันทึกสุขภาพ =====
            Text('บันทึกสุขภาพ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            _HealthCard(
              title: 'วัคซีน',
              emptyText: 'ยังไม่มีข้อมูล',
              items: _vaccines
                  .map((e) =>
                      '${DateFormat('yyyy-MM-dd').format((e['date'] as Timestamp).toDate())} • ${e['type']}${e['notes'] != null ? ' • ${e['notes']}' : ''}')
                  .toList(),
              onAdd: _addVaccine,
            ),
            const SizedBox(height: 12),

            _HealthCard(
              title: 'เจ็บป่วย',
              emptyText: 'ยังไม่มีข้อมูล',
              items: _illness
                  .map((e) =>
                      '${DateFormat('yyyy-MM-dd').format((e['date'] as Timestamp).toDate())} • ${e['diagnosis']}${e['treatment'] != null ? ' • Rx: ${e['treatment']}' : ''}${e['notes'] != null ? ' • ${e['notes']}' : ''}')
                  .toList(),
              onAdd: _addIllness,
            ),
            const SizedBox(height: 12),

            _HealthCard(
              title: 'ตรวจสุขภาพ',
              emptyText: 'ยังไม่มีข้อมูล',
              items: _checkups
                  .map((e) =>
                      '${DateFormat('yyyy-MM-dd').format((e['date'] as Timestamp).toDate())}${e['clinic'] != null ? ' • ${e['clinic']}' : ''}${e['weightKg'] != null ? ' • ${e['weightKg']} กก.' : ''}${e['notes'] != null ? ' • ${e['notes']}' : ''}')
                  .toList(),
              onAdd: _addCheckup,
            ),
            const SizedBox(height: 12),

            _HealthCard(
              title: 'การรักษา',
              emptyText: 'ยังไม่มีข้อมูล',
              items: _treatments.map((e) {
                final dt = DateFormat('yyyy-MM-dd').format((e['date'] as Timestamp).toDate());
                final parts = <String>[
                  dt,
                  if ((e['clinic'] ?? '').toString().isNotEmpty) e['clinic'],
                  if ((e['medicine'] ?? '').toString().isNotEmpty) 'ยา: ${e['medicine']}',
                  if ((e['dose'] ?? '').toString().isNotEmpty) 'ขนาดยา: ${e['dose']}',
                  if ((e['note'] ?? '').toString().isNotEmpty) e['note'],
                ];
                final name = (e['name'] ?? 'การรักษา').toString();
                return '$name • ${parts.join(' • ')}';
              }).toList(),
              onAdd: _addTreatment,
            ),
            const SizedBox(height: 12),

            _HealthCard(
              title: 'การคลอด',
              emptyText: 'ยังไม่มีข้อมูล',
              items: _births
                  .map((e) =>
                      '${DateFormat('yyyy-MM-dd').format((e['date'] as Timestamp).toDate())} • รวม ${e['kittens']} ตัว${(e['healthyAll'] ?? true) ? ' • แข็งแรงครบ' : ''}${(e['other'] ?? false) ? ' • อื่นๆ' : ''}${e['notes'] != null ? ' • ${e['notes']}' : ''}')
                  .toList(),
              onAdd: _gender == 'male' ? null : _addBirth,
              disabledHint: 'เฉพาะเพศเมีย',
            ),
            const SizedBox(height: 24),

            SafeArea(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('บันทึกข้อมูล'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<String> items;
  final Future<void> Function()? onAdd;
  final String? disabledHint;

  const _HealthCard({
    required this.title,
    required this.emptyText,
    required this.items,
    this.onAdd,
    this.disabledHint,
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = onAdd != null;
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: canAdd ? onAdd : null,
                  icon: const Icon(Icons.add),
                  tooltip: canAdd ? 'เพิ่ม' : (disabledHint ?? ''),
                )
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(emptyText, style: TextStyle(color: Colors.grey[700])),
              ),
            for (final t in items) ...[
              const Divider(height: 8),
              Text(t),
            ],
          ],
        ),
      ),
    );
  }
}
