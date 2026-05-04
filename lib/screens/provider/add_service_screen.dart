import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/service_service.dart';

// Real-life Indian service categories with typical prices
const Map<String, Map<String, dynamic>> kServiceCategories = {
  "AC": {
    "icon": Icons.ac_unit,
    "services": [
      {"name": "AC Service & Cleaning", "min": 499, "max": 799},
      {"name": "AC Installation (Split)", "min": 999, "max": 1499},
      {"name": "AC Gas Refilling", "min": 1200, "max": 2000},
      {"name": "AC Repair", "min": 399, "max": 999},
      {"name": "AC Uninstallation", "min": 399, "max": 599},
    ],
  },
  "Plumber": {
    "icon": Icons.plumbing,
    "services": [
      {"name": "Tap/Faucet Repair", "min": 199, "max": 499},
      {"name": "Pipe Leakage Fix", "min": 299, "max": 799},
      {"name": "Bathroom Fitting", "min": 499, "max": 1499},
      {"name": "Water Tank Cleaning", "min": 599, "max": 999},
      {"name": "Toilet Repair", "min": 249, "max": 599},
      {"name": "Motor/Pump Installation", "min": 799, "max": 1499},
    ],
  },
  "Electrician": {
    "icon": Icons.electrical_services,
    "services": [
      {"name": "Fan Installation", "min": 149, "max": 299},
      {"name": "Switchboard Repair", "min": 149, "max": 399},
      {"name": "Light/Bulb Fitting", "min": 99, "max": 249},
      {"name": "MCB/Wiring Repair", "min": 299, "max": 799},
      {"name": "Inverter Installation", "min": 499, "max": 999},
      {"name": "Geyser Installation", "min": 299, "max": 599},
    ],
  },
  "Cleaning": {
    "icon": Icons.cleaning_services,
    "services": [
      {"name": "Home Deep Cleaning (1BHK)", "min": 1499, "max": 2499},
      {"name": "Home Deep Cleaning (2BHK)", "min": 2499, "max": 3999},
      {"name": "Sofa Cleaning", "min": 499, "max": 999},
      {"name": "Bathroom Cleaning", "min": 299, "max": 599},
      {"name": "Kitchen Cleaning", "min": 499, "max": 899},
      {"name": "Carpet Cleaning", "min": 399, "max": 799},
    ],
  },
  "Carpenter": {
    "icon": Icons.handyman,
    "services": [
      {"name": "Furniture Assembly", "min": 299, "max": 699},
      {"name": "Door Repair/Hinge Fix", "min": 199, "max": 499},
      {"name": "Cupboard/Wardrobe Repair", "min": 399, "max": 999},
      {"name": "Bed/Sofa Repair", "min": 499, "max": 1199},
      {"name": "Window Repair", "min": 249, "max": 599},
    ],
  },
  "Painter": {
    "icon": Icons.format_paint,
    "services": [
      {"name": "Room Painting (per room)", "min": 1999, "max": 3999},
      {"name": "Wall Putty & Painting", "min": 2999, "max": 5999},
      {"name": "Exterior Painting (per sqft)", "min": 12, "max": 25},
      {"name": "Waterproofing", "min": 1999, "max": 4999},
      {"name": "Texture Painting", "min": 2999, "max": 6999},
    ],
  },
  "Pest Control": {
    "icon": Icons.bug_report,
    "services": [
      {"name": "Cockroach Treatment (1BHK)", "min": 599, "max": 999},
      {"name": "Termite Treatment", "min": 1499, "max": 2999},
      {"name": "Bed Bug Treatment", "min": 999, "max": 1999},
      {"name": "Full Home Pest Control (2BHK)", "min": 1199, "max": 2499},
      {"name": "Mosquito Control", "min": 499, "max": 899},
    ],
  },
  "Appliance Repair": {
    "icon": Icons.home_repair_service,
    "services": [
      {"name": "Washing Machine Repair", "min": 299, "max": 799},
      {"name": "Refrigerator Repair", "min": 349, "max": 999},
      {"name": "Microwave Repair", "min": 249, "max": 599},
      {"name": "TV Repair", "min": 299, "max": 899},
      {"name": "Water Purifier Service", "min": 349, "max": 699},
    ],
  },
};

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final serviceService = ServiceService();

  bool isLoading = false;
  String? selectedCategory;
  Map<String, dynamic>? selectedService;
  bool useCustomTitle = false;

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
      selectedService = null;
      titleController.clear();
      priceController.clear();
      useCustomTitle = false;
    });
  }

  void _onServiceSelected(Map<String, dynamic> service) {
    setState(() {
      selectedService = service;
      titleController.text = service['name'];
      // Set midpoint price as suggestion
      final mid = ((service['min'] + service['max']) / 2).round();
      priceController.text = mid.toString();
    });
  }

  Future<void> _addService() async {
    if (titleController.text.trim().isEmpty ||
        descController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final price = double.tryParse(priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid price")),
      );
      return;
    }

    setState(() => isLoading = true);

    await serviceService.addService(
      title: titleController.text.trim(),
      description: descController.text.trim(),
      price: priceController.text.trim(),
    );

    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service added successfully")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Service")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// STEP 1 — CATEGORY
            Text("Select Category", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kServiceCategories.entries.map((entry) {
                final isSelected = selectedCategory == entry.key;
                return GestureDetector(
                  onTap: () => _onCategorySelected(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.value['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            /// STEP 2 — SERVICE LIST
            if (selectedCategory != null) ...[
              const SizedBox(height: 20),
              Text("Select Service", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...kServiceCategories[selectedCategory]!['services'].map<Widget>((service) {
                final isSelected = selectedService == service;
                return GestureDetector(
                  onTap: () => _onServiceSelected(service),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            service['name'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? theme.colorScheme.primary : null,
                            ),
                          ),
                        ),
                        Text(
                          "₹${service['min']} – ₹${service['max']}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // Custom service option
              GestureDetector(
                onTap: () {
                  setState(() {
                    useCustomTitle = true;
                    selectedService = null;
                    titleController.clear();
                    priceController.clear();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: useCustomTitle ? theme.colorScheme.secondary.withOpacity(0.1) : theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: useCustomTitle ? theme.colorScheme.secondary : Colors.grey.withOpacity(0.2),
                      width: useCustomTitle ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: theme.colorScheme.secondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Custom Service (type manually)",
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            /// STEP 3 — DETAILS FORM
            if (selectedService != null || useCustomTitle) ...[
              const SizedBox(height: 20),
              Text("Service Details", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              /// TITLE
              TextField(
                controller: titleController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: "Service Title",
                  prefixIcon: const Icon(Icons.work_outline),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// DESCRIPTION
              TextField(
                controller: descController,
                style: theme.textTheme.bodyLarge,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description",
                  hintText: "e.g. Includes cleaning, gas top-up, and filter check",
                  prefixIcon: const Icon(Icons.description_outlined),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// PRICE with range hint
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: "Your Price (₹)",
                  prefixIcon: const Icon(Icons.currency_rupee),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  helperText: selectedService != null
                      ? "Typical range: ₹${selectedService!['min']} – ₹${selectedService!['max']}"
                      : null,
                  helperStyle: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
                ),
              ),

              /// PRICE QUICK PICK CHIPS
              if (selectedService != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text("Quick pick: ", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 6),
                    _priceChip("₹${selectedService!['min']}", selectedService!['min'].toString(), theme),
                    const SizedBox(width: 6),
                    _priceChip(
                      "₹${((selectedService!['min'] + selectedService!['max']) / 2).round()} (mid)",
                      ((selectedService!['min'] + selectedService!['max']) / 2).round().toString(),
                      theme,
                    ),
                    const SizedBox(width: 6),
                    _priceChip("₹${selectedService!['max']}", selectedService!['max'].toString(), theme),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              /// ADD BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _addService,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Add Service", style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _priceChip(String label, String value, ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => priceController.text = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}