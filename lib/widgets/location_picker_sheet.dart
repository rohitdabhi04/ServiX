import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _searchController = TextEditingController();

  final List<String> _popularCities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Ahmedabad',
    'Hyderabad',
    'Chennai',
    'Pune',
    'Surat',
    'Jaipur',
    'Kolkata',
    'Lucknow',
    'Kanpur',
    'Nagpur',
    'Indore',
    'Bhopal',
    'Vadodara',
    'Rajkot',
    'Coimbatore',
    'Visakhapatnam',
    'Thane',
  ];

  List<String> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = _popularCities;
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = _popularCities;
      } else {
        _filteredCities = _popularCities
            .where((c) => c.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleResult(BuildContext context, String result, LocationProvider loc) {
    if (!context.mounted) return;
    if (result == 'success') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Location set: ${loc.displayLocation}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result == 'gps_off') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please turn on GPS/Location from settings.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result == 'permission_denied_forever') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⚠️ Location permission blocked. Enable from App Settings.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Location permission denied.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Set Your Location',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // GPS Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: locationProvider.isLoading
                  ? null
                  : () async {
                      final result = await locationProvider.detectLocation();
                      if (!context.mounted) return;
                      _handleResult(context, result, locationProvider);
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Current Location',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'GPS se automatically detect karo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (locationProvider.isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    else
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // OR Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OR',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCities,
              decoration: InputDecoration(
                hintText: 'Search city...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.colorScheme.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onSubmitted: (value) async {
                if (value.trim().isNotEmpty) {
                  await locationProvider.setManualLocation(value.trim());
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
            ),
          ),

          const SizedBox(height: 8),

          // Cities list
          SizedBox(
            height: 220,
            child: _filteredCities.isEmpty
                ? Center(
                    child: Text(
                      'No city found.\nPress Enter to use "${_searchController.text}"',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      final isCurrentCity =
                          locationProvider.city == city;
                      return ListTile(
                        leading: Icon(
                          Icons.location_city_rounded,
                          size: 20,
                          color: isCurrentCity
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                        title: Text(
                          city,
                          style: TextStyle(
                            fontWeight: isCurrentCity
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrentCity
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        trailing: isCurrentCity
                            ? Icon(Icons.check_circle_rounded,
                                color: theme.colorScheme.primary, size: 18)
                            : null,
                        onTap: () async {
                          await locationProvider.setManualLocation(city);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
