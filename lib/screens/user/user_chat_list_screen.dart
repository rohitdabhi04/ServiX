import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';
import '../../widgets/user_avatar.dart';

class UserChatListScreen extends StatelessWidget {
  const UserChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("messages")
            .where("participants", arrayContains: currentUser?.uid)
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final Map<String, Map<String, dynamic>> chatMap = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final sender = data['senderId'];
            final receiver = data['receiverId'];
            if (sender == currentUser?.uid) {
              chatMap[receiver] = data;
            } else {
              chatMap[sender] = data;
            }
          }

          final users = chatMap.keys.toList();
          if (users.isEmpty) {
            return const Center(child: Text("No Chats Yet"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userId = users[index];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data() as Map<String, dynamic>?;
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
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      chatMap[userId]?['text'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
      ),
    );
  }
}