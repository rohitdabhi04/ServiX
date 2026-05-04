import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/service_service.dart';
import '../../widgets/user_avatar.dart';
import 'service_portfolio_screen.dart';

class ProviderServicesScreen extends StatelessWidget {
  const ProviderServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceService = ServiceService();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("services")
          .where("providerId", isEqualTo: uid)
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
                const Icon(Icons.build_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text("No services yet", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                const Text("Tap + to add a new service", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final services = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final doc = services[index];
            final data = doc.data() as Map<String, dynamic>;

            final price = data['price'];
            double finalPrice = 0;
            if (price is num) {
              finalPrice = price.toDouble();
            } else if (price is String) {
              finalPrice = double.tryParse(price) ?? 0;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      UserAvatar(
                        userId: uid,
                        fallbackName: data['providerName'] ?? '',
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(data['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),

                      /// PORTFOLIO
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.purple),
                        tooltip: "Portfolio",
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ServicePortfolioScreen(
                            serviceId: doc.id,
                            serviceName: data['title'] ?? 'Service',
                          ),
                        )),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: const EdgeInsets.all(4),
                      ),

                      /// EDIT
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showEditDialog(context, doc.id, data),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: const EdgeInsets.all(4),
                      ),

                      /// DELETE
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: const EdgeInsets.all(4),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Delete Service"),
                              content: const Text("Are you sure you want to delete this service?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await serviceService.deleteService(doc.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Service deleted")),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(data['description'] ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "₹${finalPrice.toStringAsFixed(0)}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String serviceId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title']);
    final descController = TextEditingController(text: data['description']);
    final priceController = TextEditingController(text: data['price'].toString());
    final serviceService = ServiceService();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Service"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
              const SizedBox(height: 10),
              TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: "Description")),
              const SizedBox(height: 10),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price", prefixText: "₹ ")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text.trim()) ?? 0;
              await serviceService.updateService(
                serviceId: serviceId,
                title: titleController.text.trim(),
                description: descController.text.trim(),
                price: newPrice,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Service updated")),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}