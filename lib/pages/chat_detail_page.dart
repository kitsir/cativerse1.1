// lib/pages/chat_detail_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatDetailPage extends StatefulWidget {
  final String roomId;
  final String otherUid;
  const ChatDetailPage({super.key, required this.roomId, required this.otherUid});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _ctrl = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final uid = _auth.currentUser!.uid;
      final now = FieldValue.serverTimestamp();

      final msgRef = _db.collection('rooms').doc(widget.roomId).collection('messages').doc();
      await msgRef.set({
        'id': msgRef.id,
        'authorId': uid,
        'text': text,
        'createdAt': now,
        'type': 'text',
      });

      await _db.collection('rooms').doc(widget.roomId).set({
        'lastMessage': text,
        'updatedAt': now,
      }, SetOptions(merge: true));

      _ctrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ส่งข้อความไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;
    final stream = _db.collection('rooms').doc(widget.roomId)
        .collection('messages').orderBy('createdAt', descending: false).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('แชท')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snap.data!.docs;
                if (msgs.isEmpty) {
                  return const Center(child: Text('ส่งข้อความทักทายกันได้เลย'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i].data();
                    final isMe = m['authorId'] == uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (m['text'] as String?) ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 6, 12),
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ…',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 12, 12),
                  child: IconButton(
                    icon: _sending
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
