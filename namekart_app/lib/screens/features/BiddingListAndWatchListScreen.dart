import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../activity_helpers/UIHelpers.dart';
import '../../services/api_service.dart';
import '../../storageClasses/DBdetails.dart';

enum _FilterCategory {
  platform,
  resultStatus,
  auctionType,
  age,
  appraisalValue,
  sortBy,
}

class BiddingListAndWatchListScreen extends StatefulWidget {
  final String api;
  const BiddingListAndWatchListScreen({super.key, required this.api});

  @override
  State<BiddingListAndWatchListScreen> createState() => _BiddingListAndWatchListScreenState();
}

class _BiddingListAndWatchListScreenState extends State<BiddingListAndWatchListScreen> {
  late Future<List<DBdetails>> _biddingListFuture;
  final ApiService _apiService = ApiService();

  // --- State Variables ---
  String _searchQuery = '';
  Set<String> _selectedPlatforms = {};
  Set<String> _selectedResults = {};
  Set<String> _selectedAuctionTypes = {};
  Set<String> _selectedAges = {};
  Set<String> _selectedAppraisals = {};
  String _selectedSortBy = 'Ends Soonest';

  // --- Filter & Sort Options ---
  List<String> _platformFilters = ['All Platforms'];
  final List<String> _resultFilters = ['All Results', 'Bid Placed', 'Outbid', 'Bid Scheduled', 'Won', 'Loss', 'Bid Cancelled'];
  List<String> _auctionTypeFilters = ['All Types'];
  final List<String> _ageFilters = ['All Ages', '0-1 year', '1-5 years', '5+ years'];
  final List<String> _appraisalFilters = ['All Appraisals', 'Less than ₹1000', '₹1000 - ₹5000', '₹5000 - ₹10000', '₹10000+'];
  final List<String> _sortOptions = [
    'Ends Soonest', 'Ends Latest', 'Domain A-Z', 'Domain Z-A',
    'Highest Current Bid', 'Lowest Current Bid',
    'Highest My Max Bid', 'Lowest My Max Bid',
    'Highest Estibot', 'Lowest Estibot',
    'Newest Domain Age', 'Oldest Domain Age',
  ];

  List<DBdetails> _allBids = [];
  List<DBdetails> _filteredBids = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSearchBoxOpen = false;

