import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../user/chat_screen.dart';
import '../../widgets/user_avatar.dart';

class ProviderChatListScreen extends StatelessWidget {
  const ProviderChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("messages")
          .where("participants", arrayContains: currentUser.uid)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final Map<String, Map<String, dynamic>> userMap = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final sender = data['senderId'] ?? '';
          final receiver = data['receiverId'] ?? '';
          if (sender == currentUser.uid && receiver.isNotEmpty) {
            userMap.putIfAbsent(receiver, () => data);
          } else if (receiver == currentUser.uid && sender.isNotEmpty) {
            userMap.putIfAbsent(sender, () => data);
          }
        }

        if (userMap.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("No chats yet",
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        final userIds = userMap.keys.toList();

        return ListView.builder(
          itemCount: userIds.length,
          itemBuilder: (context, index) {
            final userId = userIds[index];
            final lastMessage = userMap[userId]?['text'] ?? '';

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snap) {
                final data =
                snap.data?.data() as Map<String, dynamic>?;
                final name = data?['name'] ?? 'User';
                final imageUrl = data?['image'] as String?;

                return ListTile(
                  leading: UserAvatar(
                    userId: userId,
                    imageUrl: imageUrl,
                    fallbackName: name,
                    radius: 22,
                  ),
                  title: Text(name,
                      style:
                      const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(lastMessage,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(receiverId: userId),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}