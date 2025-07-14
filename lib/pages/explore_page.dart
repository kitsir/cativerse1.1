import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ExplorePage extends StatefulWidget {
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _auth = FirebaseAuth.instance;
  List<int> _currentImage = [];

  Future<void> handleLike(String otherUid) async {
    final me = _auth.currentUser!.uid;
    final matchRef = FirebaseFirestore.instance.collection('matches');

    await matchRef.add({
      'userId': me,
      'likedUserId': otherUid,
      'matched': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final mutual = await matchRef
        .where('userId', isEqualTo: otherUid)
        .where('likedUserId', isEqualTo: me)
        .get();

    if (mutual.docs.isNotEmpty) {
      await matchRef.add({
        'userId': me,
        'likedUserId': otherUid,
        'matched': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .get();
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cats')
          .where('ownerId', isNotEqualTo: _auth.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text('ไม่มีแมวให้ปัดในตอนนี้ 😿'));
        }

        final cats = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return data;
        }).toList();

        if (_currentImage.length != cats.length) {
          _currentImage = List.filled(cats.length, 0);
        }

        return CardSwiper(
          cardsCount: cats.length,
          numberOfCardsDisplayed: cats.length < 3 ? cats.length : 3,
          isLoop: false,
          onSwipe: (prev, _, direction) {
            if (direction == CardSwiperDirection.right) {
              handleLike(cats[prev]['ownerId'] as String);
            }
            return true;
          },
          cardBuilder: (context, index, _, __) {
            final cat = cats[index];
            final List imageUrls = cat['imageUrls'] as List;
            final currentIdx = _currentImage[index];
            final imageUrl = imageUrls[currentIdx] as String;

            return LayoutBuilder(
              builder: (ctx, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    if (imageUrls.length <= 1) return;
                    final tapX = details.localPosition.dx;
                    final w = constraints.maxWidth;
                    setState(() {
                      if (tapX > w / 2) {
                        _currentImage[index] = (currentIdx + 1) % imageUrls.length;
                      } else {
                        _currentImage[index] = (currentIdx - 1 + imageUrls.length) % imageUrls.length;
                      }
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                          gradient: LinearGradient(
                            colors: [Colors.black54, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${cat['name']}, ${cat['age']} ปี (${cat['gender'] ?? '-'})',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              cat['description'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
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
