import 'dart:async';
import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/cutsom_widget/SuperAnimatedWidget.dart';
import 'package:namekart_app/database/HiveHelper.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../activity_helpers/UIHelpers.dart';
import '../features/BiddingList.dart';
import '../features/BulkBid.dart';
import '../features/BulkFetch.dart';
import '../features/WatchList.dart';
import '../live_screens/live_details_screen.dart';

class Search extends StatefulWidget {
  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController textEditingController = TextEditingController();
  Timer? _debounceTimer;

  // Paginated data structures
  final Map<String, dynamic> allDocumentsData = {};
  final Map<String, List<String>> documentKeywords = {};
  List<String> filteredAvailableData = [];
  List<List<String>> filteredAuctionTools = [];
  List<String> filteredDocuments = [];
  final Map<String, dynamic> filteredDocumentsData = {};

  List<String> allAvailableData = [];
  final List<List<String>> auctionsTools = [
    ["Watch List", "watchlist"],
    ["Bidding List", "biddinglist"],
    ["Bulk Bid", "bulkbid"],
    ["Bulk Fetch", "bulkfetch"],
  ];

  bool isLoading = true;
  String query = "";
  int _currentPage = 0;
  final int _pageSize = 20; // Number of items per page
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    Future.delayed(const Duration(milliseconds: 500), _initializeData);
    haptic();
    textEditingController.addListener(_onSearchChanged);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      search();
    });
  }

  Future<void> _initializeData() async {
    if (await buildSearchIndexInBackground()) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> buildSearchIndexInBackground() async {
    allAvailableData = HiveHelper.getCategoryPathsOnly();
    filteredAvailableData = List.from(allAvailableData);
    filteredAuctionTools = List.from(auctionsTools);

    List<String> paths = HiveHelper.getAllAvailablePaths();
    for (String path in paths) {
      try {
        var data = HiveHelper.read(path);
        allDocumentsData[path] = data;
        documentKeywords[path] = extractSearchableStrings(data, excludedKeys: ["uibuttons", "device_notification", "actionsDone"]);
      } catch (e) {
        print("Failed to index $path: $e");
      }
    }

    // Initialize with first page
    filteredDocuments = allDocumentsData.keys.take(_pageSize).toList();
    for (var path in filteredDocuments) {
      filteredDocumentsData[path] = allDocumentsData[path];
    }

    return true;
  }

  List<String> extractSearchableStrings(dynamic data, {List<String> excludedKeys = const []}) {
    List<String> result = [];
    final normalizedExcludedKeys = excludedKeys.map((k) => k.toLowerCase()).toSet();

    if (data is Map) {
      data.forEach((key, value) {
        if (normalizedExcludedKeys.contains(key.toString().toLowerCase())) return;
        if (value is String || value is num || value is bool) {
          result.add(value.toString().toLowerCase());
        }
        if (value is Map || value is List) {
          result.addAll(extractSearchableStrings(value, excludedKeys: excludedKeys));
        }
      });
    } else if (data is List) {
      for (var item in data) {
        result.addAll(extractSearchableStrings(item, excludedKeys: excludedKeys));
      }
    } else if (data != null) {
      result.add(data.toString().toLowerCase());
    }

    return result;
  }

  void _loadMore() {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    final newItems = allDocumentsData.keys.skip(startIndex).take(_pageSize).toList();

    if (newItems.isNotEmpty) {
      setState(() {
        filteredDocuments.addAll(newItems);
        for (var path in newItems) {
          filteredDocumentsData[path] = allDocumentsData[path];
        }
        _currentPage++;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void search() {
    query = textEditingController.text.trim().toLowerCase();
    _currentPage = 0;
    filteredDocuments.clear();
    filteredDocumentsData.clear();

    setState(() {
      isLoading = true;

      filteredAvailableData = allAvailableData
          .where((item) => item.toLowerCase().contains(query))
          .toList();

      filteredAuctionTools = auctionsTools
          .where((item) => item[0].toLowerCase().contains(query))
          .toList();

      allDocumentsData.forEach((path, data) {
        List<String> keywords = documentKeywords[path] ?? [];
        if (path.toLowerCase().contains(query) ||
            keywords.any((k) => k.contains(query))) {
          filteredDocuments.add(path);
          filteredDocumentsData[path] = data;
        }
      });

      filteredDocuments = filteredDocuments.take(_pageSize).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(height: 30.sp),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 0.5,
                          blurRadius: 0.5)
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15, bottom: 1),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xff717171),
                              size: 15,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right:20),
                            child: TextField(
                              controller: textEditingController,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: "Search Here",
                                hintStyle: GoogleFonts.poppins(
                                  color: Color(0xff717171),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 10.sp,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              isLoading && filteredDocuments.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              )
                  : SuperAnimatedWidget(
                effects: const [AnimationEffect.fade],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (filteredAuctionTools.isEmpty &&
                        filteredDocumentsData.isEmpty &&
                        filteredAvailableData.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 10),
                        child: Text(
                          "No Data Found!",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    if (filteredAvailableData.isNotEmpty)
                      buildSimpleCategoryUI(filteredAvailableData),
                    if (filteredAuctionTools.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 25),
                        child: Text(
                          "Auctions Tools",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:Color(0xff717171),
                          ),
                        ),
                      ),
                    if (filteredAuctionTools.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: filteredAuctionTools.map<Widget>((item) {
                            return Bounceable(
                              onTap: () {
                                switch (item[1]) {
                                  case "watchlist":
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => WatchList()),
                                    );
                                    break;
                                  case "biddinglist":
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => BiddingList()),
                                    );
                                    break;
                                  case "bulkbid":
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => BulkBid()),
                                    );
                                    break;
                                  case "bulkfetch":
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => BulkFetch()),
                                    );
                                    break;
                                }
                              },
                              child: _buildActionItem(item[0], item[1], 20, 8),
                            );
                          }).toList(),
                        ),
                      ),
                    if (filteredDocuments.isNotEmpty && query.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDocuments.length + (isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filteredDocuments.length) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final entry = MapEntry(
                            filteredDocuments[index],
                            filteredDocumentsData[filteredDocuments[index]],
                          );
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width-30,
                                  child: TextScroll(
                                    entry.key,
                                    pauseBetween: Duration(seconds: 2),
                                    selectable: true,
                                    velocity: Velocity(pixelsPerSecond: Offset(10, 10)),
                                    style:GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xff717171),
                                    )
                                  ),
                                ),
                                buildPreview(entry.value, entry.key, entry.key),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(String label, String iconPath, double iconSize, double fontSize) {
    return Column(
      children: [
        const SizedBox(height: 2),
        getIconForButton(iconPath, iconSize),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.bold,
            color: Color(0xff717171),
            fontSize: fontSize.sp,
          ),
        ),
      ],
    );
  }

  Widget buildSimpleCategoryUI(List<String> input) {
    Map<String, Map<String, Set<String>>> categoryMap = {};
    for (var item in input) {
      if(item.contains("account~user"))continue;
      try {
        List<String> parts = item.split('~');
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categoryMap.length,
      itemBuilder: (context, index) {
        final category = categoryMap.keys.elementAt(index);
        final subCategories = categoryMap[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 20),
              child: text(
                text: category.capitalize(),
                  fontWeight: FontWeight.bold,
                  color: Color(0xff717171),
                size: 12,
              ),
            ),
            ...subCategories.entries.map<Widget>((entry) {
              String subCategoryName = entry.key;
              List<String> items = entry.value.toList();
              return Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 8,bottom: 8),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20),bottomLeft: Radius.circular(20)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 0.5,
                          blurRadius: 0.5)
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: 100,
                                child: _buildActionItem(
                                  subCategoryName.capitalize(),
                                  subCategoryName,
                                  20,
                                  8,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_right_alt_sharp,color: Color(0xff717171)),
                            const SizedBox(width: 10),
                            Row(
                              children: items.map<Widget>((item) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) {
                                            return LiveDetailsScreen(
                                              mainCollection: category,
                                              subCollection: subCategoryName,
                                              subSubCollection: item,
                                              showHighlightsButton: category.contains("live"),
                                              img: (subCategoryName == "godaddy" ||
                                                  subCategoryName == "dropcatch" ||
                                                  subCategoryName == "dynadot" ||
                                                  subCategoryName == "namecheap" ||
                                                  subCategoryName == "namesilo")
                                                  ? "assets/images/home_screen_images/livelogos/$subCategoryName.png"
                                                  : "assets/images/home_screen_images/appbar_images/notification.png",
                                            );
                                          },
                                        ),
                                      );
                                    },

                                    style: ButtonStyle(
                                      padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
                                      backgroundColor: const WidgetStatePropertyAll(Colors.white),

                                      textStyle: WidgetStateProperty.all(
                                        GoogleFonts.poppins(
                                          color: Color(0xff717171),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      
                                      elevation: WidgetStatePropertyAll(1)
                                    ),
                                    child: text(
                                      text: item,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff717171),
                                        size: 8,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    textEditingController.removeListener(_onSearchChanged);
    textEditingController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}

Widget buildPreview(Map<dynamic, dynamic> filteredDocumentData, String hiveDatabasePath, String appBarTitle) {
  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      var data = filteredDocumentData['data'] as Map<dynamic, dynamic>? ?? {};
      var uiButtons = filteredDocumentData['uiButtons'];
      List<dynamic>? buttons;
      var actionDoneList = filteredDocumentData['actionsDone'];
      bool ringStatus = false;
      try {
        var ringStatusString = filteredDocumentData['device_notification']?.toString() ?? '';
        ringStatus = ringStatusString.contains("ringAlarm: true");
      } catch (e) {}
      String readStatus = filteredDocumentData['read']?.toString() ?? 'no';
      if (uiButtons is List && uiButtons.isNotEmpty) {
        buttons = uiButtons;
      }
      var itemId = filteredDocumentData['id']?.toString() ?? '';
      var path = filteredDocumentData['path']?.toString() ?? '';
      return VisibilityDetector(
        key: Key('document-item-$itemId'),
        onVisibilityChanged: (info) async {
          if (info.visibleFraction > 0.9 && readStatus == 'no') {
            await HiveHelper.markAsRead(path);
            setState(() {});
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: ringStatus
                          ? const BorderSide(color: Colors.redAccent, width: 2)
                          : const BorderSide(color: Colors.transparent, width: 0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              text(
                                text: data['h1'] ?? 'No Title',
                                size: 10.sp,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff3F3F41),
                              ),
                              Row(
                                children: [
                                  if (readStatus == "no")
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(
                                          right: 18.0),
                                      child: Container(
                                        decoration:
                                        const BoxDecoration(
                                          color:
                                          Color(0xff4CAF50),
                                          shape:
                                          BoxShape.circle,
                                        ),
                                        padding:
                                        const EdgeInsets
                                            .all(3),
                                      ),
                                    ),
                                  if (appBarTitle
                                      .contains("Highlights"))
                                    GestureDetector(
                                        onTap: () {
                                          haptic();
                                          TextEditingController
                                          _inputTextFieldController =
                                          new TextEditingController();
                                          showDialog(
                                              context: context,
                                              // Provide the context
                                              builder:
                                                  (BuildContext
                                              context) {
                                                return AlertDialog(
                                                    contentPadding:
                                                    const EdgeInsets
                                                        .all(
                                                        0),
                                                    backgroundColor:
                                                    Color(
                                                        0xffF5F5F5),
                                                    content: Container(
                                                        width: MediaQuery.of(context).size.width,
                                                        height: 200.sp,
                                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                          AppBar(
                                                            title:
                                                            Text(
                                                              "Enter First Row Value To Sort",
                                                              style: GoogleFonts.poppins(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                                            ),
                                                            backgroundColor:
                                                            Color(0xffB71C1C),
                                                            iconTheme:
                                                            IconThemeData(size: 20, color: Colors.white),
                                                            titleSpacing:
                                                            0,
                                                            shape:
                                                            const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                                                          ),
                                                          Container(
                                                            child:
                                                            Padding(
                                                              padding: const EdgeInsets.all(20),
                                                              child: Container(
                                                                height: 50.sp,
                                                                alignment: Alignment.centerLeft,
                                                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
                                                                child: TextField(
                                                                  controller: _inputTextFieldController,
                                                                  style: GoogleFonts.poppins(
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.black45,
                                                                    fontSize: 12.sp,
                                                                  ),
                                                                  decoration: InputDecoration(labelText: 'i.e Age 6 or modoo.blog or price 10', border: InputBorder.none, labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black45, fontSize: 8.sp), prefixIcon: Icon(Icons.keyboard), prefixIconColor: Color(0xffB71C1C)),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets.only(right: 20),
                                                            child:
                                                            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                                              Container(
                                                                decoration: const BoxDecoration(
                                                                  color: Color(0xffE7E7E7),
                                                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                                                ),
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(10),
                                                                  child: Text("Sort", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                                                                ),
                                                              ),
                                                            ]),
                                                          ),
                                                        ])));
                                              });
                                        },
                                        child: const Icon(
                                          Icons
                                              .compare_arrows_outlined,
                                          size: 18,
                                        ))
                                ],
                              )
                            ],
                          ),
                          SizedBox(height: 5.h),
                          if (appBarTitle.contains("highlights"))
                            Table(
                              columnWidths: const {
                                0: FixedColumnWidth(80),
                                1: FlexColumnWidth(),
                                2: FixedColumnWidth(80),
                              },
                              children: data.entries
                                  .where((entry) => entry.key != 'h1')
                                  .map((entry) {
                                List<String> items =
                                entry.value.toString().split('|').map((e) => e.trim()).toList();
                                if (items.length < 3) {
                                  items.addAll(List.filled(3 - items.length, ''));
                                } else if (items.length > 3) {
                                  items = items.sublist(0, 3);
                                }
                                return TableRow(
                                  children: items
                                      .map(
                                        (item) => Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.h),
                                      child: Center(
                                        child: TextScroll(
                                          item,
                                          velocity: const Velocity(pixelsPerSecond: Offset(10, 10)),
                                          style: GoogleFonts.poppins(
                                            fontSize: 10.sp,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                      .toList(),
                                );
                              }).toList(),
                            ),
                          if (!appBarTitle.contains("highlights"))
                            Table(
                              columnWidths: const {
                                0: FixedColumnWidth(80),
                                1: FlexColumnWidth(),
                                2: FixedColumnWidth(80),
                              },
                              children: data.entries
                                  .where((entry) =>
                              entry.key != 'h1')
                                  .map(
                                    (entry) {
                                  List<String> items = entry
                                      .value
                                      .toString()
                                      .split('|')
                                      .map((e) => e.trim())
                                      .toList();

                                  // Ensure the list has exactly 3 items
                                  if (items.length < 3) {
                                    items.addAll(List.filled(
                                        3 - items.length, ''));
                                  } else if (items.length > 3) {
                                    items = items.sublist(0, 3);
                                  }

                                  return TableRow(
                                    children: items
                                        .map(
                                          (item) => Padding(
                                        padding:
                                        const EdgeInsets
                                            .all(3),
                                        child: Container(
                                          padding: EdgeInsets
                                              .symmetric(
                                              vertical:
                                              6.h,
                                              horizontal:
                                              10.w),
                                          decoration:
                                          BoxDecoration(
                                            color: Colors
                                                .white,
                                            borderRadius:
                                            BorderRadius
                                                .circular(
                                                8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors
                                                    .grey
                                                    .shade300,
                                                blurRadius:
                                                0.5,
                                              ),
                                            ],
                                          ),
                                          alignment:
                                          Alignment
                                              .center,
                                          child: TextScroll(
                                            item,
                                            velocity: Velocity(
                                                pixelsPerSecond:
                                                Offset(
                                                    10,
                                                    10)),
                                            style: GoogleFonts.poppins(
                                                fontSize:
                                                7.sp,
                                                color: Color(
                                                    0xff717171),
                                                fontWeight:
                                                FontWeight
                                                    .w400),
                                          ),
                                        ),
                                      ),
                                    )
                                        .toList(),
                                  );
                                },
                              ).toList(),
                            ),

                          const SizedBox(height: 10),
                          if (buttons != null)
                            Container(
                              alignment:
                              AlignmentDirectional.center,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 20.0,
                                runSpacing: 5,
                                children:
                                buttons.map((buttonData) {
                                  final button = buttonData
                                      .values.first
                                  as Map<dynamic, dynamic>;
                                  final buttonText =
                                  button['button_text']
                                  as String;

                                  return Padding(
                                    padding:
                                    const EdgeInsets.all(
                                        5),
                                    child: Column(
                                      children: [
                                          Column(
                                            children: [
                                              ColorFiltered(
                                                colorFilter: ColorFilter.mode(
                                                    Color(
                                                        0xff717171),
                                                    BlendMode
                                                        .srcIn),
                                                child: getIconForButton(
                                                    buttonText,
                                                    15),
                                              ),
                                              SizedBox(
                                                  height: 10),
                                              text(
                                                text:
                                                buttonText,
                                                color: Color(
                                                    0xff717171),
                                                fontWeight:
                                                FontWeight
                                                    .w300,
                                                size: 7.sp,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.end,
                            children: [
                              text(
                                text:  filteredDocumentData['datetime']?.toString() ?? '',
                                size: 6,
                                color: Color(0xff717171),
                                fontWeight: FontWeight.w300,
                              ),
                            ],
                          ),
                          if (actionDoneList != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Wrap(
                                  alignment: WrapAlignment.start,
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: (actionDoneList
                                  as List<dynamic>)
                                      .map<Widget>((actionDone) {
                                    return Container(
                                      width: 70.sp,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors
                                                .grey.shade300,
                                            blurRadius: 0.5,
                                          )
                                        ],
                                        borderRadius:
                                        BorderRadius.only(
                                            topLeft: Radius
                                                .circular(10),
                                            bottomRight:
                                            Radius
                                                .circular(
                                                10)),
                                      ),
                                      padding: EdgeInsets.all(10),
                                      alignment: Alignment.center,
                                      child: text(
                                          text: actionDone
                                              .toString(),
                                          size: 7.sp,
                                          color:
                                          Color(0xff717171),
                                          fontWeight:
                                          FontWeight.w400),
                                    );
                                  }).toList()),
                            ),
                        ],
                      ),
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
}