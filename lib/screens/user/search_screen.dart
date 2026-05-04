import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/rating_bar.dart';
import '../../widgets/user_avatar.dart';
import 'service_detail_screen.dart';
import 'provider_public_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {

  String searchText = '';

  // Filters
  String selectedCategory = 'All';
  double minPrice = 0;
  double maxPrice = 10000;
  double minRating = 0;
  String sortBy = 'Newest'; // Newest | Price Low-High | Price High-Low | Rating

  bool _showFilters = false;

  final List<Map<String, dynamic>> categories = [
    {'label': 'All',         'icon': Icons.apps},
    {'label': 'AC',          'icon': Icons.ac_unit},
    {'label': 'Plumber',     'icon': Icons.plumbing},
    {'label': 'Electrician', 'icon': Icons.electrical_services},
    {'label': 'Cleaning',    'icon': Icons.cleaning_services},
  ];

  final List<String> sortOptions = [
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
    'Top Rated',
  ];

  late AnimationController _filterController;
  late Animation<double> _filterHeight;

  @override
  void initState() {
    super.initState();
    _filterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterHeight = CurvedAnimation(
        parent: _filterController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterController.forward();
    } else {
      _filterController.reverse();
    }
  }

  void _resetFilters() {
    setState(() {
      selectedCategory = 'All';
      minPrice = 0;
      maxPrice = 10000;
      minRating = 0;
      sortBy = 'Newest';
    });
  }

  bool get _hasActiveFilters =>
      selectedCategory != 'All' ||
      minPrice > 0 ||
      maxPrice < 10000 ||
      minRating > 0 ||
      sortBy != 'Newest';

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> docs) {
    var filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final category = data['category'] ?? '';
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      final rating = (data['avgRating'] as num?)?.toDouble() ?? 0;

      final matchSearch = searchText.isEmpty || title.contains(searchText);
      final matchCategory = selectedCategory == 'All' || category == selectedCategory;
      final matchPrice = price >= minPrice && price <= maxPrice;
      final matchRating = rating >= minRating;

      return matchSearch && matchCategory && matchPrice && matchRating;
    }).toList();

    // Sort
    switch (sortBy) {
      case 'Price: Low to High':
        filtered.sort((a, b) {
          final aPrice = (a.data() as Map)['price'] as num? ?? 0;
          final bPrice = (b.data() as Map)['price'] as num? ?? 0;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) {
          final aPrice = (a.data() as Map)['price'] as num? ?? 0;
          final bPrice = (b.data() as Map)['price'] as num? ?? 0;
          return bPrice.compareTo(aPrice);
        });
        break;
      case 'Top Rated':
        filtered.sort((a, b) {
          final aRating = (a.data() as Map)['avgRating'] as num? ?? 0;
          final bRating = (b.data() as Map)['avgRating'] as num? ?? 0;
          return bRating.compareTo(aRating);
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Search Services'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          /// Filter toggle with active badge
          Stack(
            children: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _showFilters
                        ? Icons.filter_list_off_rounded
                        : Icons.filter_list_rounded,
                    key: ValueKey(_showFilters),
                  ),
                ),
                onPressed: _toggleFilters,
                tooltip: 'Filters',
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [

          /// 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => searchText = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
          ),

          /// 🎛 FILTER PANEL (Animated)
          SizeTransition(
            sizeFactor: _filterHeight,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                      if (_hasActiveFilters)
                        GestureDetector(
                          onTap: _resetFilters,
                          child: Text('Reset all',
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  /// Category chips
                  Text('Category',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = selectedCategory == cat['label'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => selectedCategory = cat['label']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark ? Colors.white24 : Colors.black12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat['icon'],
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Text(
                                  cat['label'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : theme.textTheme.bodyMedium?.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// Price Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Price Range',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text(
                        '₹${minPrice.toInt()} — ₹${maxPrice.toInt()}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(minPrice, maxPrice),
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: theme.colorScheme.primary.withOpacity(0.2),
                    onChanged: (v) => setState(() {
                      minPrice = v.start;
                      maxPrice = v.end;
                    }),
                  ),

                  const SizedBox(height: 8),

                  /// Min Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Minimum Rating',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      RatingBar(
                        initialRating: minRating,
                        itemSize: 22,
                        onRatingChanged: (r) =>
                            setState(() => minRating = r),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// Sort By
                  Text('Sort By',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: sortOptions.map((opt) {
                        final isSelected = sortBy == opt;
                        return GestureDetector(
                          onTap: () => setState(() => sortBy = opt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark ? Colors.white24 : Colors.black12),
                              ),
                            ),
                            child: Text(
                              opt,
                              style: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.textTheme.bodyMedium?.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// 📋 RESULTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyState('No services available');
                }

                final filtered = _applyFilters(snapshot.data!.docs);

                if (filtered.isEmpty) {
                  return _emptyState('No results found\nTry changing filters');
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _serviceCard(context, theme, doc.id, data, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(BuildContext context, ThemeData theme, String serviceId,
      Map<String, dynamic> data, int index) {
    final isDark = theme.brightness == Brightness.dark;
    final title = data['title'] ?? 'Service';
    final description = data['description'] ?? '';
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final providerName = data['providerName'] ?? 'Provider';
    final providerId = data['providerId'] ?? '';
    final category = data['category'] ?? '';
    final avgRating = (data['avgRating'] as num?)?.toDouble() ?? 0;
    final totalReviews = (data['totalReviews'] as num?)?.toInt() ?? 0;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 60)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(
              serviceId: serviceId, data: data),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderPublicProfileScreen(
                          providerId: providerId,
                          providerName: providerName,
                        ),
                      ),
                    ),
                    child: UserAvatar(
                      userId: providerId,
                      fallbackName: providerName,
                      radius: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(providerName,
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          )),
                      RatingDisplay(
                          rating: avgRating,
                          totalReviews: totalReviews,
                          compact: true),
                    ],
                  ),
                ],
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      height: 1.4),
                ),
              ],

              if (category.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
  }
}
