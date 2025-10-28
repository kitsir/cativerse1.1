// lib/pages/chat_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cativerse/pages/chat_detail_page.dart';
import 'package:cativerse/theme/colors.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final roomsStream = FirebaseFirestore.instance
        .collection('rooms')
        .where('userIds', arrayContains: currentUid)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: white,
      // ❌ ไม่มี AppBar/ไม่มีหัวซ้ำในตัวหน้า
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: roomsStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีข้อความ'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8), // ชิด AppBar ด้านบนพอดี
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final roomDoc = docs[i];
              final data = roomDoc.data();
              final userIds = List<String>.from(data['userIds'] ?? const <String>[]);
              final otherUid = userIds.firstWhere((u) => u != currentUid, orElse: () => currentUid);

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUid).get(),
                builder: (context, usnap) {
                  String name = 'Unknown';
                  String avatar = '';

                  if (usnap.hasData && usnap.data!.exists) {
                    final u = usnap.data!.data()!;
                    final fn = (u['firstName'] as String?)?.trim() ?? '';
                    final ln = (u['lastName'] as String?)?.trim() ?? '';
                    final imageUrl = (u['imageUrl'] as String?)?.trim() ?? '';
                    final ava = (u['avatar'] as String?)?.trim() ?? '';
                    final candidate = ('$fn $ln').trim();
                    if (candidate.isNotEmpty) name = candidate;
                    avatar = imageUrl.isNotEmpty ? imageUrl : ava;
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: _LastMessage(roomId: roomDoc.id),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailPage(roomId: roomDoc.id, otherUid: otherUid),
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

class _LastMessage extends StatelessWidget {
  final String roomId;
  const _LastMessage({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text('เริ่มแชทกันเลย', style: TextStyle(color: Colors.grey));
        }
        final m = snap.data!.docs.first.data();
        final text = (m['text'] as String?) ?? '';
        return Text(
          text.isNotEmpty ? text : 'รูป/สติ๊กเกอร์',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(color: Colors.grey),
        );
      },
    );
  }
}
