import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  String generateChatId(String otherUserId) {
    final uid1 = currentUserId!;
    final uid2 = otherUserId;

    return uid1.hashCode <= uid2.hashCode
        ? "${uid1}_$uid2"
        : "${uid2}_$uid1";
  }

  /// Send a message with isRead tracking
  Future<void> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) return;

    final chatId = generateChatId(receiverId);

    await _db.collection("messages").add({
      "chatId": chatId,
      "senderId": senderId,
      "receiverId": receiverId,
      "participants": [senderId, receiverId],
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    });
  }

  /// Mark all messages in a chat as read (for current user as receiver)
  Future<void> markMessagesAsRead(String chatId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final unread = await _db
        .collection("messages")
        .where("chatId", isEqualTo: chatId)
        .where("receiverId", isEqualTo: uid)
        .where("isRead", isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {"isRead": true});
    }
    await batch.commit();
  }

  /// Stream of total unread message count for badge display
  Stream<int> getUnreadCount() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(0);

    return _db
        .collection("messages")
        .where("receiverId", isEqualTo: uid)
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Stream of unread count for a specific chat
  Stream<int> getChatUnreadCount(String chatId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value(0);

    return _db
        .collection("messages")
        .where("chatId", isEqualTo: chatId)
        .where("receiverId", isEqualTo: uid)
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}