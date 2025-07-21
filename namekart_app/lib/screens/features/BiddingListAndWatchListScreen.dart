import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../activity_helpers/UIHelpers.dart'; // Assuming this provides the 'text' widget
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

  // --- Filter State Variables ---
  String _searchQuery = '';
  Set<String> _selectedPlatforms = {};
  Set<String> _selectedResults = {};
  Set<String> _selectedAuctionTypes = {};
  Set<String> _selectedAges = {};
  Set<String> _selectedAppraisals = {};

  // --- Sorting State Variables ---
  String _selectedSortBy = 'Ends Soonest'; // Default sort order

  List<String> _platformFilters = ['All Platforms'];
  List<String> _resultFilters = ['All Results', 'Bid Placed', 'Outbid', 'Bid Scheduled', 'Won', 'Loss', 'Bid Cancelled'];
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

  bool isSearchBoxOpen=false;

  @override
  void initState() {
    super.initState();
    _biddingListFuture = _loadBiddingData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterAndSortBids();
      });
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

      final Set<String> uniquePlatforms = fetchedBids
          .map((bid) => bid.platform)
          .where((platform) => platform != null && platform.isNotEmpty)
          .cast<String>()
          .toSet();

      final Set<String> uniqueAuctionTypes = fetchedBids
          .map((bid) => bid.auctiontype)
          .where((type) => type != null && type.isNotEmpty)
          .cast<String>()
          .toSet();

      setState(() {
        _allBids = fetchedBids;
        _platformFilters = ['All Platforms', ...uniquePlatforms.toList()..sort()];
        _auctionTypeFilters = ['All Types', ...uniqueAuctionTypes.toList()..sort()];

        _selectedPlatforms.clear();
        _selectedResults.clear();
        _selectedAuctionTypes.clear();
        _selectedAges.clear();
        _selectedAppraisals.clear();

        _filterAndSortBids();
      });
      return fetchedBids;
    } catch (e) {
      setState(() {
        _allBids = [];
        _filteredBids = [];
      });
      rethrow;
    }
  }

  void _filterAndSortBids() {
    List<DBdetails> tempBids = List.from(_allBids);

    if (_searchQuery.isNotEmpty) {
      tempBids = tempBids.where((bid) =>
      bid.domain != null &&
          bid.domain!.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    if (_selectedPlatforms.isNotEmpty && !_selectedPlatforms.contains('All Platforms')) {
      tempBids = tempBids.where((bid) => bid.platform != null && _selectedPlatforms.contains(bid.platform!)).toList();
    }

    if (_selectedResults.isNotEmpty && !_selectedResults.contains('All Results')) {
      tempBids = tempBids.where((bid) => bid.result != null && _selectedResults.contains(bid.result!)).toList();
    }

    if (_selectedAuctionTypes.isNotEmpty && !_selectedAuctionTypes.contains('All Types')) {
      tempBids = tempBids.where((bid) => bid.auctiontype != null && _selectedAuctionTypes.contains(bid.auctiontype!)).toList();
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
        final num? appraisalValue = (bid.estibot != null && bid.estibot! > 0)
            ? bid.estibot
            : (bid.gdv != null && bid.gdv! > 0 ? bid.gdv : null);

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
      switch (_selectedSortBy) {
        case 'Domain A-Z': return (a.domain ?? '').compareTo(b.domain ?? '');
        case 'Domain Z-A': return (b.domain ?? '').compareTo(a.domain ?? '');
        case 'Ends Soonest': return _compareEndTimes(a.endTimeist, b.endTimeist);
        case 'Ends Latest': return _compareEndTimes(b.endTimeist, a.endTimeist);
        case 'Highest Current Bid': return _compareCurrencyStringsDesc(a.currbid, b.currbid);
        case 'Lowest Current Bid': return _compareCurrencyStringsAsc(a.currbid, b.currbid);
        case 'Highest My Max Bid': return _compareCurrencyStringsDesc(a.bidAmount, b.bidAmount);
        case 'Lowest My Max Bid': return _compareCurrencyStringsAsc(a.bidAmount, b.bidAmount);
        case 'Highest Estibot': return _compareNumbersDesc(a.estibot?.toDouble(), b.estibot?.toDouble());
        case 'Lowest Estibot': return _compareNumbersAsc(a.estibot?.toDouble(), b.estibot?.toDouble());
        case 'Newest Domain Age': return _compareNumbersAsc(a.age?.toDouble(), b.age?.toDouble());
        case 'Oldest Domain Age': return _compareNumbersDesc(a.age?.toDouble(), b.age?.toDouble());
        default: return 0;
      }
    });

    setState(() {
      _filteredBids = tempBids;
    });
  }

  int _compareEndTimes(String? timeA, String? timeB) {
    if (timeA == null && timeB == null) return 0;
    if (timeA == null) return 1;
    if (timeB == null) return -1;
    try {
      final dateTimeA = DateFormat("yyyy-MM-dd HH:mm 'IST'").parse(timeA).toLocal();
      final dateTimeB = DateFormat("yyyy-MM-dd HH:mm 'IST'").parse(timeB).toLocal();
      return dateTimeA.compareTo(dateTimeB);
    } catch (e) {
      print('Error comparing dates: $e for $timeA vs $timeB');
      return 0;
    }
  }

  double? _parseCurrencyStringToDouble(String? currencyString) {
    if (currencyString == null || currencyString.isEmpty) {
      return null;
    }
    final cleanedString = currencyString.replaceAll(RegExp(r'[^\d.]'), '').trim();
    try {
      return double.parse(cleanedString);
    } on FormatException catch (e) {
      print('Warning: Failed to parse currency string "$currencyString": $e');
      return null;
    } catch (e) {
      print('Error parsing currency string "$currencyString": $e');
      return null;
    }
  }

  int _compareNumbersAsc(num? a, num? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  int _compareNumbersDesc(num? a, num? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  int _compareCurrencyStringsAsc(String? aString, String? bString) {
    final double? a = _parseCurrencyStringToDouble(aString);
    final double? b = _parseCurrencyStringToDouble(bString);
    return _compareNumbersAsc(a, b);
  }

  int _compareCurrencyStringsDesc(String? aString, String? bString) {
    final double? a = _parseCurrencyStringToDouble(aString);
    final double? b = _parseCurrencyStringToDouble(bString);
    return _compareNumbersDesc(a, b);
  }

  void _showFilterBottomSheet(BuildContext context) {
    Set<String> tempSelectedPlatforms = Set.from(_selectedPlatforms);
    Set<String> tempSelectedResults = Set.from(_selectedResults);
    Set<String> tempSelectedAuctionTypes = Set.from(_selectedAuctionTypes);
    Set<String> tempSelectedAges = Set.from(_selectedAges);
    Set<String> tempSelectedAppraisals = Set.from(_selectedAppraisals);
    String tempSelectedSortBy = _selectedSortBy;

    _FilterCategory _currentCategory = _FilterCategory.platform;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      text(text: 'Filters & Sort', size: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xff717171)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xff717171),size: 16,),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 120.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView(
                            children: [
                              _buildFilterCategoryTitle(context, _FilterCategory.platform, 'Platform', _currentCategory, (category) {
                                setModalState(() => _currentCategory = category);
                              }),
                              _buildFilterCategoryTitle(context, _FilterCategory.resultStatus, 'Result Status', _currentCategory, (category) {
                                setModalState(() => _currentCategory = category);
                              }),
                              _buildFilterCategoryTitle(context, _FilterCategory.auctionType, 'Auction Type', _currentCategory, (category) {
                                setModalState(() => _currentCategory = category);
                              }),
                              _buildFilterCategoryTitle(context, _FilterCategory.age, 'Age', _currentCategory, (category) {
                                setModalState(() => _currentCategory = category);
                              }),
                              _buildFilterCategoryTitle(context, _FilterCategory.appraisalValue, 'Appraisal Value', _currentCategory, (category) {
                                setModalState(() => _currentCategory = category);
                              }),
                              const Divider(height: 20),
                              _buildFilterCategoryTitle(context, _FilterCategory.sortBy, 'Sort By', _currentCategory, (category) {
                                setModalState(() => _currentCategory = category);
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildFilterOptionsList(
                            context,
                            _currentCategory,
                            setModalState,
                            tempSelectedPlatforms,
                            tempSelectedResults,
                            tempSelectedAuctionTypes,
                            tempSelectedAges,
                            tempSelectedAppraisals,
                            tempSelectedSortBy,
                                (newValue) => tempSelectedSortBy = newValue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempSelectedPlatforms.clear();
                              tempSelectedResults.clear();
                              tempSelectedAuctionTypes.clear();
                              tempSelectedAges.clear();
                              tempSelectedAppraisals.clear();
                              tempSelectedSortBy = 'Ends Soonest';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: text(text: 'Reset', color: Theme.of(context).colorScheme.primary, size: 12.sp, fontWeight: FontWeight.w300),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedPlatforms = tempSelectedPlatforms;
                              _selectedResults = tempSelectedResults;
                              _selectedAuctionTypes = tempSelectedAuctionTypes;
                              _selectedAges = tempSelectedAges;
                              _selectedAppraisals = tempSelectedAppraisals;
                              _selectedSortBy = tempSelectedSortBy;
                            });
                            _filterAndSortBids();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: text(text: 'Apply', color: Theme.of(context).colorScheme.onPrimary, size: 12.sp, fontWeight: FontWeight.w300),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterCategoryTitle(BuildContext context, _FilterCategory category, String title, _FilterCategory currentSelected, ValueChanged<_FilterCategory> onTap) {
    final bool isSelected = category == currentSelected;
    return InkWell(
      onTap: () => onTap(category),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: text(
          text: title,
          size: 11.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xff717171),
        ),
      ),
    );
  }

  Widget _buildFilterOptionsList(
      BuildContext context,
      _FilterCategory currentCategory,
      StateSetter setModalState,
      Set<String> tempSelectedPlatforms,
      Set<String> tempSelectedResults,
      Set<String> tempSelectedAuctionTypes,
      Set<String> tempSelectedAges,
      Set<String> tempSelectedAppraisals,
      String tempSelectedSortBy,
      ValueChanged<String> onSortByChanged,
      ) {
    List<String> options = [];
    Set<String> currentSelections = {};
    bool isMultiSelect = true;

    switch (currentCategory) {
      case _FilterCategory.platform:
        options = _platformFilters;
        currentSelections = tempSelectedPlatforms;
        break;
      case _FilterCategory.resultStatus:
        options = _resultFilters;
        currentSelections = tempSelectedResults;
        break;
      case _FilterCategory.auctionType:
        options = _auctionTypeFilters;
        currentSelections = tempSelectedAuctionTypes;
        break;
      case _FilterCategory.age:
        options = _ageFilters;
        currentSelections = tempSelectedAges;
        break;
      case _FilterCategory.appraisalValue:
        options = _appraisalFilters;
        currentSelections = tempSelectedAppraisals;
        break;
      case _FilterCategory.sortBy:
        options = _sortOptions;
        isMultiSelect = false;
        break;
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        if (isMultiSelect) {
          return CheckboxListTile(
            title: text(text: option, size: 10.sp, color: const Color(0xff717171), fontWeight: FontWeight.w300),
            value: currentSelections.contains(option),
            onChanged: (bool? selected) {
              setModalState(() {
                if (option.contains('All ')) {
                  if (selected!) {
                    currentSelections.clear();
                    currentSelections.add(option);
                  } else {
                    currentSelections.remove(option);
                  }
                } else {
                  if (currentSelections.contains('All ')) {
                    currentSelections.removeWhere((element) => element.contains('All '));
                  }
                  if (selected!) {
                    currentSelections.add(option);
                  } else {
                    currentSelections.remove(option);
                  }
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          );
        } else {
          return RadioListTile<String>(
            title: text(text: option, size: 10.sp, color: const Color(0xff717171), fontWeight: FontWeight.w300),
            value: option,
            groupValue: tempSelectedSortBy,
            onChanged: (String? newValue) {
              setModalState(() {
                if (newValue != null) {
                  onSortByChanged(newValue);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xffF7F7F7),
        surfaceTintColor: const Color(0xffF7F7F7),
        titleSpacing: 0,
        iconTheme: const IconThemeData(size: 15, color: Color(0xff717171)),
        title: text(
          text: widget.api == "/getWatchList" ? "WatchList" : "BiddingList",
          size: 12.sp,
          color: const Color(0xff717171),
          fontWeight: FontWeight.bold,
        ),
        actions: [

          Bounceable(
              onTap: (){ setState(() {
                isSearchBoxOpen = !isSearchBoxOpen;
              });},
              child: Icon(isSearchBoxOpen?Icons.search_off_rounded:Icons.search_rounded,color: const Color(0xff717171),size: 16,)),

          SizedBox(width: 10,),
          Bounceable(
              onTap: () => _showFilterBottomSheet(context),
              child: Icon(Icons.filter_alt,color: Color(0xff717171),size: 16,)),
          SizedBox(width: 10,),

        ],
      ),
      body: Column(
        children: [
          // --- Search Bar and Filter Button ---
          if(isSearchBoxOpen)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Domain',
                      hintText: 'e.g., example.com',
                      hintStyle: TextStyle(color: Color(0xff717171),fontSize: 12),
                      labelStyle: TextStyle(color: Color(0xff717171),fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Color(0xff717171),size: 12,),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),borderSide: BorderSide(color: Colors.black12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),borderSide: BorderSide(color: Colors.black12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),borderSide: BorderSide(color: Colors.black12)),
                      contentPadding: EdgeInsets.all(2),
                    ),
                    onChanged: (value) {
                      // Handled by addListener in initState
                    },
                  ),
                ),
              ],
            ),
          ),
          // --- NEW: Display Applied Filters/Sort as Chips ---
          _buildAppliedFilterChips(), // Call the new method here
          // --- Bids List ---
          Expanded(
            child: FutureBuilder<List<DBdetails>>(
              future: _biddingListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _allBids.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: colorScheme.error, size: 40),
                          const SizedBox(height: 10),
                          text(text: 'Error: ${snapshot.error}', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w300),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _biddingListFuture = _loadBiddingData();
                              });
                            },
                            child: text(text: 'Try Again', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w300),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (_filteredBids.isEmpty && (snapshot.connectionState == ConnectionState.done || _searchQuery.isNotEmpty || _selectedPlatforms.isNotEmpty || _selectedResults.isNotEmpty || _selectedAuctionTypes.isNotEmpty || _selectedAges.isNotEmpty || _selectedAppraisals.isNotEmpty)) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant, size: 40),
                        const SizedBox(height: 10),
                        text(text: 'No bids found for the selected filters.', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w300),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedPlatforms.clear();
                              _selectedResults.clear();
                              _selectedAuctionTypes.clear();
                              _selectedAges.clear();
                              _selectedAppraisals.clear();
                              _selectedSortBy = 'Ends Soonest';
                              _filterAndSortBids();
                            });
                          },
                          child: text(text: 'Reset Filters & Refresh', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w300),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _filteredBids.length,
                    itemBuilder: (context, index) {
                      final bid = _filteredBids[index];

                      String formattedEndTime = 'N/A';
                      if (bid.endTimeist != null && bid.endTimeist!.isNotEmpty) {
                        try {
                          final dateTime = DateFormat("yyyy-MM-dd HH:mm 'IST'").parse(bid.endTimeist!);
                          formattedEndTime = DateFormat('MMM dd, yyyy HH:mm').format(dateTime.toLocal());
                        } on FormatException catch (e) {
                          print('DateFormat.parse failed for endTimeist: ${bid.endTimeist} - $e');
                          formattedEndTime = bid.endTimeist!;
                        } catch (e) {
                          print('Other error parsing endTimeist: ${bid.endTimeist} - $e');
                          formattedEndTime = bid.endTimeist!;
                        }
                      }

                      String formattedWhoisDate = 'N/A';
                      if (bid.whoisCreateDate != null && bid.whoisCreateDate!.isNotEmpty) {
                        try {
                          final whoisDate = DateFormat("yyyy-MM-dd").parse(bid.whoisCreateDate!);
                          formattedWhoisDate = DateFormat('MMM dd, yyyy').format(whoisDate);
                        } catch (e) {
                          print('Error parsing whoisCreateDate: ${bid.whoisCreateDate} - $e');
                          formattedWhoisDate = bid.whoisCreateDate!;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        color: bid.result == 'Outbid'
                            ? const Color(0xFFFEE4E4)
                            : (bid.result == 'Won' ? const Color(0xFFE6FAE6) : Colors.white),

                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              text(text: bid.domain ?? 'Unknown Domain', color: const Color(0xff717171), size: 12, fontWeight: FontWeight.w400),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip(context, Icons.account_tree_outlined, 'Platform', bid.platform ?? 'N/A'),
                                  _buildInfoChip(context, Icons.price_change, 'Current Bid', '₹${bid.currbid ?? 'N/A'}'),
                                  _buildInfoChip(context, Icons.gavel, 'My Max Bid', '₹${bid.bidAmount ?? 'N/A'}', isPrimary: true),
                                  _buildInfoChip(context, Icons.schedule, 'Time Left', bid.timeLeft ?? 'N/A'),
                                  _buildInfoChip(context, Icons.calendar_today, 'Ends', formattedEndTime),
                                  if (bid.result != null)
                                    _buildInfoChip(
                                      context,
                                      _getIconForResult(bid.result!),
                                      'Status',
                                      bid.result!,
                                      textColor: _getColorForResult(bid.result!),
                                    ),
                                  if (bid.scheduled == true)
                                    _buildInfoChip(
                                      context,
                                      Icons.timer,
                                      'Scheduled',
                                      'Yes',
                                      textColor: Colors.green,
                                    ),
                                  if (bid.auctiontype != null)
                                    _buildInfoChip(context, Icons.category, 'Type', bid.auctiontype!),
                                ],
                              ),
                              const Divider(height: 24),
                              text(text: 'Appraisal & Details', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w300),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  if (bid.estibot != null && bid.estibot! > 0)
                                    _buildInfoChip(context, Icons.insights, 'Estibot', '₹${bid.estibot}'),
                                  if (bid.gdv != null && bid.gdv! > 0)
                                    _buildInfoChip(context, Icons.trending_up, 'GDV', '₹${bid.gdv}'),
                                  if (bid.whoisRegistrar != null && bid.whoisRegistrar!.isNotEmpty)
                                    _buildInfoChip(context, Icons.business, 'Registrar', bid.whoisRegistrar!),
                                  if (bid.whoisCreateDate != null && bid.whoisCreateDate!.isNotEmpty)
                                    _buildInfoChip(context, Icons.date_range, 'Created', formattedWhoisDate),
                                  if (bid.age != null && bid.age! > 0)
                                    _buildInfoChip(context, Icons.timelapse, 'Age', '${bid.age} yrs'),
                                  if (bid.bids != null && bid.bids! > 0)
                                    _buildInfoChip(context, Icons.money, 'Total Bids', '${bid.bids}'),
                                  if (bid.bidders != null && bid.bidders! > 0)
                                    _buildInfoChip(context, Icons.people, 'Bidders', '${bid.bidders}'),
                                  if (bid.myLastBid != null && bid.myLastBid! > 0)
                                    _buildInfoChip(context, Icons.person_pin, 'My Last Bid', '₹${bid.myLastBid!.toStringAsFixed(2)}'),
                                  if (bid.minNextBid != null && bid.minNextBid! > 0)
                                    _buildInfoChip(context, Icons.arrow_right_alt, 'Min Next Bid', '₹${bid.minNextBid!.toStringAsFixed(2)}'),
                                  if (bid.renewPrice != null && bid.renewPrice! > 0)
                                    _buildInfoChip(context, Icons.autorenew, 'Renew Price', '₹${bid.renewPrice!.toStringAsFixed(2)}'),
                                  if (bid.keywordExactLsv != null && bid.keywordExactLsv! > 0)
                                    _buildInfoChip(context, Icons.search, 'LSV', '${bid.keywordExactLsv}'),
                                  if (bid.keywordExactCpc != null && bid.keywordExactCpc! >= 0)
                                    _buildInfoChip(context, Icons.attach_money_outlined, 'CPC', '₹${bid.keywordExactCpc!.toStringAsFixed(2)}'),
                                  if (bid.endUsersBuyers != null && bid.endUsersBuyers! >= 0)
                                    _buildInfoChip(context, Icons.group, 'EUB', '${bid.endUsersBuyers}'),
                                  if (bid.category != null && bid.category!.isNotEmpty)
                                    _buildInfoChip(context, Icons.folder_open, 'Category', bid.category!),
                                  if (bid.firstWord != null && bid.firstWord!.isNotEmpty)
                                    _buildInfoChip(context, Icons.text_fields, 'First Word', bid.firstWord!),
                                  if (bid.secondWord != null && bid.secondWord!.isNotEmpty)
                                    _buildInfoChip(context, Icons.text_fields, 'Second Word', bid.secondWord!),
                                  if (bid.sldLength != null && bid.sldLength! > 0)
                                    _buildInfoChip(context, Icons.numbers, 'SLD Length', '${bid.sldLength}'),
                                ],
                              ),
                              if (bid.url != null && bid.url!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        print('Launching URL: ${bid.url}');
                                      },
                                      icon: const Icon(Icons.link),
                                      label: text(text: 'View Auction', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w300),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build consistent info chips
  Widget _buildInfoChip(BuildContext context, IconData icon, String label, String value, {Color? textColor, bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPrimary ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isPrimary ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          text(text: '$label:', color: const Color(0xff717171), size: 8, fontWeight: FontWeight.w300),
          Flexible(
            child: text(text: value, color: textColor ?? const Color(0xff717171), size: 8, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }

  // Helper to get icon based on result status
  IconData _getIconForResult(String result) {
    switch (result) {
      case 'Bid Placed':
        return Icons.check_circle_outline;
      case 'Bid Scheduled':
        return Icons.pending_actions;
      case 'Outbid':
        return Icons.cancel_outlined;
      case 'Won':
        return Icons.emoji_events;
      case 'Loss':
        return Icons.mood_bad;
      case 'Bid Cancelled':
        return Icons.close;
      default:
        return Icons.info_outline;
    }
  }

  // Helper to get color based on result status
  Color _getColorForResult(String result) {
    switch (result) {
      case 'Bid Placed':
        return Colors.green;
      case 'Bid Scheduled':
        return Colors.orange;
      case 'Outbid':
        return Colors.red;
      case 'Won':
        return Colors.green.shade700;
      case 'Loss':
        return Colors.red.shade700;
      case 'Bid Cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // Add this method inside the _BiddingListAndWatchListScreenState class

  Widget _buildAppliedFilterChips() {
    List<Widget> chips = [];

    // 1. Add Search Query Chip if active
    if (_searchQuery.isNotEmpty) {
      chips.add(
        Chip(
          label: text(text: 'Search: "$_searchQuery"', size: 9.sp,fontWeight: FontWeight.w300,color: Color(0xff717171)),
          onDeleted: () {
            setState(() {
              _searchController.clear();
              _searchQuery = ''; // Clear the query state
              _filterAndSortBids();
            });
          },
          deleteIcon: Icon(Icons.close, size: 14.sp),
          backgroundColor: Colors.blue.shade100,
          labelStyle: TextStyle(color: Colors.blue.shade800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // 2. Add Platform Filter Chips
    // Only add chips if specific platforms are selected (not 'All Platforms' is implicitly selected)
    if (_selectedPlatforms.isNotEmpty && !_selectedPlatforms.contains('All Platforms')) {
      for (var platform in _selectedPlatforms) {
        chips.add(
          Chip(
            label: text(text: 'Platform: $platform', size: 8.sp,fontWeight: FontWeight.w300,color: Color(0xff717171)),
            onDeleted: () {
              setState(() {
                _selectedPlatforms.remove(platform);
                // If all platforms are deselected, effectively re-add 'All Platforms' filter conceptually
                if (_selectedPlatforms.isEmpty) {
                  // You might want to automatically re-add 'All Platforms' to the set
                  // or just leave it empty, and your filter logic handles empty set as "all"
                  // For now, leaving it empty means no specific platform filter.
                }
                _filterAndSortBids();
              });
            },
            deleteIcon: Icon(Icons.close,color: Color(0xff717171), size: 12.sp),
            backgroundColor: Colors.green.shade100,
            labelStyle: TextStyle(color: Colors.green.shade800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
      }
    }

    // 3. Add Result Status Filter Chips
    if (_selectedResults.isNotEmpty && !_selectedResults.contains('All Results')) {
      for (var result in _selectedResults) {
        chips.add(
          Chip(
            label: text(text: 'Result: $result', size: 9.sp,fontWeight: FontWeight.w300,color: Color(0xff717171)),
            onDeleted: () {
              setState(() {
                _selectedResults.remove(result);
                _filterAndSortBids();
              });
            },
            deleteIcon: Icon(Icons.close, size: 14.sp),
            backgroundColor: Colors.orange.shade100,
            labelStyle: TextStyle(color: Colors.orange.shade800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }

    // 4. Add Auction Type Filter Chips
    if (_selectedAuctionTypes.isNotEmpty && !_selectedAuctionTypes.contains('All Types')) {
      for (var type in _selectedAuctionTypes) {
        chips.add(
          Chip(
            label: text(text: 'Type: $type', size: 9.sp,fontWeight: FontWeight.w300,color: Color(0xff717171)),
            onDeleted: () {
              setState(() {
                _selectedAuctionTypes.remove(type);
                _filterAndSortBids();
              });
            },
            deleteIcon: Icon(Icons.close, size: 14.sp),
            backgroundColor: Colors.purple.shade100,
            labelStyle: TextStyle(color: Colors.purple.shade800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }

    // 5. Add Age Filter Chips
    if (_selectedAges.isNotEmpty && !_selectedAges.contains('All Ages')) {
      for (var ageRange in _selectedAges) {
        chips.add(
          Chip(
            label: text(text: 'Age: $ageRange', size: 9.sp,fontWeight: FontWeight.w300,color: Color(0xff717171)),
            onDeleted: () {
              setState(() {
                _selectedAges.remove(ageRange);
                _filterAndSortBids();
              });
            },
            deleteIcon: Icon(Icons.close, size: 14.sp),
            backgroundColor: Colors.cyan.shade100,
            labelStyle: TextStyle(color: Colors.cyan.shade800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }

    // 6. Add Appraisal Filter Chips
    if (_selectedAppraisals.isNotEmpty && !_selectedAppraisals.contains('All Appraisals')) {
      for (var appraisalRange in _selectedAppraisals) {
        chips.add(
          Chip(
            label: text(text: 'Appraisal: $appraisalRange',size: 9.sp,fontWeight: FontWeight.w300,color: Color(0xff717171)),
            onDeleted: () {
              setState(() {
                _selectedAppraisals.remove(appraisalRange);
                _filterAndSortBids();
              });
            },
            deleteIcon: Icon(Icons.close, size: 14.sp),
            backgroundColor: Colors.brown.shade100,
            labelStyle: TextStyle(color: Colors.brown.shade800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }

    // 7. Add Sort By Chip (no delete button, as sorting is always applied)
    if (_selectedSortBy != 'Ends Soonest') { // Only show if not default sort
      chips.add(
        Chip(
          label: text(text: 'Sorted By: $_selectedSortBy', size: 9.sp,fontWeight: FontWeight.w300,color: Color(0xff717171)),
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(color: Colors.grey.shade800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // Only display the Wrap if there are any chips to show
    if (chips.isEmpty && _searchQuery.isEmpty) { // Also hide if only search is active but no other filters
      return const SizedBox.shrink(); // Return an empty widget if no filters are applied
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Wrap(
        spacing: 8.0, // Space between chips
        runSpacing: 4.0, // Space between lines of chips
        children: chips,
      ),
    );
  }
}