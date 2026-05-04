import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/notification_service.dart';
import '../../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;

  const ChatScreen({super.key, required this.receiverId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;

  String? _receiverName;
  bool _isTyping = false;
  bool _isSending = false;
  bool _isUploadingImage = false;

  // ── Reply state ─────────────────────────────────────────────
  Map<String, dynamic>? _replyToMessage;
  String? _replyToDocId;

  // Typing indicator debounce
  DateTime? _lastTyped;

  @override
  void initState() {
    super.initState();
    _loadReceiverName();
    _markMessagesAsRead();
    controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onTextChanged);
    controller.dispose();
    _scrollController.dispose();
    _setTyping(false);
    super.dispose();
  }

  void _onTextChanged() {
    _lastTyped = DateTime.now();
    if (!_isTyping) _setTyping(true);
    Future.delayed(const Duration(seconds: 2), () {
      if (_lastTyped != null &&
          DateTime.now().difference(_lastTyped!) >= const Duration(seconds: 2)) {
        _setTyping(false);
      }
    });
  }

  Future<void> _setTyping(bool typing) async {
    if (!mounted || currentUser == null) return;
    setState(() => _isTyping = typing);
    try {
      await db.collection('chats').doc(chatId).set({
        'typingUsers': typing
            ? FieldValue.arrayUnion([currentUser!.uid])
            : FieldValue.arrayRemove([currentUser!.uid]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _loadReceiverName() async {
    final doc = await db.collection('users').doc(widget.receiverId).get();
    if (mounted) {
      setState(() {
        _receiverName = (doc.data() as Map<String, dynamic>?)?['name'] ?? 'Chat';
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (currentUser == null) return;
    try {
      final unread = await db
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in unread.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (_) {}
  }

  String get chatId {
    final uid1 = currentUser!.uid;
    final uid2 = widget.receiverId;
    return uid1.compareTo(uid2) <= 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  // ── Send Text Message ─────────────────────────────────────────
  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || currentUser == null) return;

    HapticFeedback.lightImpact();
    setState(() => _isSending = true);
    controller.clear();
    _setTyping(false);

    final Map<String, dynamic> msgData = {
      'chatId': chatId,
      'senderId': currentUser!.uid,
      'receiverId': widget.receiverId,
      'participants': [currentUser!.uid, widget.receiverId],
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'deletedFor': [],
    };

    // Attach reply info if replying
    if (_replyToMessage != null) {
      msgData['replyTo'] = {
        'docId': _replyToDocId,
        'text': _replyToMessage!['text'] ?? '',
        'type': _replyToMessage!['type'] ?? 'text',
        'imageUrl': _replyToMessage!['imageUrl'] ?? '',
        'senderId': _replyToMessage!['senderId'] ?? '',
      };
    }

    // Clear reply
    setState(() {
      _replyToMessage = null;
      _replyToDocId = null;
    });

    await db.collection('messages').add(msgData);
    setState(() => _isSending = false);

    _scrollToBottom();
    _sendNotification(text);
  }

  // ── Pick & Send Image ─────────────────────────────────────────
  Future<void> _pickAndSendImage() async {
    if (currentUser == null) return;

    // Camera ya Gallery choose karo
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Send Photo',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
                ),
                title: const Text('Camera'),
                subtitle: const Text('Take a photo now'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.purple),
                ),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from your gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile == null) return;

      HapticFeedback.lightImpact();
      setState(() => _isUploadingImage = true);

      final file = File(pickedFile.path);
      final imageUrl = await StorageService().uploadChatImage(file);
      if (imageUrl == null) throw Exception('Image upload failed');

      final Map<String, dynamic> msgData = {
        'chatId': chatId,
        'senderId': currentUser!.uid,
        'receiverId': widget.receiverId,
        'participants': [currentUser!.uid, widget.receiverId],
        'text': '',
        'type': 'image',
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'deletedFor': [],
      };

      if (_replyToMessage != null) {
        msgData['replyTo'] = {
          'docId': _replyToDocId,
          'text': _replyToMessage!['text'] ?? '',
          'type': _replyToMessage!['type'] ?? 'text',
          'imageUrl': _replyToMessage!['imageUrl'] ?? '',
          'senderId': _replyToMessage!['senderId'] ?? '',
        };
      }

      setState(() {
        _replyToMessage = null;
        _replyToDocId = null;
      });

      await db.collection('messages').add(msgData);
      _sendNotification('📷 Photo');
      _scrollToBottom();
    } catch (e) {
      debugPrint('Image send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send image. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ── Delete Message ─────────────────────────────────────────────
  Future<void> _deleteMessage(String docId, bool isMe) async {
    if (currentUser == null) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _deleteSheet(ctx, isMe),
    );

    if (result == null) return;

    if (result == 'everyone') {
      // Delete for everyone: replace text
      await db.collection('messages').doc(docId).update({
        'text': '',
        'imageUrl': '',
        'type': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } else if (result == 'me') {
      // Delete only for me
      await db.collection('messages').doc(docId).update({
        'deletedFor': FieldValue.arrayUnion([currentUser!.uid]),
      });
    }
  }

  Widget _deleteSheet(BuildContext ctx, bool isMe) {
    final theme = Theme.of(ctx);
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Delete message?',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          if (isMe)
            ListTile(
              leading: const Icon(Icons.delete_sweep_rounded,
                  color: Colors.redAccent),
              title: const Text('Delete for everyone'),
              subtitle: const Text('This message will be removed for all'),
              onTap: () => Navigator.pop(ctx, 'everyone'),
            ),
          ListTile(
            leading: Icon(Icons.person_remove_rounded,
                color: Colors.orange.shade700),
            title: const Text('Delete for me'),
            subtitle: const Text('This message will only be removed from your chat'),
            onTap: () => Navigator.pop(ctx, 'me'),
          ),
          ListTile(
            leading: const Icon(Icons.close_rounded, color: Colors.grey),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Copy Message ─────────────────────────────────────────────
  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Long Press Options ─────────────────────────────────────────
  void _showMessageOptions(
      BuildContext ctx, String docId, Map<String, dynamic> data, bool isMe) {
    final theme = Theme.of(ctx);
    final type = data['type'] ?? 'text';
    final text = data['text'] ?? '';

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            // Reply option
            ListTile(
              leading: Icon(Icons.reply_rounded,
                  color: theme.colorScheme.primary),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _replyToMessage = data;
                  _replyToDocId = docId;
                });
              },
            ),
            // Copy option (text only)
            if (type == 'text' && text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.blue),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyMessage(text);
                },
              ),
            // Delete option
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMessage(docId, isMe);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendNotification(String preview) async {
    try {
      final senderDoc = await db.collection('users').doc(currentUser!.uid).get();
      final senderName =
          (senderDoc.data() as Map<String, dynamic>?)?['name'] ??
              currentUser!.email ??
              'Someone';
      await NotificationService.sendNotificationToUser(
        userId: widget.receiverId,
        title: '💬 New Message from $senderName',
        body: preview.length > 60
            ? '${preview.substring(0, 60)}...'
            : preview,
      );
    } catch (e) {
      debugPrint('Chat notification error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            UserAvatar(
              userId: widget.receiverId,
              fallbackName: _receiverName ?? '',
              radius: 18,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _receiverName ?? 'Chat',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: db.collection('chats').doc(chatId).snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final data =
                    snap.data?.data() as Map<String, dynamic>?;
                    final typingUsers =
                        (data?['typingUsers'] as List?)?.cast<String>() ?? [];
                    final isOtherTyping =
                    typingUsers.contains(widget.receiverId);
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isOtherTyping
                          ? Row(
                        key: const ValueKey('typing'),
                        children: [
                          _dotIndicator(0, theme),
                          _dotIndicator(1, theme),
                          _dotIndicator(2, theme),
                          const SizedBox(width: 4),
                          Text('typing...',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      )
                          : const SizedBox.shrink(key: ValueKey('idle')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),

          /// 💬 MESSAGES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('messages')
                  .where('chatId', isEqualTo: chatId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Say hello! 👋',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data!.docs;
                // Filter deleted for current user
                final messages = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final deletedFor =
                      (data['deletedFor'] as List?)?.cast<String>() ?? [];
                  return !deletedFor.contains(currentUser?.uid);
                }).toList();

                _markMessagesAsRead();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser?.uid;
                    final isRead = data['isRead'] == true;

                    // Date separator
                    final ts = data['timestamp'] as Timestamp?;
                    final msgDate = ts?.toDate();
                    final prevTs = index < messages.length - 1
                        ? (messages[index + 1].data()
                    as Map<String, dynamic>)['timestamp'] as Timestamp?
                        : null;
                    final prevDate = prevTs?.toDate();
                    final showDate = msgDate != null &&
                        (prevDate == null ||
                            !_isSameDay(msgDate, prevDate));

                    return Column(
                      children: [
                        if (showDate)
                          _dateSeparator(msgDate!, theme, isDark),
                        _swipeableMessage(
                          context, theme, doc.id, data, isMe, isRead,
                          msgDate, isDark,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Reply Preview ──────────────────────────────────────────
          if (_replyToMessage != null)
            _replyPreviewBar(theme, isDark),

          // ── Image uploading indicator ──────────────────────────────
          if (_isUploadingImage)
            LinearProgressIndicator(
              minHeight: 2,
              color: theme.colorScheme.primary,
            ),

          /// ✏️ INPUT BAR
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12),
              ),
            ),
            child: Row(
              children: [
                // Image picker button
                GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndSendImage,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: Icon(
                      Icons.image_rounded,
                      color: _isUploadingImage
                          ? Colors.grey
                          : theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Text field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _replyToMessage != null
                            ? 'Write a reply...'
                            : 'Type a message...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSending
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reply Preview Bar ─────────────────────────────────────────────
  Widget _replyPreviewBar(ThemeData theme, bool isDark) {
    final type = _replyToMessage!['type'] ?? 'text';
    final text = _replyToMessage!['text'] ?? '';
    final imageUrl = _replyToMessage!['imageUrl'] ?? '';
    final isMyMsg = _replyToMessage!['senderId'] == currentUser?.uid;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E3A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMyMsg ? 'Your message' : (_receiverName ?? 'Their message'),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (type == 'image')
                  Row(children: [
                    Icon(Icons.image_rounded,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('Photo', style: TextStyle(color: Colors.grey.shade500,
                        fontSize: 12)),
                  ])
                else
                  Text(
                    text.length > 60 ? '${text.substring(0, 60)}...' : text,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (type == 'image' && imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => setState(() {
              _replyToMessage = null;
              _replyToDocId = null;
            }),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Swipeable Message Wrapper ─────────────────────────────────────
  Widget _swipeableMessage(
      BuildContext context,
      ThemeData theme,
      String docId,
      Map<String, dynamic> data,
      bool isMe,
      bool isRead,
      DateTime? ts,
      bool isDark,
      ) {
    return Dismissible(
      key: ValueKey('swipe_$docId'),
      direction:
      isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        HapticFeedback.selectionClick();
        setState(() {
          _replyToMessage = data;
          _replyToDocId = docId;
        });
        return false; // Don't actually dismiss
      },
      background: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(Icons.reply_rounded,
              color: theme.colorScheme.primary, size: 22),
        ),
      ),
      child: GestureDetector(
        onLongPress: () =>
            _showMessageOptions(context, docId, data, isMe),
        child: _messageBubble(
            context, theme, data, isMe, isRead, ts, isDark),
      ),
    );
  }

  // ── Message Bubble ─────────────────────────────────────────────────
  Widget _messageBubble(
      BuildContext context,
      ThemeData theme,
      Map<String, dynamic> data,
      bool isMe,
      bool isRead,
      DateTime? ts,
      bool isDark,
      ) {
    final text = data['text'] ?? '';
    final type = data['type'] ?? 'text';
    final imageUrl = data['imageUrl'] ?? '';
    final timeStr = ts != null ? DateFormat('h:mm a').format(ts) : '';
    final replyTo = data['replyTo'] as Map<String, dynamic>?;

    final isDeleted = type == 'deleted';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: (!isDeleted && isMe)
              ? LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isDeleted
              ? Colors.grey.shade300
              : (isMe
              ? null
              : (isDark ? const Color(0xFF1E1E3A) : Colors.white)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ── Reply preview inside bubble ─────────────────────────
            if (replyTo != null) _replySnippet(replyTo, isMe, theme, isDark),

            // ── Deleted message ─────────────────────────────────────
            if (isDeleted)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.do_not_disturb_alt_rounded,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'This message was deleted',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            // ── Image message ────────────────────────────────────────
            else if (type == 'image' && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 200,
                    height: 100,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image_rounded),
                  ),
                ),
              )
            // ── Text message ─────────────────────────────────────────
            else
              Text(
                text,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isMe ? Colors.white60 : Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
                if (isMe && !isDeleted) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: isRead ? Colors.lightBlueAccent : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Reply snippet inside bubble ─────────────────────────────────
  Widget _replySnippet(Map<String, dynamic> replyTo, bool isMe,
      ThemeData theme, bool isDark) {
    final rType = replyTo['type'] ?? 'text';
    final rText = replyTo['text'] ?? '';
    final rImageUrl = replyTo['imageUrl'] ?? '';
    final rSenderId = replyTo['senderId'] ?? '';
    final rIsMe = rSenderId == currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.2)
            : (isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isMe
                ? Colors.white60
                : theme.colorScheme.secondary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rIsMe ? 'You' : (_receiverName ?? 'Them'),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white70
                        : theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (rType == 'image')
                  Row(children: [
                    Icon(Icons.image_rounded,
                        size: 12,
                        color: isMe ? Colors.white60 : Colors.grey),
                    const SizedBox(width: 4),
                    Text('Photo',
                        style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white60 : Colors.grey)),
                  ])
                else
                  Text(
                    rText.length > 50
                        ? '${rText.substring(0, 50)}...'
                        : rText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white60 : Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (rType == 'image' && rImageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: rImageUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateSeparator(DateTime date, ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final isYesterday =
    _isSameDay(date, now.subtract(const Duration(days: 1)));

    String label;
    if (isToday) {
      label = 'Today';
    } else if (isYesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat('d MMM yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: isDark ? Colors.white12 : Colors.black12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
              child: Divider(
                  color: isDark ? Colors.white12 : Colors.black12)),
        ],
      ),
    );
  }

  Widget _dotIndicator(int index, ThemeData theme) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + index * 150),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (_, value, __) => Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.3 + 0.7 * value),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}