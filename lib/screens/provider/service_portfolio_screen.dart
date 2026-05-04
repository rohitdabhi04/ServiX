import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../services/storage_service.dart';

/// Provider uploads portfolio photos per service.
/// Images stored on Cloudinary; URL saved in Firestore.
/// Firestore path: services/{serviceId}/portfolio/{photoId}
class ServicePortfolioScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;

  const ServicePortfolioScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<ServicePortfolioScreen> createState() =>
      _ServicePortfolioScreenState();
}

class _ServicePortfolioScreenState extends State<ServicePortfolioScreen> {
  final _picker = ImagePicker();
  final _storage = StorageService();
  bool _uploading = false;
  double _uploadProgress = 0;

  Future<void> _pickAndUpload() async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final url = await _storage.uploadPortfolioImage(
        File(file.path),
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (url == null) throw Exception("Upload returned null URL");

      await FirebaseFirestore.instance
          .collection("services")
          .doc(widget.serviceId)
          .collection("portfolio")
          .add({
        "url": url,
        "uploadedAt": FieldValue.serverTimestamp(),
        "uploadedBy": uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Photo uploaded successfully!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePhoto(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Delete Photo?"),
        content: const Text(
            "This will permanently remove this photo from your portfolio."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("services")
          .doc(widget.serviceId)
          .collection("portfolio")
          .doc(docId)
          .delete();
      // Note: Cloudinary free plan does not support server-side delete via SDK;
      // URL is removed from Firestore (effectively unreachable from app).
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Photo removed")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Service Portfolio"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: "Add Photo",
            onPressed: _uploading ? null : _pickAndUpload,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Service Banner ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.providerGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_library, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.serviceName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const Text(
                          "Upload your work photos — builds trust",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Upload Progress ───────────────────────────────────────────
          if (_uploading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _uploadProgress < 1.0 ? "Uploading to Cloudinary..." : "Saving...",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.providerPrimary),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ── Photo Grid ────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("services")
                  .doc(widget.serviceId)
                  .collection("portfolio")
                  .orderBy("uploadedAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 64,
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400),
                        const SizedBox(height: 14),
                        const Text("No portfolio photos yet",
                            style: TextStyle(color: Colors.grey, fontSize: 15)),
                        const SizedBox(height: 6),
                        const Text("Tap + to add your work photos",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final url = data['url'] as String? ?? '';

                    return GestureDetector(
                      onTap: () {
                        final urls = docs
                            .map((d) =>
                                (d.data() as Map<String, dynamic>)['url']
                                    as String? ??
                                '')
                            .toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                _PhotoViewer(urls: urls, initial: i),
                          ),
                        );
                      },
                      onLongPress: () => _deletePhoto(doc.id),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: isDark
                                    ? AppColors.cardColor
                                    : AppColors.lightCard,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: isDark
                                    ? AppColors.cardColor
                                    : AppColors.lightCard,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _deletePhoto(doc.id),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _pickAndUpload,
        backgroundColor: AppColors.providerPrimary,
        icon: _uploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add_photo_alternate_outlined,
                color: Colors.white),
        label: Text(
          _uploading ? "Uploading..." : "Add Photo",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// ── Full-screen Photo Viewer ─────────────────────────────────────────────────
class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initial;
  const _PhotoViewer({required this.urls, required this.initial});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _pc;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _pc = PageController(initialPage: widget.initial);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("${_current + 1} / ${widget.urls.length}",
            style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (ctx, i) => InteractiveViewer(
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Read-only Portfolio Widget (shown on service detail for users) ────────────
class PortfolioGalleryWidget extends StatelessWidget {
  final String serviceId;
  const PortfolioGalleryWidget({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("services")
          .doc(serviceId)
          .collection("portfolio")
          .orderBy("uploadedAt", descending: true)
          .limit(9)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Work Portfolio",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final url = data['url'] as String? ?? '';
                  return GestureDetector(
                    onTap: () {
                      final urls = docs
                          .map((d) =>
                              (d.data() as Map<String, dynamic>)['url']
                                  as String? ??
                              '')
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              _PhotoViewer(urls: urls, initial: i),
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isDark
                            ? AppColors.cardColor
                            : AppColors.lightCard,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
