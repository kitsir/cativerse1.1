import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cat_models.dart';
import 'cat_health_page.dart';

class CatDetailPage extends StatelessWidget {
  final String catId;
  const CatDetailPage({super.key, required this.catId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดแมว')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('cats').doc(catId).get(),
        builder: (c, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cat = Cat.fromDoc(snap.data!);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (cat.imageUrls.isNotEmpty)
                SizedBox(
                  height: 300,
                  child: PageView(
                    children: cat.imageUrls
                        .map((u) => Image.network(u, fit: BoxFit.cover))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 16),
              Text(cat.name, style: Theme.of(context).textTheme.headlineMedium),
              Text('${cat.breed} • ${ageLabel(cat.birthdate)}'),
              const SizedBox(height: 12),
              Text(cat.description),
              const Divider(height: 32),

              // สรุปสุขภาพ
              _HealthSummary(catId: cat.id),

              if (cat.ownerId == uid) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CatHealthPage(catId: cat.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('จัดการสุขภาพ'),
                )
              ]
            ],
          );
        },
      ),
    );
  }
}

class _HealthSummary extends StatelessWidget {
  final String catId;
  const _HealthSummary({required this.catId});

  Future<int> _count(String sub) async {
    final snap = await FirebaseFirestore.instance
        .collection('cats').doc(catId).collection(sub).get();
    return snap.docs.length;
  }

  Future<DateTime?> _latestCheckup() async {
    final snap = await FirebaseFirestore.instance
        .collection('cats').doc(catId).collection('checkupRecords')
        .orderBy('date', descending: true).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return (snap.docs.first['date'] as Timestamp).toDate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('สรุปสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        FutureBuilder<int>(
          future: _count('vaccineRecords'),
          builder: (c, s) => Text('วัคซีนที่ฉีดแล้ว: ${s.data ?? 0} ครั้ง'),
        ),
        FutureBuilder<DateTime?>(
          future: _latestCheckup(),
          builder: (c, s) =>
              Text('ตรวจสุขภาพล่าสุด: ${s.data?.toString().split(" ").first ?? "ยังไม่เคย"}'),
        ),
        FutureBuilder<int>(
          future: _count('birthRecords'),
          builder: (c, s) => Text('การคลอด: ${s.data ?? 0} ครั้ง'),
        ),
      ],
    );
  }
}
