import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class LikesPage extends StatelessWidget {
  LikesPage({super.key});
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final me = _auth.currentUser!.uid;
    final stream = FirebaseFirestore.instance
        .collection('matches')
        .where('likedUserId', isEqualTo: me)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Likes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('ยังไม่มีใครถูกใจคุณ'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final d = docs[i];
              final likerUid = d['userId'] as String;
              final matched = (d.data() as Map<String, dynamic>)['matched'] == true;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(likerUid).get(),
                builder: (c, s) {
                  final avatar = s.data?.get('avatar') as String?;
                  final first = s.data?.get('firstName') as String? ?? '';
                  final last = s.data?.get('lastName') as String? ?? '';
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: avatar != null ? NetworkImage(avatar) : null),
                    title: Text('$first $last'),
                    subtitle: Text(matched ? 'Matched • เริ่มแชตได้เลย' : 'ชอบคุณ!'),
                    trailing: matched
                        ? const Icon(Icons.favorite, color: Colors.red)
                        : ElevatedButton.icon(
                            onPressed: () async {
                              await d.reference.update({'matched': true});
                              await FirebaseChatCore.instance.createRoom(types.User(
                                id: likerUid, firstName: first, lastName: last, imageUrl: avatar,
                              ));
                              await FirebaseFirestore.instance.collection('matches').add({
                                'userId': me,
                                'likedUserId': likerUid,
                                'matched': true,
                                'timestamp': FieldValue.serverTimestamp(),
                              });
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('จับคู่สำเร็จ!')));
                              }
                            },
                            icon: const Icon(Icons.favorite),
                            label: const Text('ตอบรับ'),
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
