const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

exports.onMatchUpsert = functions.firestore
  .document('matches/{likeId}')
  .onCreate(async (snap) => {
    const data = snap.data() || {};
    const { userId, likedUserId } = data;
    if (!userId || !likedUserId) return;

    const counterpartId = `${likedUserId}__${userId}`;
    const counterpartRef = db.collection('matches').doc(counterpartId);
    const counterpartSnap = await counterpartRef.get();
    if (!counterpartSnap.exists) return;

    const [a, b] = [userId, likedUserId].sort();
    const roomId = `${a}_${b}`;

    const batch = db.batch();
    batch.update(snap.ref, { matched: true });
    batch.update(counterpartRef, { matched: true });
    batch.set(
      db.collection('rooms').doc(roomId),
      {
        type: 'direct',
        userIds: [a, b],   // สำคัญสำหรับ Flutter Firebase Chat Core
        users: [a, b],     // เผื่อโค้ดที่อ้าง 'users'
        lastMessage: '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      },
      { merge: true }
    );

    await batch.commit();
  });
