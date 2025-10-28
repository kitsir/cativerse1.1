import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CatHealthPage extends StatelessWidget {
  final String catId;
  final int initialTab; // ✅ รับ initialTab จากหน้ารายละเอียด
  const CatHealthPage({
    super.key,
    required this.catId,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: initialTab.clamp(0, 4), // กัน index เพี้ยน
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ประวัติสุขภาพ'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'วัคซีน'),
              Tab(text: 'เจ็บป่วย'),
              Tab(text: 'ตรวจสุขภาพ'),
              Tab(text: 'การรักษา'),
              Tab(text: 'การคลอด'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _VaccinesTab(catId: catId),
            _IllnessTab(catId: catId),
            _CheckupTab(catId: catId),
            _TreatmentTab(catId: catId),
            _BirthTab(catId: catId),
          ],
        ),
      ),
    );
  }
}

/* ---------- โครง List + ปุ่มเพิ่ม ---------- */
class _ListWithAdd extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Widget Function(DocumentSnapshot<Map<String, dynamic>>) itemBuilder;
  final Future<void> Function() onAdd;
  const _ListWithAdd({
    required this.stream,
    required this.itemBuilder,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (c, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (s.hasError) return Center(child: Text('ผิดพลาด: ${s.error}'));
              final docs = s.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('ยังไม่มีรายการ'));
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (c, i) => itemBuilder(docs[i]),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มรายการ'),
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------- วัคซีน ---------- */
class _VaccinesTab extends StatelessWidget {
  final String catId;
  const _VaccinesTab({required this.catId});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('cats').doc(catId).collection('vaccineRecords');

    return _ListWithAdd(
      stream: col.orderBy('date', descending: true).snapshots(),
      itemBuilder: (d) {
        final x = d.data()!;
        final date = (x['date'] as Timestamp?)?.toDate().toString().split(' ').first ?? '';
        final type = (x['type'] ?? '').toString();
        final notes = (x['notes'] ?? '').toString();
        return ListTile(
          title: Text(type),
          subtitle: Text([date, if (notes.isNotEmpty) notes].join(' • ')),
          onLongPress: () => d.reference.delete(),
        );
      },
      onAdd: () async {
        // โหลดชนิดวัคซีนจาก Firestore lookups
        final typesSnap = await FirebaseFirestore.instance
            .collection('lookups').doc('vaccineTypes').collection('items').get();
        final types = typesSnap.docs
            .map((e) => (e.data()['name'] ?? e.id).toString())
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        String? type;
        String? notes;
        DateTime date = DateTime.now();

        await showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setSt) => AlertDialog(
              title: const Text('เพิ่มวัคซีน'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    items: types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => type = v,
                    decoration: const InputDecoration(labelText: 'ชนิดวัคซีน'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'หมายเหตุ'),
                    onChanged: (v) => notes = v,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Text('วันที่: ${date.toString().split(' ').first}')),
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
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('บันทึก')),
              ],
            ),
          ),
        );

        if (type != null) {
          await col.add({
            'date': Timestamp.fromDate(date),
            'type': type,
            'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
          });
        }
      },
    );
  }
}

/* ---------- เจ็บป่วย ---------- */
class _IllnessTab extends StatelessWidget {
  final String catId;
  const _IllnessTab({required this.catId});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('cats').doc(catId).collection('illnessRecords');

    return _ListWithAdd(
      stream: col.orderBy('date', descending: true).snapshots(),
      itemBuilder: (d) {
        final x = d.data()!;
        final date = (x['date'] as Timestamp?)?.toDate().toString().split(' ').first ?? '';
        final dx = (x['diagnosis'] ?? '').toString();
        final rx = (x['treatment'] ?? '').toString();
        final notes = (x['notes'] ?? '').toString();
        final parts = <String>[date, if (rx.isNotEmpty) 'Rx: $rx', if (notes.isNotEmpty) notes];
        return ListTile(
          title: Text(dx),
          subtitle: Text(parts.join(' • ')),
          onLongPress: () => d.reference.delete(),
        );
      },
      onAdd: () async {
        final dC = TextEditingController();
        final tC = TextEditingController();
        final nC = TextEditingController();
        DateTime date = DateTime.now();

        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setSt) => AlertDialog(
              title: const Text('เพิ่มประวัติเจ็บป่วย'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: dC, decoration: const InputDecoration(labelText: 'การวินิจฉัย')),
                  TextField(controller: tC, decoration: const InputDecoration(labelText: 'การรักษา')),
                  TextField(controller: nC, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Text('วันที่: ${date.toString().split(' ').first}')),
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
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('บันทึก')),
              ],
            ),
          ),
        );

        if (ok == true) {
          await col.add({
            'date': Timestamp.fromDate(date),
            'diagnosis': dC.text.trim(),
            'treatment': tC.text.trim().isEmpty ? null : tC.text.trim(),
            'notes': nC.text.trim().isEmpty ? null : nC.text.trim(),
          });
        }
      },
    );
  }
}

/* ---------- ตรวจสุขภาพ ---------- */
class _CheckupTab extends StatelessWidget {
  final String catId;
  const _CheckupTab({required this.catId});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('cats').doc(catId).collection('checkupRecords');

