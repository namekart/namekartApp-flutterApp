import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:text_scroll/text_scroll.dart';
import '../../activity_helpers/DbAccountHelper.dart';
import '../../activity_helpers/DbSqlHelper.dart';
import '../../activity_helpers/GlobalFunctions.dart';
import '../../activity_helpers/UIHelpers.dart';
import '../../custom_widget/_HashtagInputWidgetState.dart';
import '../features/BiddingListAndWatchListScreen.dart';
import '../features/BulkBid.dart';
import '../features/BulkFetch.dart';
import '../live_screens/live_details_screen.dart';

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return "";
    }
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _textEditingController = TextEditingController();
  Timer? _debounceTimer;

  // Data
  final Map<String, dynamic> _allDocumentsData = {};
  final Map<String, List<String>> _documentKeywords = {};
  List<String> _filteredDocuments = [];
  final Map<String, dynamic> _filteredDocumentsData = {};

  List<String> _allAvailableData = [];
  List<String> _filteredAvailableData = [];
  List<List<String>> _filteredAuctionTools = [];
  final List<List<String>> _auctionsTools = [
    ["Watch List", "watchlist"],
    ["Bidding List", "biddinglist"],
    ["Bulk Bid", "bulkbid"],
    ["Bulk Fetch", "bulkfetch"],
  ];

  // State
  bool _isLoading = true;
  String _query = "";
  int _currentPage = 0;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _initializeData();
    _textEditingController.addListener(_onSearchChanged);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300 &&
        !_isFetchingMore) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _search();
    });
  }

  Future<void> _initializeData() async {
    await _buildSearchIndexInBackground();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buildSearchIndexInBackground() async {
    _allAvailableData = await DbSqlHelper.getCategoryPathsOnly();
    _filteredAvailableData = List.from(_allAvailableData);
    _filteredAuctionTools = List.from(_auctionsTools);

    List<String> paths = await DbSqlHelper.getAllAvailablePaths();

    for (String path in paths) {
      try {
        var data = await DbSqlHelper.read(path);
        if (data != null) {
          var timestampKey = data.keys.first;
          var innerData = data[timestampKey];
          _allDocumentsData[path] = innerData;
          _documentKeywords[path] = _extractSearchableStrings(data,
              excludedKeys: ["uibuttons", "device_notification", "actionsDone"]);
        }
      } catch (e) {
        debugPrint("Failed to index $path: $e");
      }
    }
    _loadMore(); // Load initial page
  }

  List<String> _extractSearchableStrings(dynamic data,
      {List<String> excludedKeys = const []}) {
    List<String> result = [];
    final normalizedExcludedKeys =
    excludedKeys.map((k) => k.toLowerCase()).toSet();

    if (data is Map) {
      data.forEach((key, value) {
        if (normalizedExcludedKeys.contains(key.toString().toLowerCase())) return;
        if (value is String || value is num || value is bool) {
          result.add(value.toString().toLowerCase());
        }
        if (value is Map || value is List) {
          result.addAll(
              _extractSearchableStrings(value, excludedKeys: excludedKeys));
        }
      });
    } else if (data is List) {
      for (var item in data) {
        result.addAll(
            _extractSearchableStrings(item, excludedKeys: excludedKeys));
      }
    } else if (data != null) {
      result.add(data.toString().toLowerCase());
    }
    return result;
  }

  void _loadMore() {
    if (_isFetchingMore) return;
    if (mounted) setState(() => _isFetchingMore = true);

    List<String> sourceKeys;
    if (_query.isEmpty) {
      sourceKeys = _allDocumentsData.keys.toList();
    } else {
      sourceKeys = [];
      _allDocumentsData.forEach((path, data) {
        List<String> keywords = _documentKeywords[path] ?? [];
        if (path.toLowerCase().contains(_query) ||
            keywords.any((k) => k.contains(_query))) {
          sourceKeys.add(path);
        }
      });
    }

    final startIndex = _currentPage * _pageSize;
    if (startIndex >= sourceKeys.length) {
      if (mounted) setState(() => _isFetchingMore = false);
      return;
    }

    final endIndex = (startIndex + _pageSize > sourceKeys.length)
        ? sourceKeys.length
        : startIndex + _pageSize;
    final newItems = sourceKeys.sublist(startIndex, endIndex);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _filteredDocuments.addAll(newItems);
          for (var path in newItems) {
            _filteredDocumentsData[path] = _allDocumentsData[path];
          }
          _currentPage++;
          _isFetchingMore = false;
        });
      }
    });
  }

  void _search() {
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        _query = _textEditingController.text.trim().toLowerCase();
        _currentPage = 0;
        _filteredDocuments.clear();
        _filteredDocumentsData.clear();
        _isLoading = true; // Show loader while filtering

        _filteredAvailableData = _allAvailableData
            .where((item) => item.toLowerCase().contains(_query))
            .toList();

        _filteredAuctionTools = _auctionsTools
            .where((item) => item[0].toLowerCase().contains(_query))
            .toList();
      });
    }
    // Let the loading indicator show for a moment for smoother UX
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _loadMore();
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0F2F5), // Match LiveDetailsScreen background
      appBar: AppBar(backgroundColor: Colors.white,toolbarHeight: 0,),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildSliverAppBar(),
            _isLoading && _currentPage == 0
                ? const SliverFillRemaining(
              child: Center(
                  child: CupertinoActivityIndicator(radius: 15)),
            )
                : _buildSliverContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.white,
      pinned: true,
      floating: true,
      elevation: 1, // Subtle elevation
      shadowColor: Colors.black12,
      titleSpacing: 0,
      toolbarHeight: 70.h,
      title: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: CupertinoSearchTextField(
                controller: _textEditingController,
                placeholder: 'Search domains, tools, and more...',
                style: GoogleFonts.poppins(
                  color: const Color(0xff333333),
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
                backgroundColor: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12.r),
                prefixInsets: const EdgeInsets.only(left: 14),
                suffixInsets: const EdgeInsets.only(right: 14),
                onSuffixTap: () {
                  _textEditingController.clear();
                  _search();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverContent() {
    // --- Partition documents into 'alerted' and 'regular' ---
    final List<String> alertedDocumentPaths = [];
    final List<String> regularDocumentPaths = [];

    for (final path in _filteredDocuments) {
      final data = _filteredDocumentsData[path];
      if (data != null) {
        final bool hasAlert = (data['device_notification']?.toString() ?? '').contains("ringAlarm: true");
        if (hasAlert) {
          alertedDocumentPaths.add(path);
        } else {
          regularDocumentPaths.add(path);
        }
      }
    }

    bool hasNoResults = _filteredAuctionTools.isEmpty &&
        _filteredAvailableData.isEmpty &&
        alertedDocumentPaths.isEmpty &&
        regularDocumentPaths.isEmpty;

    if (hasNoResults && _query.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.search_circle,
                  size: 60, color: Colors.grey.shade300),
              SizedBox(height: 16.h),
              Text(
                "No Results Found",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Try a different search term.",
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- Build the list of widgets in the desired order ---
    List<Widget> contentWidgets = [];

    // 1. Notifications
    if (alertedDocumentPaths.isNotEmpty) {
      contentWidgets.add(const _SectionHeader(title: "Notifications"));
      contentWidgets.addAll(alertedDocumentPaths.map((path) => DocumentPreviewCard(
        data: _filteredDocumentsData[path]!,
        path: path,
      )));
    }

    // 2. Auction Tools
    if (_filteredAuctionTools.isNotEmpty) {
      contentWidgets.add(_ToolsCard(tools: _filteredAuctionTools));
    }

    // 3. Categorized Results
    if (_filteredAvailableData.isNotEmpty) {
      contentWidgets.addAll(_buildCategorizedResults(_filteredAvailableData));
    }

    // 4. Matching Documents
    if (regularDocumentPaths.isNotEmpty) {
      contentWidgets.add(const _SectionHeader(title: "Matching Documents"));
      contentWidgets.addAll(regularDocumentPaths.map((path) => DocumentPreviewCard(
        data: _filteredDocumentsData[path]!,
        path: path,
      )));
    }

    // 5. Loading Indicator
    if (_isFetchingMore) {
      contentWidgets.add(
        const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CupertinoActivityIndicator()),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 200),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: contentWidgets[index],
              ),
            ),
          );
        },
        childCount: contentWidgets.length,
      ),
    );
  }

  List<Widget> _buildCategorizedResults(List<String> input) {
    Map<String, Map<String, Set<String>>> categoryMap = {};
    for (var item in input) {
      if (item.contains("account~user")) continue;
      try {
        List<String> parts = item.split('~');
        if (parts.length < 3) continue;
        String category = parts[0];
        String subCategory = parts[1];
        String subItem = parts[2];
        categoryMap.putIfAbsent(category, () => {});
        categoryMap[category]!.putIfAbsent(subCategory, () => {});
        categoryMap[category]![subCategory]!.add(subItem);
      } catch (e) {
        continue;
      }
    }

    List<Widget> categorizedWidgets = [];
    categoryMap.forEach((category, subCategories) {
      categorizedWidgets.add(
        _SectionHeader(title: category.capitalize()),
      );
      subCategories.forEach((subCategoryName, items) {
        categorizedWidgets.add(_CategoryCard(
          category: category,
          subCategory: subCategoryName,
          items: items.toList(),
        ));
      });
    });

    return categorizedWidgets;
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_onSearchChanged);
    _textEditingController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}

