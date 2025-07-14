// chat_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatDetailPage extends StatefulWidget {
  final types.Room room;
  const ChatDetailPage({Key? key, required this.room}) : super(key: key);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _me = FirebaseAuth.instance.currentUser!;

  Stream<List<types.Message>> _messageStream() {
    return FirebaseFirestore.instance
      .collection('rooms')
      .doc(widget.room.id)
      .collection('messages')
      .orderBy('createdAt', descending: false) // เก็บจากเก่าสุด→ใหม่สุด
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['createdAt'] as Timestamp?;
        return types.TextMessage(
          author: types.User(id: data['authorId'] as String),
          createdAt: timestamp != null
            ? timestamp.toDate().millisecondsSinceEpoch
            : null,
          id: doc.id,
          text: data['text'] as String? ?? '',
        );
      }).toList());
  }

  Future<void> _handleSend(types.PartialText msg) async {
    await FirebaseFirestore.instance
      .collection('rooms')
      .doc(widget.room.id)
      .collection('messages')
      .add({
        'authorId': _me.uid,
        'text': msg.text,
        'createdAt': FieldValue.serverTimestamp(),
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.room.name ?? 'Chat')),
      body: StreamBuilder<List<types.Message>>(
        stream: _messageStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // ดึงลิสต์ข้อความจาก Firestore (เก่าสุด→ใหม่สุด)
          final original = snap.data ?? [];
          // สลับลำดับเป็น (ใหม่สุด→เก่าสุด) เพื่อให้ Chat วางข้อความใหม่ที่ด้านล่าง
          final messages = original.reversed.toList();

          return Chat(
            messages: messages,
            onSendPressed: _handleSend,
            user: types.User(id: _me.uid),
          );
        },
      ),
    );
  }
}