    return _ListWithAdd(
      stream: col.orderBy('date', descending: true).snapshots(),
      itemBuilder: (d) {
        final x = d.data()!;
        final date = (x['date'] as Timestamp?)?.toDate().toString().split(' ').first ?? '';
        final clinic = (x['clinic'] ?? '').toString();
        final weight = (x['weightKg'] as num?)?.toString();
        final notes = (x['notes'] ?? '').toString();
        final parts = <String>[
          if (clinic.isNotEmpty) clinic,
          if (weight != null) '$weight กก.',
          if (notes.isNotEmpty) notes
        ];
        return ListTile(
          title: Text(date),
          subtitle: Text(parts.join(' • ')),
          onLongPress: () => d.reference.delete(),
        );
      },
      onAdd: () async {
        final cC = TextEditingController();
        final wC = TextEditingController();
        final nC = TextEditingController();
        DateTime date = DateTime.now();

        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setSt) => AlertDialog(
              title: const Text('เพิ่มการตรวจสุขภาพ'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: cC, decoration: const InputDecoration(labelText: 'คลินิก/รพ.สัตว์')),
                  TextField(controller: wC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'น้ำหนัก (กก.)')),
                  TextField(controller: nC, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Text('วันที่: ${date.toString().split(' ').first}')),
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
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('บันทึก')),
              ],
            ),
          ),
        );

        if (ok == true) {
          await col.add({
            'date': Timestamp.fromDate(date),
            'clinic': cC.text.trim().isEmpty ? null : cC.text.trim(),
            'weightKg': double.tryParse(wC.text.trim()),
            'notes': nC.text.trim().isEmpty ? null : nC.text.trim(),
          });
        }
      },
    );
  }
}

/* ---------- การรักษา ---------- */
class _TreatmentTab extends StatelessWidget {
  final String catId;
  const _TreatmentTab({required this.catId});

  @override
  Widget build(BuildContext context) {
    // ✅ ใช้ชื่อคอลเลกชันให้ตรงกับหน้า detail
    final col = FirebaseFirestore.instance
        .collection('cats').doc(catId).collection('treatmentRecords');

    return _ListWithAdd(
      stream: col.orderBy('date', descending: true).snapshots(),
      itemBuilder: (d) {
        final x = d.data()!;
        final date = (x['date'] as Timestamp?)?.toDate().toString().split(' ').first ?? '';
        final name = (x['name'] ?? 'การรักษา').toString();
        final med  = (x['medicine'] ?? '').toString();
        final dose = (x['dose'] ?? '').toString();
        final clinic = (x['clinic'] ?? '').toString();
        final note = (x['note'] ?? x['notes'] ?? '').toString();
        final parts = <String>[
          date,
          if (clinic.isNotEmpty) clinic,
          if (med.isNotEmpty) 'ยา: $med',
          if (dose.isNotEmpty) 'ขนาดยา: $dose',
          if (note.isNotEmpty) note,
        ];
        return ListTile(
          title: Text(name),
          subtitle: Text(parts.join(' • ')),
          onLongPress: () => d.reference.delete(),
        );
      },
      onAdd: () async {
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
                      Expanded(child: Text('วันที่: ${date.toString().split(' ').first}')),
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
                ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('บันทึก')),
              ],
            ),
          ),
        );

        await col.add({
          'name': nameCtrl.text.trim(),
          'medicine': medCtrl.text.trim(),
          'dose': doseCtrl.text.trim(),
          'clinic': clinicCtrl.text.trim(),
          'note': noteCtrl.text.trim(),
          'date': Timestamp.fromDate(date),
        });
      },
    );
  }
}

/* ---------- การคลอด ---------- */
class _BirthTab extends StatelessWidget {
  final String catId;
  const _BirthTab({required this.catId});

  Future<bool> _isMale() async {
    final d = await FirebaseFirestore.instance.collection('cats').doc(catId).get();
    return (d.data()?['gender'] ?? '').toString().toLowerCase() == 'male';
  }

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('cats').doc(catId).collection('birthRecords');

    return _ListWithAdd(
      stream: col.orderBy('date', descending: true).snapshots(),
      itemBuilder: (d) {
        final x = d.data()!;
        final date = (x['date'] as Timestamp?)?.toDate().toString().split(' ').first ?? '';
        final kittens = (x['kittens'] ?? 0).toString();
        final healthyAll = (x['healthyAll'] ?? true) == true;
        final other = (x['other'] ?? false) == true;
        final notes = (x['notes'] ?? '').toString();
        final parts = <String>[
          'รวม $kittens ตัว',
          if (healthyAll) 'แข็งแรงครบ',
          if (other) 'อื่นๆ',
          if (notes.isNotEmpty) notes,
        ];
        return ListTile(
          title: Text('คลอด $date'),
          subtitle: Text(parts.join(' • ')),
          onLongPress: () => d.reference.delete(),
        );
      },
      onAdd: () async {
        if (await _isMale()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('แมวเพศผู้ไม่สามารถเพิ่มประวัติการคลอดได้')),
            );
          }
          return;
        }

        DateTime date = DateTime.now();
        final totalC = TextEditingController();
        final notesC = TextEditingController();
        bool healthyAll = true;
        bool other = false;
        String? err;

        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setSt) => AlertDialog(
              title: const Text('เพิ่มประวัติการคลอด'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: Text('วันที่: ${date.toString().split(' ').first}')),
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
                    controller: totalC,
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
                  TextField(controller: notesC, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
                  if (err != null) ...[
                    const SizedBox(height: 6),
                    Text(err!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                ElevatedButton(
                  onPressed: () {
                    final t = int.tryParse(totalC.text.trim()) ?? 0;
                    if (t <= 0) { setSt(() => err = 'กรอกจำนวนลูกทั้งหมดให้ถูกต้อง'); return; }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            ),
          ),
        );

        if (ok == true) {
          await col.add({
            'date': Timestamp.fromDate(date),
            'kittens': int.tryParse(totalC.text.trim()) ?? 0,
            'healthyAll': healthyAll,
            'other': other,
            'notes': notesC.text.trim().isEmpty ? null : notesC.text.trim(),
          });
        }
      },
    );
  }
}
