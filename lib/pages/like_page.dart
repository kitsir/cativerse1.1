// lib/pages/like_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  late final String _me;
  final _db = FirebaseFirestore.instance;
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _me = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _accept(String likerUid) async {
    if (_processing.contains(likerUid)) return;
    setState(() => _processing.add(likerUid));
    try {
      // ✅ ใช้วงเล็บปีกกาใน interpolation ให้ชัดเจน
      final backId = '${_me}__${likerUid}';
      await _db.collection('matches').doc(backId).set({
        'userId': _me,
        'likedUserId': likerUid,
        'matched': false,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ตอบรับแล้ว • ระบบจะสร้างห้องให้เมื่อแมตช์กัน')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ตอบรับไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing.remove(likerUid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db
        .collection('matches')
        .where('likedUserId', isEqualTo: _me)
        .where('matched', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('คนที่ถูกใจคุณ')),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีคนถูกใจคุณ'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final m = docs[i].data() as Map<String, dynamic>;
              final likerUid = (m['userId'] as String?) ?? '';

              return FutureBuilder<DocumentSnapshot>(
                future: _db.collection('users').doc(likerUid).get(),
                builder: (context, s) {
                  String name = likerUid;
                  String photo = '';
                  if (s.hasData && s.data!.exists) {
                    final data = s.data!.data() as Map<String, dynamic>;
                    final fn = (data['firstName'] as String?)?.trim() ?? '';
                    final ln = (data['lastName'] as String?)?.trim() ?? '';
                    final imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
                    final avatar = (data['avatar'] as String?)?.trim() ?? '';
                    final candidate = ('$fn $ln').trim();
                    if (candidate.isNotEmpty) name = candidate;
                    photo = imageUrl.isNotEmpty ? imageUrl : avatar;
                  }

                  final busy = _processing.contains(likerUid);

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: const Text('ถูกใจคุณ'),
                      trailing: TextButton.icon(
                        icon: busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.favorite),
                        label: Text(busy ? 'กำลังตอบรับ...' : 'ตอบรับ'),
                        onPressed: busy ? null : () => _accept(likerUid),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
