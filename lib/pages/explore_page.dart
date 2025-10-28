// lib/pages/explore_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:cativerse/pages/cat_detail_page.dart' show CatDetailPage;

import '../models/cat_models.dart';
import 'cat_detail_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _auth = FirebaseAuth.instance;
  late final String _me;
  final _controller = SwipableStackController();
  bool _liking = false;

  @override
  void initState() {
    super.initState();
    _me = _auth.currentUser!.uid;
  }

  Future<void> _handleLike(String otherUid) async {
    if (_liking) return;
    setState(() => _liking = true);
    try {
      final docId = '${_me}__${otherUid}';
      final ref = FirebaseFirestore.instance.collection('matches').doc(docId);
      if (!(await ref.get()).exists) {
        await ref.set({
          'userId': _me,
          'likedUserId': otherUid,
          'matched': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('cats')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs
            .where((d) => (d.data()['ownerId'] as String?) != _me)
            .toList();

        if (docs.isEmpty) {
          return const Center(child: Text('ไม่มีแมวให้ปัดในตอนนี้ 😿'));
        }

        final cats = docs.map((d) => Cat.fromDoc(d)).toList();

        return Padding(
          padding: const EdgeInsets.all(12),
          child: SwipableStack(
            controller: _controller,
            itemCount: cats.length,
            detectableSwipeDirections: const {
              SwipeDirection.left,
              SwipeDirection.right,
            },
            onSwipeCompleted: (index, direction) {
              if (direction == SwipeDirection.right) {
                _handleLike(cats[index].ownerId);
              }
            },
            // การ์ดแต่ละใบ
            builder: (context, props) {
              final cat = cats[props.index];
              return _SwipeCard(cat: cat);
            },
            // พื้นหลังเฟดสีตามทิศและระยะปัด
            overlayBuilder: (context, props) {
              final p = props.swipeProgress.abs().clamp(0.0, 1.0);
              final dir = props.direction;
              // เริ่มเห็นสีตั้งแต่แตะนิดเดียว แล้วเข้มขึ้นเรื่อย ๆ
              final opacity = (0.15 + 0.85 * p).clamp(0.0, 1.0);

              Color color;
              if (dir == SwipeDirection.right) {
                color = Colors.green.withOpacity(opacity);
              } else if (dir == SwipeDirection.left) {
                color = Colors.red.withOpacity(opacity);
              } else {
                color = Colors.transparent;
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(color: color),
              );
            },
          ),
        );
      },
    );
  }
}

class _SwipeCard extends StatelessWidget {
  final Cat cat;
  const _SwipeCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final imageUrl = cat.imageUrls.isNotEmpty ? cat.imageUrls.first : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CatDetailPage(catId: cat.id)),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade300,
              image: imageUrl != null
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: _CatFooter(cat: cat),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatFooter extends StatelessWidget {
  final Cat cat;
  const _CatFooter({required this.cat});

  @override
  Widget build(BuildContext context) {
    final ageText = ageLabel(cat.birthdate);
    final genderText =
        (cat.gender == 'male') ? '♂' : (cat.gender == 'female') ? '♀' : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${cat.name}, $ageText ($genderText)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cat.description.isNotEmpty ? cat.description : '—',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.2),
        ),
      ],
    );
  }
}
