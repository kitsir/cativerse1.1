// chat_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:cativerse/pages/chat_detail_page.dart';
import 'package:cativerse/theme/colors.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(color: primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<types.Room>>(
        stream: FirebaseChatCore.instance.rooms(),
        builder: (c, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final rooms = snap.data ?? [];
          if (rooms.isEmpty) return const Center(child: Text('No messages yet.'));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: rooms.length,
            itemBuilder: (c, i) {
              final room = rooms[i];
              final other = room.users.firstWhere((u) => u.id != currentUid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(other.id)
                    .get(),
                builder: (c2, usnap) {
                  String name = other.firstName ?? 'Unknown';
                  String avatar = other.imageUrl ?? '';

                  if (usnap.hasData && usnap.data!.exists) {
                    final data = usnap.data!.data() as Map<String, dynamic>;
                    name = '${data['firstName']} ${data['lastName']}';
                    avatar = data['avatar'] ?? avatar;
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar.isEmpty
                          ? Text(
                              name[0],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: _LastMessage(roomId: room.id),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailPage(room: room),
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

/// Widget ย่อยสำหรับดึงและโชว์ข้อความล่าสุดจาก Firestore
class _LastMessage extends StatelessWidget {
  final String roomId;
  const _LastMessage({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: true) // ใหม่→เก่า
          .limit(1)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          );
        }
        final doc = snap.data!.docs.first;
        final text = doc.get('text') as String;
        return Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        );
      },
    );
  }
}
