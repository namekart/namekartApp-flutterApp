import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:namekart_app/custom_widget/AnimatedSlideTransition.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../activity_helpers/DbSqlHelper.dart';
import '../../../activity_helpers/FirestoreHelper.dart';
import '../../../activity_helpers/UIHelpers.dart';
import '../../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../../../change_notifiers/WebSocketService.dart';
import '../../../custom_widget/SuperAnimatedWidget.dart';
import '../../../fcm/FcmHelper.dart';
import '../../live_screens/live_details_screen.dart';

typedef DisplaySubitem = Map<String, dynamic>; // {'name': 'subItemName', 'unreadCount': 5}

// --- Modern UI Constants ---
class AppColors {
  static const Color background = Color(0xFFF7F9FC);
  static const Color card = Colors.white;
  static const Color primaryText = Color(0xFF2D3748);
  static const Color secondaryText = Color(0xFF718096);
  static const Color accent = Colors.deepPurple; // A nice accent color
  static const Color notificationBadge = Color(0xFFE53E3E); // Vibrant Red
  static const Color borderColor = Color(0xFFE2E8F0);
}

class AppSpacings {
  static const double screenPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double itemSpacing = 12.0;
}

class ChannelsTab extends StatefulWidget {
  const ChannelsTab({super.key});

  @override
  State<ChannelsTab> createState() => _ChannelsTabState();
}

class _ChannelsTabState extends State<ChannelsTab> with WidgetsBindingObserver {
  late ScrollController _scrollController;

  bool _isInitialLoading = true;
  String _dataMessage = "Syncing data...";
  Map<String, List<String>> _rawParsedMap = {}; // Channel -> List<SubcollectionNames>
  Map<String, List<DisplaySubitem>> _filteredAndSortedMap = {}; // Channel -> List<{'name': subcollection, 'unreadCount': X}>
  Map<String, bool> isExpandedMap = {};

  late NotificationDatabaseChange notificationDatabaseChange;

  TextEditingController searchController = TextEditingController();
  String _currentSearchText = '';

  bool _overallNewNotificationPresent = false;

  final Map<String, ValueNotifier<int>> _subcollectionUnreadCountNotifiers = {};

  // All your existing state management and data fetching logic remains unchanged.
  // ... (initState, _debounceSearch, _handleNotificationDatabaseChange, etc.)
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();