// --- UI Components --- //

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 12.h),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1D1D1F),
        ),
      ),
    );
  }
}

class _ToolsCard extends StatelessWidget {
  final List<List<String>> tools;
  const _ToolsCard({required this.tools});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: "Auction Tools"),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Card(
            elevation: 0,
            color: const Color(0xFFF7F9FC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: tools.map((item) {
                  return Bounceable(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Navigation logic remains the same
                      switch (item[1]) {
                        case "watchlist":
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => BiddingListAndWatchListScreen(api: "/getWatchList")));
                          break;
                        case "biddinglist":
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => BiddingListAndWatchListScreen(api: "/getBiddingList")));
                          break;
                        case "bulkbid":
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => const BulkBid()));
                          break;
                        case "bulkfetch":
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => const BulkFetch()));
                          break;
                      }
                    },
                    child: _buildActionItem(item[0], item[1]),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(String label, String iconPath) {
    print(iconPath);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        getIconForButton(iconPath, 24),
        SizedBox(height: 10.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xff333333),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final String subCategory;
  final List<String> items;

  const _CategoryCard({
    required this.category,
    required this.subCategory,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  getIconForButton(subCategory, 24),
                  SizedBox(width: 12.w),
                  Text(
                    subCategory.capitalize(),
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff222222),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Divider(color: Colors.grey.shade200, height: 1),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: items.map((item) {
                  return ActionChip(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Navigation logic remains the same
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => LiveDetailsScreen(
                            mainCollection: category,
                            subCollection: subCategory,
                            subSubCollection: item,
                            showHighlightsButton: category.contains("live"),
                            img: (subCategory == "godaddy" ||
                                subCategory == "dropcatch" ||
                                subCategory == "dynadot" ||
                                subCategory == "namecheap" ||
                                subCategory == "namesilo")
                                ? "assets/images/home_screen_images/livelogos/$subCategory.png"
                                : "assets/images/home_screen_images/appbar_images/notification.png",
                            scrollToDatetimeId: "",
                          ),
                        ),
                      );
                    },
                    label: Text(item.capitalize()),
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.deepPurple,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                    padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// NEW DOCUMENT PREVIEW CARD - ADAPTED FROM LIVEDETAILSSCREEN
// ===================================================================

class DocumentPreviewCard extends StatelessWidget {
   final Map<dynamic, dynamic> data;
   final String path;

  const DocumentPreviewCard({required this.data, required this.path});

  @override
  Widget build(BuildContext context) {
    if(data.isNotEmpty) {
      var auctionItem = data as Map<dynamic, dynamic>? ?? {};
      var auctionsItemData = data['data'] as Map<dynamic, dynamic>? ?? {};
      var uiButtons = data['uiButtons'] as List<dynamic>?;
      var appBarTitle = path;

      return Bounceable(
        onTap: (){
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => LiveDetailsScreen(
                    mainCollection: path.split("~")[0],
                    subCollection: path.split("~")[1],
                    subSubCollection: path.split("~")[2],
                    showHighlightsButton: path.split("~")[1].contains("live"),
                    img:path.split("~")[2]=="Live-DC" ? "assets/images/home_screen_images/livelogos/dropcatch.png"
                        : path.split("~")[2]=="Live-DD" ? "assets/images/home_screen_images/livelogos/dynadot.png"
                        : path.split("~")[2]=="Live-SAV" ? "assets/images/home_screen_images/livelogos/sav.png"
                        : path.split("~")[2]=="Live-GD" ? "assets/images/home_screen_images/livelogos/godaddy.png"
                        : path.split("~")[2]=="Live-NC" ? "assets/images/home_screen_images/livelogos/namecheap.png"
                        : path.split("~")[2]=="Live-NS" ? "assets/images/home_screen_images/livelogos/namesilo.png":
                    "assets/images/home_screen_images/appbar_images/notification.png",
                    scrollToDatetimeId: auctionItem['datetime_id'],
                  )));
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
        
                    Expanded(
                      child: Text(
                        auctionsItemData['h1'] ?? 'No Title',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    FutureBuilder<bool>(
                      future: DbAccountHelper.isStarred(
                        "account~user~details",
                        GlobalProviders.userId,
                        path,
                        auctionItem['datetime_id'],
                      ),
                      builder: (context, snapshot) {
                        return buildStarToggleButton(
                          isStarred: snapshot.data ?? false,
                          onStarredClicked: () {},
                          onNotStarredClicked: () {},
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
        
                if (appBarTitle.contains("Highlights"))
                  _buildHighlightsTable(auctionsItemData),
                if (!appBarTitle.contains("Highlights"))
                  _buildDetailsWrap(auctionsItemData),
        
                SizedBox(height: 16.h),
        
                /// CHANGE 2: The Wrap widget is replaced by GridView.count for a 3-column grid.
                if (uiButtons != null && uiButtons.isNotEmpty)
                  GridView.count(
                    crossAxisCount: 3,
                    // Defines 3 columns
                    shrinkWrap: true,
                    // Needed to embed a grid in a scrollable list
                    physics: const NeverScrollableScrollPhysics(),
                    // Delegate scrolling to the parent list
                    crossAxisSpacing: 8,
                    // Horizontal space between buttons
                    mainAxisSpacing: 8,
                    // Vertical space between buttons
                    childAspectRatio: 2.5,
                    // Adjust for desired button proportions (width/height)
                    children: uiButtons
                        .map((buttonData) =>
                        _buildActionButton(context, auctionItem, buttonData))
                        .toList(),
                  ),
        
                Divider(color: Colors.grey.shade200),
        
                AbsorbPointer(
                  child: createHashtagAndNotesInputWidget(
                    initialHashtags: (auctionItem['hashtags'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ?? [],
                    initialNotes: (auctionItem['notes'] as List?)?.map((e) =>
                    (e as Map?)?.map((k, v) =>
                        MapEntry(k.toString(), v.toString()),) ?? {}).toList() ?? [],
                    notesAuthorName: GlobalProviders.userId,
                    onHashtagsChanged: (newHashtags) {},
                    onNotesChanged: (newNotes) {},
                  ),
                ),
                SizedBox(height: 8.h),
        
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formatToIST(auctionItem['datetime_id']),
                      style: GoogleFonts.poppins(
                        fontSize: 8.sp,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }else{
      return Container();
    }
  }

  // Helper to build the details table with the new style
  Widget _buildSearchDetailsTable(Map<dynamic, dynamic> data) {
    return Table(
      columnWidths: const { 0: FlexColumnWidth(), 1: FlexColumnWidth(), 2: FlexColumnWidth() },
      children: data.entries
          .where((entry) => entry.key != 'h1')
          .map((entry) {
        List<String> items = entry.value.toString().split('|').map((e) => e.trim()).toList();
        while (items.length < 3) items.add('–'); // Use en dash for empty cells
        items = items.sublist(0, 3);
        return TableRow(
          children: items.map((item) => Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                item,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 8.sp,
                    color: const Color(0xff616161),
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )).toList(),
        );
      }).toList(),
    );
  }

  // Helper for status indicators like in the old card
  Widget _buildStatusIndicator(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
        ),
      ),
    );
  }

  // Helper for rendering action buttons (visual only)
  Widget _buildSearchActionButton(BuildContext context, Map<dynamic, dynamic> buttonData) {
    final button = buttonData.values.first as Map<dynamic, dynamic>;
    final buttonText = button['button_text'] as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(Color(0xff555555), BlendMode.srcIn),
            child: getIconForButton(buttonText, 18),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              buttonText,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.poppins(
                  color: const Color(0xff555555),
                  fontWeight: FontWeight.w600,
                  fontSize: 8.sp),
            ),
          ),
        ],
      ),
    );
  }


  Widget buildStarToggleButton({
    required bool isStarred,
    required VoidCallback onStarredClicked,
    required VoidCallback onNotStarredClicked,
    double iconSize = 26.0,
  }) {
    return GestureDetector(
      onTap: () {
        if (isStarred) {
          onNotStarredClicked();
        } else {
          onStarredClicked();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(child: child, scale: animation);
        },
        child: Icon(
          isStarred ? Icons.star_rounded : Icons.star_border_rounded,
          key: ValueKey<bool>(isStarred),
          size: iconSize,
          color: isStarred ? Colors.amber[600] : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildHighlightsTable(Map<dynamic, dynamic> data) {
    return Table(
      columnWidths: const { 0: FlexColumnWidth(), 1: FlexColumnWidth(), 2: FlexColumnWidth() },
      children: data.entries
          .where((entry) => entry.key != 'h1')
          .map((entry) {
        List<String> items = entry.value.toString().split('|').map((e) => e.trim()).toList();
        while (items.length < 3) items.add('');
        items = items.sublist(0, 3);
        return TableRow(
          children: items.map((item) => Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                item,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 8.sp,
                    color: Color(0xff616161),
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )).toList(),
        );
      }).toList(),
    );
  }


  Widget _buildActionButton(BuildContext context, Map<dynamic, dynamic> auctionItem, Map<dynamic, dynamic> buttonData) {
    final button = buttonData.values.first as Map<dynamic, dynamic>;
    final buttonText = button['button_text'] as String;
    final buttonKey = "${auctionItem['id']} + ${buttonData.keys.toList()[0]}";
    final actionDoneList = auctionItem['actionsDone'] as List<dynamic>? ?? [];

    bool isWatched = actionDoneList.toString().contains("Watch") && buttonText.contains("Watch");
    String displayText = isWatched ? "Remove Watch" : buttonText;

    return Container(
      decoration: BoxDecoration(
        color: isWatched ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                isWatched ? Colors.blue : Color(0xff555555),
                BlendMode.srcIn),
            child: getIconForButton(
                isWatched ? "remove watch" : buttonText, 18),
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              displayText,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.poppins(
                  color: isWatched ? Colors.blue : Color(0xff555555),
                  fontWeight: FontWeight.w600,
                  fontSize: 8.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsWrap(Map<dynamic, dynamic> data) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        data['h2'], data['h3'], data['h4'], data['h5'], data['h6'], data['h7'], data['h8'], data['h9'], data['h10'],
      ]
          .where((value) => value != null)
          .join(' | ')
          .split('|')
          .map((item) => Container(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade200)
        ),
        child: Text(
            item.trim(),
            style: GoogleFonts.poppins(
                fontSize: 8.sp,
                color: Color(0xff717171),
                fontWeight: FontWeight.w600)),
      ))
          .toList(),
    );
  }


}