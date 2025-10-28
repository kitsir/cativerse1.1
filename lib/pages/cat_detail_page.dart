// lib/pages/cat_detail_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cat_models.dart';
import 'cat_health_page.dart';

class CatDetailPage extends StatefulWidget {
  final String catId;
  const CatDetailPage({super.key, required this.catId});

  @override
  State<CatDetailPage> createState() => _CatDetailPageState();
}

class _CatDetailPageState extends State<CatDetailPage> {
  int _currentImage = 0;
  final _pageCtrl = PageController();

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // ✅ เพิ่มพารามิเตอร์ canManage เพื่อควบคุมว่าโชว์ปุ่มไปหน้าจัดการหรือไม่
  Future<void> _openDetailsSheet({
    required String title,
    required String subcollection, // vaccineRecords / illnessRecords / checkupRecords / treatmentRecords / birthRecords
    required bool canManage,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(title),
            ),
            body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('cats/${widget.catId}/$subcollection')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (_, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = s.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('ยังไม่มีรายการ'));
                }
                return ListView.separated(
                  controller: controller,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = docs[i].data();
                    final t = (m['date'] as Timestamp?)?.toDate();
                    switch (subcollection) {
                      case 'vaccineRecords':
                        return ListTile(
                          title: Text(m['type']?.toString() ?? '-'),
                          subtitle: Text(
                            '${t != null ? _fmtDate(t) : '-'}'
                            '${(m['notes'] ?? '').toString().isNotEmpty ? ' • ${m['notes']}' : ''}',
                          ),
                        );
                      case 'illnessRecords':
                        return ListTile(
                          title: Text(m['diagnosis']?.toString() ?? '-'),
                          subtitle: Text(
                            '${t != null ? _fmtDate(t) : '-'}'
                            '${(m['treatment'] ?? '').toString().isNotEmpty ? ' • Rx: ${m['treatment']}' : ''}'
                            '${(m['notes'] ?? '').toString().isNotEmpty ? ' • ${m['notes']}' : ''}',
                          ),
                        );
                      case 'checkupRecords':
                        return ListTile(
                          title: Text(
                            '${t != null ? _fmtDate(t) : '-'}'
                            '${(m['clinic'] ?? '').toString().isNotEmpty ? ' • ${m['clinic']}' : ''}',
                          ),
                          subtitle: Text(
                            '${m['weightKg'] != null ? 'น้ำหนัก ${m['weightKg']} กก.' : ''}'
                            '${(m['notes'] ?? '').toString().isNotEmpty ? ' • ${m['notes']}' : ''}',
                          ),
                        );
                      case 'treatmentRecords':
                        final parts = <String>[
                          if (t != null) _fmtDate(t),
                          if ((m['clinic'] ?? '').toString().isNotEmpty) m['clinic'],
                          if ((m['medicine'] ?? '').toString().isNotEmpty) 'ยา: ${m['medicine']}',
                          if ((m['dose'] ?? '').toString().isNotEmpty) 'ขนาดยา: ${m['dose']}',
                          if ((m['note'] ?? m['notes'] ?? '').toString().isNotEmpty)
                            (m['note'] ?? m['notes']).toString(),
                        ];
                        return ListTile(
                          title: Text((m['name'] ?? 'การรักษา').toString()),
                          subtitle: Text(parts.join(' • ')),
                        );
                      default: // birthRecords
                        final parts = <String>[
                          if (t != null) _fmtDate(t),
                          'รวม ${(m['kittens'] ?? 0)} ตัว',
                          (m['healthyAll'] ?? true) ? 'แข็งแรงครบ' : 'มีตัวอ่อนแอ',
                          if ((m['other'] ?? false) == true) 'อื่นๆ',
                          if ((m['notes'] ?? '').toString().isNotEmpty) m['notes'],
                        ];
                        return ListTile(title: const Text('การคลอด'), subtitle: Text(parts.join(' • ')));
                    }
                  },
                );
              },
            ),
            // ❌ เดิมมีปุ่ม "ไปหน้าจัดการทั้งหมด" ที่นี่
            // ✅ เปลี่ยนเป็นแสดงเฉพาะเมื่อ canManage = true (คือเป็นเจ้าของเท่านั้น)
            bottomNavigationBar: canManage
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CatHealthPage(catId: widget.catId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('ไปหน้าจัดการทั้งหมด'),
                      ),
                    ),
                  )
                : null, // ← ไม่ใช่เจ้าของ: ไม่แสดงปุ่ม
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดแมว')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('cats').doc(widget.catId).get(),
        builder: (c, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('ไม่พบข้อมูลแมว'));
          }

          final cat = Cat.fromDoc(snap.data!);
          final images = cat.imageUrls;
          final hasImages = images.isNotEmpty;
          final isOwner = cat.ownerId == uid;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ===== รูปภาพ: PageView + Dots + hint =====
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: hasImages
                          ? PageView.builder(
                              controller: _pageCtrl,
                              itemCount: images.length,
                              onPageChanged: (i) => setState(() => _currentImage = i),
                              itemBuilder: (_, i) => Image.network(
                                images[i],
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, prog) =>
                                    prog == null ? child : const Center(child: CircularProgressIndicator()),
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Icon(Icons.image_not_supported)),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.pets, size: 64, color: Colors.grey)),
                            ),
                    ),
                    if (hasImages && images.length > 1)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentImage == i ? 16 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(_currentImage == i ? 0.95 : 0.55),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (hasImages && images.length > 1)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.swipe, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text('เลื่อนดูรูป', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ชื่อ/สายพันธุ์/อายุ
              Text(cat.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('${cat.breed} • ${ageLabel(cat.birthdate)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),

              // คำอธิบาย
              if (cat.description.isNotEmpty)
                Text(cat.description, style: Theme.of(context).textTheme.bodyLarge),
              if (cat.description.isEmpty)
                Text('— ไม่มีคำอธิบาย —',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const Divider(height: 32),

              // ===== สรุปสุขภาพ (แตะเพื่อดูรายละเอียด) =====
              const Text('สรุปสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _SummaryItem(
                title: 'วัคซีน',
                subtitleStream: FirebaseFirestore.instance
                    .collection('cats/${cat.id}/vaccineRecords')
                    .orderBy('date', descending: true)
                    .limit(1)
                    .snapshots()
                    .map((s) => s.docs.isEmpty
                        ? 'ยังไม่เคย'
                        : 'ล่าสุด: ${_fmtDate((s.docs.first['date'] as Timestamp).toDate())}'),
                countStream: FirebaseFirestore.instance
                    .collection('cats/${cat.id}/vaccineRecords')
                    .snapshots()
                    .map((s) => s.docs.length),
                onTap: () => _openDetailsSheet(
                  title: 'วัคซีน',
                  subcollection: 'vaccineRecords',
                  canManage: isOwner, // ✅ ส่งสิทธิ์เข้าไป
                ),
              ),
              _SummaryItem(
                title: 'เจ็บป่วย',
                subtitleStream: FirebaseFirestore.instance
                    .collection('cats/${cat.id}/illnessRecords')
                    .orderBy('date', descending: true)
                    .limit(1)
                    .snapshots()
                    .map((s) => s.docs.isEmpty
                        ? 'ยังไม่เคย'
                        : 'ล่าสุด: ${_fmtDate((s.docs.first['date'] as Timestamp).toDate())}'),
                countStream: FirebaseFirestore.instance
                    .collection('cats/${cat.id}/illnessRecords')
                    .snapshots()
                    .map((s) => s.docs.length),
                onTap: () => _openDetailsSheet(
                  title: 'ประวัติเจ็บป่วย',
                  subcollection: 'illnessRecords',
                  canManage: isOwner,
                ),
              ),
              _SummaryItem(
                title: 'ตรวจสุขภาพ',
                subtitleStream: FirebaseFirestore.instance
                    .collection('cats/${cat.id}/checkupRecords')
                    .orderBy('date', descending: true)
                    .limit(1)
                    .snapshots()
                    .map((s) => s.docs.isEmpty
                        ? 'ยังไม่เคย'
                        : 'ล่าสุด: ${_fmtDate((s.docs.first['date'] as Timestamp).toDate())}'),
                countStream: FirebaseFirestore.instance
                    .collection('cats/${cat.id}/checkupRecords')
                    .snapshots()
                    .map((s) => s.docs.length),
                onTap: () => _openDetailsSheet(
                  title: 'ตรวจสุขภาพ',
                  subcollection: 'checkupRecords',
                  canManage: isOwner,
                ),
              ),
              _SummaryItem(
                title: 'การรักษา',
                subtitleStream: FirebaseFirestore.instance
                    .collection('cats/${cat.id}/treatmentRecords')
                    .orderBy('date', descending: true)
                    .limit(1)
                    .snapshots()
                    .map((s) => s.docs.isEmpty
                        ? 'ยังไม่เคย'
                        : 'ล่าสุด: ${_fmtDate((s.docs.first['date'] as Timestamp).toDate())}'),
                countStream: FirebaseFirestore.instance
                    .collection('cats/${cat.id}/treatmentRecords')
                    .snapshots()
                    .map((s) => s.docs.length),
                onTap: () => _openDetailsSheet(
                  title: 'การรักษา',
                  subcollection: 'treatmentRecords',
                  canManage: isOwner,
                ),
              ),
              _SummaryItem(
                title: 'การคลอด',
                subtitleStream: FirebaseFirestore.instance
                    .collection('cats/${cat.id}/birthRecords')
                    .orderBy('date', descending: true)
                    .limit(1)
                    .snapshots()
                    .map((s) => s.docs.isEmpty
                        ? 'ยังไม่เคย'
                        : 'ล่าสุด: ${_fmtDate((s.docs.first['date'] as Timestamp).toDate())}'),
                countStream: FirebaseFirestore.instance
                    .collection('cats/${cat.id}/birthRecords')
                    .snapshots()
                    .map((s) => s.docs.length),
                onTap: () => _openDetailsSheet(
                  title: 'การคลอด',
                  subcollection: 'birthRecords',
                  canManage: isOwner,
                ),
              ),

              // ✅ ปุ่มจัดการสุขภาพ — โชว์เฉพาะเจ้าของเท่านั้น (ของเดิมก็ถูกแล้ว)
              if (isOwner) ...[
                const SizedBox(height: 20),
                
                FilledButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CatHealthPage(catId: cat.id)),
    );
  },
  icon: const Icon(Icons.health_and_safety),
  label: const Text('จัดการสุขภาพ'),
),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final Stream<String> subtitleStream;
  final Stream<int> countStream;
  final VoidCallback onTap;

  const _SummaryItem({
    required this.title,
    required this.subtitleStream,
    required this.countStream,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: StreamBuilder<String>(
          stream: subtitleStream,
          builder: (_, s) => Text(s.data ?? 'กำลังโหลด...'),
        ),
        trailing: StreamBuilder<int>(
          stream: countStream,
          builder: (_, s) => Chip(
            label: Text('${s.data ?? 0}'),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
        ),
      ),
    );
  }
}