    _initializeAppLoad(); // Consolidated initial app load (fetch paths, sync, then process)

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notificationDatabaseChange = Provider.of<NotificationDatabaseChange>(context, listen: false);
      notificationDatabaseChange.addListener(_handleNotificationDatabaseChange); // Listen for live updates
    });

    searchController.addListener(() {
      if (_currentSearchText != searchController.text.toLowerCase()) {
        _currentSearchText = searchController.text.toLowerCase();
        _debounceSearch();
      }
    });

    WebSocketService().sendMessage({
      "query": "firebase-all_collection_info", // Triggers initial data sync
    });
  }

  Timer? _debounceTimer;
  void _debounceSearch() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      // Search change implies a full re-evaluation of current data
      _processAndSortDataAndSetState(isInitialLoad: false, isSearchChange: true);
    });
  }

  // --- Unified Handler for Database Changes ---
  void _handleNotificationDatabaseChange() async {
    print("NotificationDatabaseChange detected. Re-evaluating UI state.");

    // 1. Re-fetch current channel/subcollection structure from DB
    final Map<String, List<String>> currentDbStructure = await _fetchCurrentDbStructure();

    bool structureChanged = false;
    // Check if the number of channels changed
    if (_rawParsedMap.length != currentDbStructure.length) {
      structureChanged = true;
    } else {
      // Check if any channel has new/removed subcollections
      for (var channelKey in _rawParsedMap.keys) {
        if (!currentDbStructure.containsKey(channelKey) || // Channel removed
            _rawParsedMap[channelKey]!.length != currentDbStructure[channelKey]!.length || // Subcollection count changed
            _rawParsedMap[channelKey]!.any((sub) => !currentDbStructure[channelKey]!.contains(sub))) { // Specific subcollection removed/added
          structureChanged = true;
          break;
        }
      }
      // Check if any new channels were added
      if (!structureChanged) {
        for (var channelKey in currentDbStructure.keys) {
          if (!_rawParsedMap.containsKey(channelKey)) {
            structureChanged = true;
            break;
          }
        }
      }
    }

    if (structureChanged) {
      print("DB structure changed (new channel/subcollection). Performing full re-initialization.");
      _rawParsedMap = currentDbStructure; // Update raw map
      await _initializeNotifiersAndProcessData(); // Re-init notifiers and re-process everything
    } else {
      print("DB structure same. Updating counts and resorting if necessary.");
      // Structure is the same, just counts might have changed.
      // 1. Update ValueNotifiers and _filteredAndSortedMap counts
      bool sortingOrderMightChange = false;
      bool globalUnreadStatusChanged = false;

      for (final channelEntry in _filteredAndSortedMap.entries) {
        final channelName = channelEntry.key;
        final subitems = channelEntry.value;

        for (final displaySubitem in subitems) {
          final subItemName = displaySubitem['name'] as String;
          final oldUnreadCount = displaySubitem['unreadCount'] as int;

          final newUnreadCount = await DbSqlHelper.getReadCount("notifications~$channelName~${subItemName.trim()}");
          print("newunread $newUnreadCount");
          if (newUnreadCount != oldUnreadCount) {
            _subcollectionUnreadCountNotifiers[subItemName]?.value = newUnreadCount;
            displaySubitem['unreadCount'] = newUnreadCount; // Update for sorting

            if ((oldUnreadCount == 0 && newUnreadCount > 0) || (oldUnreadCount > 0 && newUnreadCount == 0)) {
              sortingOrderMightChange = true;
            }
            if ((newUnreadCount > 0 && oldUnreadCount == 0) || (newUnreadCount == 0 && oldUnreadCount > 0)) {
              globalUnreadStatusChanged = true;
            }
          }
        }
      }

      // 2. Update overall new notification flag
      if (globalUnreadStatusChanged) {
        final newOverallPresence = await _checkOverallNewNotificationPresence();
        if (_overallNewNotificationPresent != newOverallPresence) {
          if (mounted) setState(() { _overallNewNotificationPresent = newOverallPresence; });
        }
      }

      // 3. Re-sort the main map ONLY IF counts changed in a way that affects sorting AND no search filter is active
      if (sortingOrderMightChange && _currentSearchText.isEmpty) {
        _resortFilteredAndSortedMap(isLiveUpdate: true);
      } else {
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
            _dataMessage = _filteredAndSortedMap.isNotEmpty ? "Data Found" : "No Data Found";
          });
        }
      }
    }
  }

  // New helper to fetch current channel/subcollection structure from DB (efficiently)
  Future<Map<String, List<String>>> _fetchCurrentDbStructure() async {
    final Map<String, List<String>> tempMap = {};
    final dynamic channelsAndSubcollectionsData = await DbSqlHelper.read("notifications");

    if (channelsAndSubcollectionsData is Map<dynamic, dynamic>) {
      for (var channelEntry in channelsAndSubcollectionsData.entries) {
        final channel = channelEntry.key.toString();
        final subcollectionsMap = channelEntry.value;
        if (subcollectionsMap is Map<dynamic, dynamic>) {
          tempMap.putIfAbsent(channel, () => []);
          for (var subEntry in subcollectionsMap.entries) {
            tempMap[channel]!.add(subEntry.key.toString());
          }
        }
      }
    }
    return Map.fromEntries(
      tempMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }


  // Helper to check overall new notification presence
  Future<bool> _checkOverallNewNotificationPresence() async {
    // Get count for Home Screen (notifications in AMP-LIVE channel)
    final String homeScreenPath = 'notifications~AMP-LIVE';
    int homeCount = await DbSqlHelper.getReadCount(homeScreenPath);

    // Get total unread count across ALL channels
    final String allNotificationsPath = 'notifications';
    final int totalUnreadCount = await DbSqlHelper.getReadCount(allNotificationsPath);

    // Calculate channelReadCount (all unread EXCEPT AMP-LIVE)
    // This ensures that only notifications from other channels contribute to channelReadCount.
    int channelCount = totalUnreadCount - homeCount;

    // Ensure channelReadCount doesn't go negative if there's a data discrepancy,
    // although theoretically, with correct logic, it shouldn't.
    if (channelCount < 0) {
      channelCount = 0;
    }

    // Update the UI
    setState(() {});

    print('Home Screen Unread Count (AMP-LIVE): $homeCount');
    print('Channel Screen Unread Count (Others): $channelCount');


    return (homeCount > 0 || channelCount > 0);
  }

  // --- Consolidated Initial App Load Process ---
  Future<void> _initializeAppLoad() async {
    if (!mounted) return;
    setState(() {
      _isInitialLoading = true;
      _dataMessage = "Syncing data...";
      _overallNewNotificationPresent = false;
    });

    try {
      // Phase 1 & 2: Fetch and Sync from Firestore
      await _fetchAndSyncFirestoreData();

      if (!mounted) {
        setState(() { _dataMessage = "No Data Found"; _isInitialLoading = false; });
        return;
      }

      // Phase 3 & 4: Build _rawParsedMap and Initialize/Update ValueNotifiers
      await _initializeNotifiersAndProcessData(); // <--- Now calling the new helper

    } catch (e, st) {
      print("❌ Error in _initializeAppLoad: $e\n$st");
      if(mounted) {
        setState(() {
          _dataMessage = "Error loading data.";
          _isInitialLoading = false;
        });
      }
    }
  }

  // --- NEW: Helper to Initialize Notifiers and Trigger Processing ---
  // This extracts the common logic for setting up _rawParsedMap and _subcollectionUnreadCountNotifiers
  // and then triggering _processAndSortDataAndSetState.
  Future<void> _initializeNotifiersAndProcessData() async {
    if (!mounted) return;

    // Phase 3: Build _rawParsedMap from current DB state (after sync or initial load)
    _rawParsedMap = await _fetchCurrentDbStructure();

    // Initialize expanded state for new channels if they don't exist
    for (var key in _rawParsedMap.keys) {
      isExpandedMap.putIfAbsent(key, () => true);
    }

    // Phase 4: Initialize/Update ValueNotifiers for all known subcollections
    // Dispose all existing notifiers to prevent memory leaks before clearing and recreating
    _subcollectionUnreadCountNotifiers.forEach((key, notifier) => notifier.dispose());
    _subcollectionUnreadCountNotifiers.clear();

    for (final channelEntry in _rawParsedMap.entries) {
      final channelName = channelEntry.key;
      for (final subItemName in channelEntry.value) {
        // Pre-fetch initial count and create ValueNotifier
        print("notifications~$channelName~${subItemName.trim()}");
        final unread = await DbSqlHelper.getReadCount("notifications~$channelName~$subItemName");
        _subcollectionUnreadCountNotifiers[subItemName] = ValueNotifier<int>(unread);
      }
    }

    // Phase 5: Process, filter, and sort (this uses the updated notifiers)
    // This call is always treated as an "initial" or "full re-sort" from this helper's perspective
    await _processAndSortDataAndSetState(isInitialLoad: true, isSearchChange: false);
  }


  // New helper for Firestore fetching and syncing part of _initializeData
  Future<void> _fetchAndSyncFirestoreData() async {
    final readedData = await readAllCloudPath();
    if (!mounted || readedData == null) {
      return;
    }

    final outerDecoded = jsonDecode(readedData);
    final dataField = outerDecoded['data'];
    final innerDecoded = dataField is String ? jsonDecode(dataField) : dataField;
    final responseRaw = innerDecoded['response'];
    final responseList = responseRaw is String ? jsonDecode(responseRaw) : responseRaw;

    for (var item in responseList) {
      if (item is! String) continue;

      final parts = item.split("~");
      if (parts.length < 3 || parts[0] != "notifications") continue;

      final channel = parts[1];
      final subCollection = parts[2];

      if (channel.isEmpty || subCollection.isEmpty) continue;

      final hivePath = "notifications~$channel~$subCollection";
      final lastDbData = await DbSqlHelper.getLast(hivePath);
      final lastTimestamp = lastDbData?['datetime_id'];

      if (lastTimestamp == null) {
        print("📭 No local data for $hivePath. Fetching 10 latest from Firestore...");
        final latestDocs = await getLatestDocuments(hivePath, limit: 10);
        if (latestDocs.isEmpty) {
          print("⚠️ No documents found on Firestore for $hivePath.");
          continue;
        }
        for (final doc in latestDocs) {
          final docId = doc['datetime_id']?.toString();
          if (docId != null) {
            try {
              await DbSqlHelper.addData(hivePath, docId, doc);
            } catch (e) {
              print("⚠️ Skipping existing doc $docId or error adding: $e");
            }
          }
        }
        final latestStored = await DbSqlHelper.getLast(hivePath);
        final latestId = latestStored?['datetime_id'];
        if (latestId != null) {
          await syncFirestoreFromDocIdTimestamp(hivePath, latestId, false);
        }
      } else {
        print("📦 Found local data for $hivePath: $lastTimestamp. Syncing from Firestore...");
        await syncFirestoreFromDocIdTimestamp(hivePath, lastTimestamp, false);
      }
    }
  }


  // --- Data Processing and Sorting (updates _filteredAndSortedMap) ---
  Future<void> _processAndSortDataAndSetState({required bool isInitialLoad, bool isSearchChange = false}) async {
    if (!mounted) return;

    if (isInitialLoad || isSearchChange) {
      setState(() {
        _isInitialLoading = true;
        _dataMessage = "Processing channels...";
      });
    }

    _overallNewNotificationPresent = await _checkOverallNewNotificationPresence();

    try {
      final String lowerSearchText = _currentSearchText.toLowerCase();

      final List<Future<MapEntry<String, List<DisplaySubitem>>>> futuresForSubcollectionSorting =
      _rawParsedMap.entries.map((entry) async {
        final channel = entry.key;
        final subcollections = entry.value;

        final filteredSubcollections = subcollections.where((sub) {
          final String lowerSubcollection = sub.toLowerCase();
          final String lowerChannel = channel.toLowerCase();
          return lowerChannel.contains(lowerSearchText) ||
              lowerSubcollection.contains(lowerSearchText);
        }).toList();

        if (filteredSubcollections.isEmpty) {
          return MapEntry(channel, <DisplaySubitem>[]);
        }

        final List<DisplaySubitem> subitemsWithCounts = [];
        for (final subItemName in filteredSubcollections) {
          // Get count from the ValueNotifier, which should be updated by _handleNotificationDatabaseChange
          final int unread = _subcollectionUnreadCountNotifiers[subItemName]?.value ?? 0;

          subitemsWithCounts.add({
            'name': subItemName,
            'unreadCount': unread, // Store the count fetched here for sorting
          });
        }

        subitemsWithCounts.sort((a, b) {
          final countA = a['unreadCount'] as int;
          final countB = b['unreadCount'] as int;
          final nameA = a['name'] as String;
          final nameB = b['name'] as String;

          if (countA > 0 && countB > 0) {
            return countB.compareTo(countA);
          }
          if (countA > 0) return -1;
          if (countB > 0) return 1;
          return nameA.compareTo(nameB);
        });

        return MapEntry(channel, subitemsWithCounts);
      }).toList();

      final List<MapEntry<String, List<DisplaySubitem>>> sortedChannelEntries =
      await Future.wait(futuresForSubcollectionSorting);

      final List<MapEntry<String, List<DisplaySubitem>>> nonEmptySortedChannelEntries =
      sortedChannelEntries.where((entry) => entry.value.isNotEmpty).toList();

      final Map<String, int> maxUnreadCountsForChannels = {};
      for (final entry in nonEmptySortedChannelEntries) {
        final channelKey = entry.key;
        final subitemsInChannel = entry.value;

        int maxCount = 0;
        for (final displaySubitem in subitemsInChannel) {
          final count = displaySubitem['unreadCount'] as int;
          if (count > maxCount) {
            maxCount = count;
          }
        }
        maxUnreadCountsForChannels[channelKey] = maxCount;
      }

      nonEmptySortedChannelEntries.sort((a, b) {
        final maxA = maxUnreadCountsForChannels[a.key] ?? 0;
        final maxB = maxUnreadCountsForChannels[b.key] ?? 0;
        return maxB.compareTo(maxA);
      });

      if (!mounted) return;

      setState(() {
        _filteredAndSortedMap = Map.fromEntries(nonEmptySortedChannelEntries);
        if (isInitialLoad || isSearchChange) {
          _isInitialLoading = false;
        }
        _dataMessage = _filteredAndSortedMap.isNotEmpty ? "Data Found" : "No Data Found";
      });

    } catch (e, st) {
      print("❌ Error in _processAndSortDataAndSetState: $e\n$st");
      if (mounted) {
        if (isInitialLoad || isSearchChange) _isInitialLoading = false;
        _dataMessage = "Error processing data.";
      }
    }
  }

  // New method to re-sort the already filtered data without full re-processing
  Future<void> _resortFilteredAndSortedMap({required bool isLiveUpdate}) async {
    if (!mounted) return;

    try {
      final List<MapEntry<String, List<DisplaySubitem>>> tempChannelEntries =
      _filteredAndSortedMap.entries.toList();

      final Map<String, int> maxUnreadCountsForChannels = {};
      for (final entry in tempChannelEntries) {
        final channelKey = entry.key;
        final subitemsInChannel = entry.value;

        int maxCount = 0;
        for (final displaySubitem in subitemsInChannel) {
          final count = displaySubitem['unreadCount'] as int;
          if (count > maxCount) {
            maxCount = count;
          }
        }
        maxUnreadCountsForChannels[channelKey] = maxCount;
      }

      tempChannelEntries.sort((a, b) {
        final maxA = maxUnreadCountsForChannels[a.key] ?? 0;
        final maxB = maxUnreadCountsForChannels[b.key] ?? 0;
        if (maxA > 0 && maxB > 0) {
          return maxB.compareTo(maxA);
        }
        if (maxA > 0) return -1;
        if (maxB > 0) return 1;
        return a.key.compareTo(b.key);
      });

      if (!mounted) return;

      setState(() {
        _filteredAndSortedMap = Map.fromEntries(tempChannelEntries);
      });

    } catch (e, st) {
      print("❌ Error in _resortFilteredAndSortedMap: $e\n$st");
      if (mounted) {
        print("Live update resort failed. UI might be slightly out of order until next full refresh.");
      }
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    notificationDatabaseChange.removeListener(_handleNotificationDatabaseChange);
    searchController.removeListener(_debounceSearch);
    searchController.dispose();
    _debounceTimer?.cancel();

    _subcollectionUnreadCountNotifiers.forEach((key, notifier) => notifier.dispose());
    _subcollectionUnreadCountNotifiers.clear();

    super.dispose();
  }

  /// Navigates to the details screen for a specific channel sub-item.
  void _navigateToDetails(String channel, String subItemName) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return LiveDetailsScreen(
            mainCollection: "notifications",
            subCollection: channel.trim(),
            subSubCollection: subItemName.trim(),
            showHighlightsButton: false,
            img: "assets/images/home_screen_images/appbar_images/notification.png",
            scrollToDatetimeId: "",
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    _handleNotificationDatabaseChange(); // Trigger update on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            surfaceTintColor: Colors.white,
            backgroundColor: AppColors.background,
            pinned: false,
            elevation: 0,
            toolbarHeight: 50.h,
            title: _buildSearchBar(),
          ),
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          _buildBody(),
          SliverToBoxAdapter(child: SizedBox(height: 50.h)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w400,
        color: AppColors.primaryText,
        fontSize: 12.sp,
      ),
      decoration: InputDecoration(
        hintText: "Search Channels...",
        hintStyle: GoogleFonts.poppins(color: AppColors.secondaryText),
        prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.secondaryText,size: 20,),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _overallNewNotificationPresent
          ? Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () async {
            haptic();
            await DbSqlHelper.markEverythingAsRead();
            _handleNotificationDatabaseChange(); // Trigger update
          },
          icon: Icon(CupertinoIcons.checkmark_seal, size: 16.sp, color: AppColors.secondaryText),
          label: Text(
            "Mark All As Read",
            style: GoogleFonts.poppins(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryText),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return _buildShimmerList();
    }

    if (_filteredAndSortedMap.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.tray, size: 50.sp, color: AppColors.secondaryText),
            SizedBox(height: 16.h),
            Text(
              _currentSearchText.isEmpty ? "No Channels Found" : "No results for '$_currentSearchText'",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _currentSearchText.isEmpty
                  ? "Channels will appear here once they are available."
                  : "Try checking your spelling or searching for something else.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryText),
            ),
            SizedBox(height: 20.h),
            if (_currentSearchText.isEmpty)
              ElevatedButton.icon(
                onPressed: () => _initializeAppLoad(),
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacings.screenPadding),
      sliver: SliverList.builder(
        itemCount: _filteredAndSortedMap.length,
        itemBuilder: (context, index) {
          final String channel = _filteredAndSortedMap.keys.elementAt(index);
          final bool isExpanded = isExpandedMap[channel] ?? true;
          final List<DisplaySubitem> subcollections = _filteredAndSortedMap[channel]!;

          return SuperAnimatedWidget(
            effects: const [AnimationEffect.fade, AnimationEffect.slide],
            child: _ChannelCard(
              channel: channel,
              isExpanded: isExpanded,
              onToggle: () {
                haptic();
                setState(() => isExpandedMap[channel] = !isExpanded);
              },
              subItems: subcollections.map((displaySubitem) {
                final String subItemName = displaySubitem['name'] as String;
                final unreadNotifier = _subcollectionUnreadCountNotifiers[subItemName];
                return _SubItemTile(
                  subItemName: subItemName,
                  unreadNotifier: unreadNotifier ?? ValueNotifier(0),
                  onTap: () => _navigateToDetails(channel, subItemName),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacings.screenPadding),
      sliver: SliverToBoxAdapter(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListView.builder(
            itemCount: 5, // Increased count for better visual
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => const _ShimmerPlaceholderCard(),
          ),
        ),
      ),
    );
  }
}

/// A card representing a single channel and its sub-items.
class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.isExpanded,
    required this.onToggle,
    required this.subItems,
  });

  final String channel;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> subItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacings.itemSpacing),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Bounceable(
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.all(AppSpacings.cardPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      channel,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(height: 1, color: AppColors.borderColor),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: subItems),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// A tile for a sub-item within a channel card.
class _SubItemTile extends StatelessWidget {
  const _SubItemTile({
    required this.subItemName,
    required this.unreadNotifier,
    required this.onTap,
  });

  final String subItemName;
  final ValueNotifier<int> unreadNotifier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Bounceable(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subItemName.trim(),
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<int>(
                valueListenable: unreadNotifier,
                builder: (context, unreadCount, _) {
                  return _NotificationBadge(count: unreadCount);
                },
              ),
              SizedBox(width: 8.w),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A visual badge to display the number of unread notifications.
class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink(); // Don't show anything if count is zero
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.notificationBadge,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        count > 99 ? "99+" : count.toString(),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// --- NEW: Shimmer Placeholder Widget based on your example ---
class _ShimmerPlaceholderCard extends StatelessWidget {
  const _ShimmerPlaceholderCard();

  Widget _buildPlaceholderLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // This must be a solid color for shimmer to work
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacings.itemSpacing),
      padding: EdgeInsets.all(AppSpacings.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card, // This is the background of the card itself
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlaceholderLine(width: double.infinity, height: 22.h),
          SizedBox(height: 16.h),
          _buildPlaceholderLine(width: 200.w, height: 16.h),
          SizedBox(height: 8.h),
          _buildPlaceholderLine(width: 150.w, height: 16.h),
        ],
      ),
    );
  }
}