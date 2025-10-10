import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../models/cat_models.dart';      // สำหรับ ageLabel และ Cat.fromDoc
import 'cat_detail_page.dart';          // หน้าใหม่รายละเอียดแมว (ที่เราเพิ่มไป)

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _auth = FirebaseAuth.instance;
  late final String _me;
  List<int> _currentImage = [];

  @override
  void initState() {
    super.initState();
    _me = _auth.currentUser!.uid;
  }

  Future<void> _handleLike(String otherUid) async {
    final me = _me;
    final matchRef = FirebaseFirestore.instance.collection('matches');

    // like
    await matchRef.add({
      'userId': me,
      'likedUserId': otherUid,
      'matched': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // mutual?
    final mutual = await matchRef
        .where('userId', isEqualTo: otherUid)
        .where('likedUserId', isEqualTo: me)
        .limit(1)
        .get();

    if (mutual.docs.isNotEmpty) {
      // mark matched (เพิ่มเรคอร์ด matched=true อีกอัน หรือคุณจะอัปเดตเรคอร์ดเดิมก็ได้)
      await matchRef.add({
        'userId': me,
        'likedUserId': otherUid,
        'matched': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // สร้างห้องแชต
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
      if (!userDoc.exists) return;
      final userData = userDoc.data()!;
      await FirebaseChatCore.instance.createRoom(
        types.User(
          id: otherUid,
          firstName: userData['firstName'],
          lastName: userData['lastName'],
          imageUrl: userData['avatar'],
        ),
      );
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

        // กรองไม่ให้เห็นแมวของตัวเอง
        final docs = snapshot.data!.docs
            .where((d) => (d.data()['ownerId'] as String?) != _me)
            .toList();

        if (docs.isEmpty) {
          return const Center(child: Text('ไม่มีแมวให้ปัดในตอนนี้ 😿'));
        }

        // map → Cat model
        final cats = docs.map((d) => Cat.fromDoc(d)).toList();

        if (_currentImage.length != cats.length) {
          _currentImage = List.filled(cats.length, 0);
        }

        return CardSwiper(
          cardsCount: cats.length,
          numberOfCardsDisplayed: cats.length < 3 ? cats.length : 3,
          isLoop: false,
          onSwipe: (prevIndex, _, direction) {
            if (direction == CardSwiperDirection.right) {
              _handleLike(cats[prevIndex].ownerId);
            }
            // left/other = ข้าม
            return true;
          },
          cardBuilder: (context, index, _, __) {
            final cat = cats[index];
            final imageUrls = cat.imageUrls;
            final hasImages = imageUrls.isNotEmpty;
            final currentIdx = _currentImage[index] % (imageUrls.isNotEmpty ? imageUrls.length : 1);
            final imageUrl = hasImages ? imageUrls[currentIdx] : null;

            return LayoutBuilder(
              builder: (ctx, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // เข้าไปดูรายละเอียดแมว
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CatDetailPage(catId: cat.id)),
                    );
                  },
                  onTapUp: (details) {
                    // เปลี่ยนรูปซ้าย/ขวา (ถ้ามีหลายรูป)
                    if (!hasImages || imageUrls.length <= 1) return;
                    final tapX = details.localPosition.dx;
                    final w = constraints.maxWidth;
                    setState(() {
                      if (tapX > w / 2) {
                        _currentImage[index] = (currentIdx + 1) % imageUrls.length;
                      } else {
                        _currentImage[index] =
                            (currentIdx - 1 + imageUrls.length) % imageUrls.length;
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade300,
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          borderRadius:
                              BorderRadius.vertical(bottom: Radius.circular(16)),
                          gradient: LinearGradient(
                            colors: [Colors.black54, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: _CatFooter(cat: cat),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CatFooter extends StatelessWidget {
  final Cat cat;
  const _CatFooter({required this.cat});

  @override
  Widget build(BuildContext context) {
    final ageText = ageLabel(cat.birthdate); // helper จาก models/cat_models.dart
    final genderText = (cat.gender == 'male') ? '♂' : (cat.gender == 'female') ? '♀' : '-';

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
