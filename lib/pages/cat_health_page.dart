import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/cat_models.dart';
import '../data/breed_and_vaccines.dart';

class CatHealthPage extends StatelessWidget {
  final String catId;
  const CatHealthPage({super.key, required this.catId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ประวัติสุขภาพ'),
          bottom: const TabBar(tabs: [
            Tab(text: 'วัคซีน'),
            Tab(text: 'เจ็บป่วย'),
            Tab(text: 'ตรวจสุขภาพ'),
            Tab(text: 'การคลอด'),
          ]),
        ),
        body: TabBarView(
          children: [
            _VaccinesTab(catId: catId),
            _IllnessTab(catId: catId),
            _CheckupTab(catId: catId),
            _BirthTab(catId: catId),
          ],
        ),
      ),
    );
  }
}

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
              if (!s.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = s.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('ยังไม่มีรายการ'));
              }
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

/* ------------------------- วัคซีน ------------------------- */

class _VaccinesTab extends StatelessWidget {
  final String catId;
  const _VaccinesTab({required this.catId});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('cats')
        .doc(catId)
        .collection('vaccineRecords');

    final stream = col.orderBy('date', descending: true).snapshots();

    return _ListWithAdd(
      stream: stream,
      itemBuilder: (d) {
        final rec = VaccineRecord.fromDoc(d);
        final date = rec.date.toString().split(' ').first;
        return ListTile(
          title: Text(rec.type),
          subtitle: Text('$date${rec.notes != null ? ' • ${rec.notes}' : ''}'),
        );
      },
      onAdd: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date == null) return;

        String? type;
        String? notes;

        await showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('เพิ่มวัคซีน'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    items: kVaccineOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => type = v,
                    decoration: const InputDecoration(labelText: 'ชนิดวัคซีน'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'หมายเหตุ'),
                    onChanged: (v) => notes = v,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );

        if (type != null) {
          await col.add({
            'date': Timestamp.fromDate(date),
            'type': type,
            'notes': notes,
          });
        }
      },
    );
  }
}

/* ------------------------- เจ็บป่วย ------------------------- */

class _IllnessTab extends StatelessWidget {
  final String catId;
  const _IllnessTab({required this.catId});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('cats')
        .doc(catId)
        .collection('illnessRecords');

    final stream = col.orderBy('date', descending: true).snapshots();

    return _ListWithAdd(
      stream: stream,
      itemBuilder: (d) {
        final rec = IllnessRecord.fromDoc(d);
        final date = rec.date.toString().split(' ').first;
        final rx =
            rec.treatment != null && rec.treatment!.isNotEmpty ? ' • Rx: ${rec.treatment}' : '';
        final notes =
            rec.notes != null && rec.notes!.isNotEmpty ? ' • ${rec.notes}' : '';
        return ListTile(
          title: Text(rec.diagnosis),
          subtitle: Text('$date$rx$notes'),
        );
      },
      onAdd: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date == null) return;

        final dC = TextEditingController();
        final tC = TextEditingController();
        final nC = TextEditingController();

        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('เพิ่มประวัติเจ็บป่วย'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: dC, decoration: const InputDecoration(labelText: 'การวินิจฉัย')),
                  TextField(controller: tC, decoration: const InputDecoration(labelText: 'การรักษา')),
                  TextField(controller: nC, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('บันทึก')),
              ],
            );
          },
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

/* ------------------------- ตรวจสุขภาพ ------------------------- */

class _CheckupTab extends StatelessWidget {
  final String catId;
  const _CheckupTab({required this.catId});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('cats')
        .doc(catId)
        .collection('checkupRecords');

    final stream = col.orderBy('date', descending: true).snapshots();

    return _ListWithAdd(
      stream: stream,
      itemBuilder: (d) {
        final rec = CheckupRecord.fromDoc(d);
        final date = rec.date.toString().split(' ').first;
        final clinic = rec.clinic != null && rec.clinic!.isNotEmpty ? ' • ${rec.clinic}' : '';
        final weight = rec.weightKg != null ? ' • ${rec.weightKg} กก.' : '';
        final notes = rec.notes != null && rec.notes!.isNotEmpty ? ' • ${rec.notes}' : '';
        return ListTile(
          title: Text('$date$clinic'),
          subtitle: Text('$weight$notes'.trim()),
        );
      },
      onAdd: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date == null) return;

        final cC = TextEditingController();
        final wC = TextEditingController();
        final nC = TextEditingController();

        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('เพิ่มการตรวจสุขภาพ'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: cC, decoration: const InputDecoration(labelText: 'คลินิก/รพ.สัตว์')),
                  TextField(controller: wC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'น้ำหนัก (กก.)')),
                  TextField(controller: nC, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('บันทึก')),
              ],
            );
          },
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

/* ------------------------- การคลอด ------------------------- */

class _BirthTab extends StatelessWidget {
  final String catId;
  const _BirthTab({required this.catId});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('cats')
        .doc(catId)
        .collection('birthRecords');

    final stream = col.orderBy('date', descending: true).snapshots();

    return _ListWithAdd(
      stream: stream,
      itemBuilder: (d) {
        final rec = BirthRecord.fromDoc(d);
        final date = rec.date.toString().split(' ').first;
        return ListTile(
          title: Text('$date • ${rec.kittens} ตัว'),
          subtitle: Text(rec.notes ?? ''),
        );
      },
      onAdd: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date == null) return;

        final kC = TextEditingController();
        final nC = TextEditingController();

        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('เพิ่มประวัติการคลอด'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: kC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวนลูก')),
                  TextField(controller: nC, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('บันทึก')),
              ],
            );
          },
        );

        if (ok == true) {
          await col.add({
            'date': Timestamp.fromDate(date),
            'kittens': int.tryParse(kC.text.trim()) ?? 0,
            'notes': nC.text.trim().isEmpty ? null : nC.text.trim(),
          });
        }
      },
    );
  }
}