  @override
  void initState() {
    super.initState();
    _biddingListFuture = _loadBiddingData();
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
          _filterAndSortBids();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<DBdetails>> _loadBiddingData() async {
    try {
      final List<DBdetails> fetchedBids = await _apiService.fetchBiddingList(widget.api);
      final Set<String> uniquePlatforms = fetchedBids.map((bid) => bid.platform).whereType<String>().toSet();
      final Set<String> uniqueAuctionTypes = fetchedBids.map((bid) => bid.auctiontype).whereType<String>().toSet();

      if (mounted) {
        setState(() {
          _allBids = fetchedBids;
          _platformFilters = ['All Platforms', ...uniquePlatforms.toList()..sort()];
          _auctionTypeFilters = ['All Types', ...uniqueAuctionTypes.toList()..sort()];
          _filterAndSortBids();
        });
      }
      return fetchedBids;
    } catch (e) {
      if (mounted) {
        setState(() {
          _allBids = [];
          _filteredBids = [];
        });
      }
      rethrow;
    }
  }

  void _filterAndSortBids() {
    List<DBdetails> tempBids = List.from(_allBids);

    if (_searchQuery.isNotEmpty) {
      tempBids = tempBids.where((bid) => bid.domain?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false).toList();
    }
    if (_selectedPlatforms.isNotEmpty && !_selectedPlatforms.contains('All Platforms')) {
      tempBids = tempBids.where((bid) => _selectedPlatforms.contains(bid.platform)).toList();
    }
    if (_selectedResults.isNotEmpty && !_selectedResults.contains('All Results')) {
      tempBids = tempBids.where((bid) => _selectedResults.contains(bid.result)).toList();
    }
    if (_selectedAuctionTypes.isNotEmpty && !_selectedAuctionTypes.contains('All Types')) {
      tempBids = tempBids.where((bid) => _selectedAuctionTypes.contains(bid.auctiontype)).toList();
    }
    if (_selectedAges.isNotEmpty && !_selectedAges.contains('All Ages')) {
      tempBids = tempBids.where((bid) {
        if (bid.age == null) return false;
        return _selectedAges.any((filter) {
          switch (filter) {
            case '0-1 year': return bid.age! >= 0 && bid.age! <= 1;
            case '1-5 years': return bid.age! > 1 && bid.age! <= 5;
            case '5+ years': return bid.age! > 5;
            default: return false;
          }
        });
      }).toList();
    }
    if (_selectedAppraisals.isNotEmpty && !_selectedAppraisals.contains('All Appraisals')) {
      tempBids = tempBids.where((bid) {
        final num? appraisalValue = (bid.estibot != null && bid.estibot! > 0) ? bid.estibot : (bid.gdv != null && bid.gdv! > 0 ? bid.gdv : null);
        if (appraisalValue == null) return false;
        return _selectedAppraisals.any((filter) {
          switch (filter) {
            case 'Less than ₹1000': return appraisalValue < 1000;
            case '₹1000 - ₹5000': return appraisalValue >= 1000 && appraisalValue <= 5000;
            case '₹5000 - ₹10000': return appraisalValue > 5000 && appraisalValue <= 10000;
            case '₹10000+': return appraisalValue > 10000;
            default: return false;
          }
        });
      }).toList();
    }

    tempBids.sort((a, b) {
      int compareEndTimes(String? timeA, String? timeB) {
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        try {
          return DateFormat("yyyy-MM-dd HH:mm 'IST'").parse(timeA).compareTo(DateFormat("yyyy-MM-dd HH:mm 'IST'").parse(timeB));
        } catch (e) {
          return 0;
        }
      }
      double? parseCurrency(String? s) => (s == null) ? null : double.tryParse(s.replaceAll(RegExp(r'[^\d.]'), ''));
      int compareNullableNums(num? x, num? y) {
        if (x == null && y == null) return 0;
        if (x == null) return 1;
        if (y == null) return -1;
        return x.compareTo(y);
      }

      switch (_selectedSortBy) {
        case 'Domain A-Z': return (a.domain ?? '').compareTo(b.domain ?? '');
        case 'Domain Z-A': return (b.domain ?? '').compareTo(a.domain ?? '');
        case 'Ends Soonest': return compareEndTimes(a.endTimeist, b.endTimeist);
        case 'Ends Latest': return compareEndTimes(b.endTimeist, a.endTimeist);
        case 'Highest Current Bid': return compareNullableNums(parseCurrency(b.currbid), parseCurrency(a.currbid));
        case 'Lowest Current Bid': return compareNullableNums(parseCurrency(a.currbid), parseCurrency(b.currbid));
        case 'Highest My Max Bid': return compareNullableNums(parseCurrency(b.bidAmount), parseCurrency(a.bidAmount));
        case 'Lowest My Max Bid': return compareNullableNums(parseCurrency(a.bidAmount), parseCurrency(b.bidAmount));
        case 'Highest Estibot': return compareNullableNums(b.estibot, a.estibot);
        case 'Lowest Estibot': return compareNullableNums(a.estibot, b.estibot);
        case 'Newest Domain Age': return compareNullableNums(a.age, b.age);
        case 'Oldest Domain Age': return compareNullableNums(b.age, a.age);
        default: return 0;
      }
    });

    if (mounted) setState(() => _filteredBids = tempBids);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          widget.api == "/getWatchList" ? "Watchlist" : "Bidding List",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold,fontSize: 14.sp,color: Color(0xff717171)),
        ),
        iconTheme: IconThemeData(color: Color(0xff717171),size: 24),
        actions: [
          Bounceable(
            onTap: () => setState(() => _isSearchBoxOpen = !_isSearchBoxOpen),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(_isSearchBoxOpen ? Icons.search_off_rounded : Icons.search_rounded, size: 24),
            ),
          ),
          Bounceable(
            onTap: () => _showFilterBottomSheet(context),
            child: const Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.filter_list_rounded, size: 24),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchBoxOpen ? 80.h : 0,
            child: _isSearchBoxOpen ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by domain name...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                ),
              ),
            ) : const SizedBox.shrink(),
          ),
          _buildAppliedFilterChips(),
          Expanded(
            child: FutureBuilder<List<DBdetails>>(
              future: _biddingListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _allBids.isEmpty) return _buildShimmerEffect();
                if (snapshot.hasError) return _buildErrorState(snapshot.error, colorScheme, textTheme);
                if (_filteredBids.isEmpty) return _buildEmptyState(textTheme, colorScheme);
                return RefreshIndicator(
                  onRefresh: () async => await _loadBiddingData(),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: _filteredBids.length,
                    itemBuilder: (context, index) => _buildBidItemCard(_filteredBids[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedFilterChips() {
    List<Widget> chips = [];
    if (_searchQuery.isNotEmpty) chips.add(_buildFilterChip('Search: "$_searchQuery"', () => _searchController.clear()));
    _selectedPlatforms.where((p) => p != 'All Platforms').forEach((item) => chips.add(_buildFilterChip('Platform: $item', () => setState(() { _selectedPlatforms.remove(item); _filterAndSortBids(); }))));
    _selectedResults.where((r) => r != 'All Results').forEach((item) => chips.add(_buildFilterChip('Result: $item', () => setState(() { _selectedResults.remove(item); _filterAndSortBids(); }))));
    _selectedAuctionTypes.where((t) => t != 'All Types').forEach((item) => chips.add(_buildFilterChip('Type: $item', () => setState(() { _selectedAuctionTypes.remove(item); _filterAndSortBids(); }))));
    _selectedAges.where((a) => a != 'All Ages').forEach((item) => chips.add(_buildFilterChip('Age: $item', () => setState(() { _selectedAges.remove(item); _filterAndSortBids(); }))));
    _selectedAppraisals.where((a) => a != 'All Appraisals').forEach((item) => chips.add(_buildFilterChip('Appraisal: $item', () => setState(() { _selectedAppraisals.remove(item); _filterAndSortBids(); }))));
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 8.h),
      child: SizedBox(
        height: 35.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: chips.map((c) => Padding(padding: EdgeInsets.only(right: 8.w), child: c)).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIconColor: Theme.of(context).colorScheme.onSecondaryContainer,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
      labelStyle: Theme.of(context).textTheme.labelMedium,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemBuilder: (_, __) => Container(
          height: 170.h,
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.0)),
        ),
      ),
    );
  }

  Widget _buildBidItemCard(DBdetails bid) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    Color cardColor = colorScheme.surface;
    Border? border;
    if (bid.result == 'Outbid') {
      cardColor = const Color(0xFFFFF0F0);
      border = Border.all(color: Colors.red.shade200);
    } else if (bid.result == 'Won') {
      cardColor = const Color(0xFFF0FFF3);
      border = Border.all(color: Colors.green.shade200);
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: border?.top ?? BorderSide.none),
      color: cardColor,
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(bid.domain ?? 'Unknown Domain', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                _buildInfoChip(Icons.account_tree_outlined, bid.platform ?? 'N/A'),
              ],
            ),
            SizedBox(height: 4.h),
            _buildStatusChip(bid, textTheme),
            SizedBox(height: 16.h),
            Row(
              children: [
                _buildCoreInfoItem('Current Bid', '₹${bid.currbid ?? 'N/A'}', textTheme),
                _buildCoreInfoItem('My Max Bid', '₹${bid.bidAmount ?? 'N/A'}', textTheme, isHighlighted: true),
                _buildCoreInfoItem('Time Left', bid.timeLeft ?? 'N/A', textTheme),
              ],
            ),
            SizedBox(height: 16.h),
            const Divider(),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                if (bid.estibot != null && bid.estibot! > 0) _buildInfoChip(Icons.insights, 'Estibot: ₹${bid.estibot}'),
                if (bid.age != null && bid.age! > 0) _buildInfoChip(Icons.cake_outlined, 'Age: ${bid.age} yrs'),
                if (bid.bids != null && bid.bids! > 0) _buildInfoChip(Icons.gavel_rounded, 'Bids: ${bid.bids}'),
                if (bid.bidders != null && bid.bidders! > 0) _buildInfoChip(Icons.people_outline, 'Bidders: ${bid.bidders}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
        SizedBox(width: 6.w),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );

  Widget _buildStatusChip(DBdetails bid, TextTheme textTheme) {
    if (bid.result == null) return const SizedBox.shrink();
    Color statusColor = _getColorForResult(bid.result!);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIconForResult(bid.result!), size: 14.sp, color: statusColor),
          SizedBox(width: 6.w),
          Text(bid.result!, style: textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCoreInfoItem(String label, String value, TextTheme textTheme, {bool isHighlighted = false}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall),
        SizedBox(height: 4.h),
        Text(value, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: isHighlighted ? Theme.of(context).colorScheme.primary : null)),
      ],
    ),
  );

  Widget _buildEmptyState(TextTheme textTheme, ColorScheme colorScheme) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 60, color: colorScheme.onSurfaceVariant),
        SizedBox(height: 16.h),
        Text('No Bids Found', style: textTheme.titleLarge),
        SizedBox(height: 8.h),
        Text('Try adjusting your search or filter criteria.', style: textTheme.bodyMedium),
      ],
    ),
  );

  Widget _buildErrorState(Object? error, ColorScheme colorScheme, TextTheme textTheme) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_off, size: 60, color: colorScheme.error),
        SizedBox(height: 16.h),
        Text('Failed to Load Bids', style: textTheme.titleLarge),
        SizedBox(height: 8.h),
        Text('Please check your connection and try again.', style: textTheme.bodyMedium),
        SizedBox(height: 20.h),
        ElevatedButton.icon(
          onPressed: () => setState(() => _biddingListFuture = _loadBiddingData()),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        )
      ],
    ),
  );

  void _showFilterBottomSheet(BuildContext context) {
    Set<String> tempSelectedPlatforms = Set.from(_selectedPlatforms);
    Set<String> tempSelectedResults = Set.from(_selectedResults);
    Set<String> tempSelectedAuctionTypes = Set.from(_selectedAuctionTypes);
    Set<String> tempSelectedAges = Set.from(_selectedAges);
    Set<String> tempSelectedAppraisals = Set.from(_selectedAppraisals);
    String tempSelectedSortBy = _selectedSortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // ✅ DECLARED STATE VARIABLE INSIDE THE BUILDER
        // This ensures setModalState can access and modify it correctly.
        _FilterCategory currentCategory = _FilterCategory.platform;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters & Sort', style: Theme.of(context).textTheme.titleLarge),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120.w,
                          child: ListView(
                            children: _FilterCategory.values.map((category) {
                              bool isSelected = category == currentCategory;
                              Widget title = _buildFilterCategoryTitle(category: category, isSelected: isSelected, onTap: () {
                                // ✅ CORRECTED STATE UPDATE
                                setModalState(() {
                                  currentCategory = category;
                                });
                              });

                              if (category == _FilterCategory.sortBy) {
                                return Column(children: [const Divider(height: 20), title]);
                              }
                              return title;
                            }).toList(),
                          ),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          child: _buildFilterOptionsList(currentCategory, setModalState, tempSelectedPlatforms, tempSelectedResults,
                              tempSelectedAuctionTypes, tempSelectedAges, tempSelectedAppraisals, tempSelectedSortBy,
                                  (newValue) => tempSelectedSortBy = newValue),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelectedPlatforms.clear(); tempSelectedResults.clear(); tempSelectedAuctionTypes.clear();
                                tempSelectedAges.clear(); tempSelectedAppraisals.clear(); tempSelectedSortBy = 'Ends Soonest';
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedPlatforms = tempSelectedPlatforms; _selectedResults = tempSelectedResults;
                                _selectedAuctionTypes = tempSelectedAuctionTypes; _selectedAges = tempSelectedAges;
                                _selectedAppraisals = tempSelectedAppraisals; _selectedSortBy = tempSelectedSortBy;
                              });
                              _filterAndSortBids();
                              Navigator.pop(context);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
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

  // ✅ REFACTORED to be a stateless presentation widget
  Widget _buildFilterCategoryTitle({required _FilterCategory category, required bool isSelected, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titles = {
      _FilterCategory.platform: 'Platform', _FilterCategory.resultStatus: 'Result Status', _FilterCategory.auctionType: 'Auction Type',
      _FilterCategory.age: 'Age', _FilterCategory.appraisalValue: 'Appraisal Value', _FilterCategory.sortBy: 'Sort By',
    };
    return InkWell(
      onTap: onTap, // Uses the passed-in callback
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer.withOpacity(0.4) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          titles[category]!,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOptionsList(
      _FilterCategory currentCategory, StateSetter setModalState,
      Set<String> tempSelectedPlatforms, Set<String> tempSelectedResults, Set<String> tempSelectedAuctionTypes,
      Set<String> tempSelectedAges, Set<String> tempSelectedAppraisals, String tempSelectedSortBy,
      ValueChanged<String> onSortByChanged) {

    List<String> options;
    Set<String>? currentSelections;
    switch (currentCategory) {
      case _FilterCategory.platform: options = _platformFilters; currentSelections = tempSelectedPlatforms; break;
      case _FilterCategory.resultStatus: options = _resultFilters; currentSelections = tempSelectedResults; break;
      case _FilterCategory.auctionType: options = _auctionTypeFilters; currentSelections = tempSelectedAuctionTypes; break;
      case _FilterCategory.age: options = _ageFilters; currentSelections = tempSelectedAges; break;
      case _FilterCategory.appraisalValue: options = _appraisalFilters; currentSelections = tempSelectedAppraisals; break;
      case _FilterCategory.sortBy: options = _sortOptions; currentSelections = null; break;
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        if (currentCategory != _FilterCategory.sortBy) {
          return CheckboxListTile(
            title: Text(option, style: Theme.of(context).textTheme.bodyMedium),
            value: currentSelections!.contains(option),
            onChanged: (bool? selected) {
              setModalState(() {
                if (option.contains('All ')) {
                  currentSelections!.clear();
                  if (selected == true) currentSelections.add(option);
                } else {
                  currentSelections!.removeWhere((e) => e.contains('All '));
                  if (selected == true) currentSelections.add(option); else currentSelections.remove(option);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading, dense: true, contentPadding: EdgeInsets.zero,
          );
        } else {
          return RadioListTile<String>(
            title: Text(option, style: Theme.of(context).textTheme.bodyMedium),
            value: option,
            groupValue: tempSelectedSortBy,
            onChanged: (String? newValue) => setModalState(() { if (newValue != null) onSortByChanged(newValue); }),
            controlAffinity: ListTileControlAffinity.leading, dense: true, contentPadding: EdgeInsets.zero,
          );
        }
      },
    );
  }

  IconData _getIconForResult(String result) {
    switch (result) {
      case 'Bid Placed': return Icons.check_circle_outline;
      case 'Bid Scheduled': return Icons.pending_actions_outlined;
      case 'Outbid': return Icons.cancel_outlined;
      case 'Won': return Icons.emoji_events_outlined;
      case 'Loss': return Icons.sentiment_dissatisfied_outlined;
      case 'Bid Cancelled': return Icons.do_not_disturb_alt_outlined;
      default: return Icons.info_outline;
    }
  }

  Color _getColorForResult(String result) {
    switch (result) {
      case 'Bid Placed': return Colors.green.shade700;
      case 'Bid Scheduled': return Colors.orange.shade800;
      case 'Outbid': return Colors.red.shade700;
      case 'Won': return Colors.teal.shade600;
      case 'Loss': return Colors.red.shade800;
      case 'Bid Cancelled': return Colors.grey.shade600;
      default: return Colors.blue.shade700;
    }
  }
}