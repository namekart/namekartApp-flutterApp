import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/cutsom_widget/SuperAnimatedWidget.dart';
import 'package:namekart_app/database/HiveHelper.dart';
import 'package:path/path.dart';
import 'package:shimmer/shimmer.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../activity_helpers/FirestoreHelper.dart';
import '../../activity_helpers/GlobalFunctions.dart';
import '../../activity_helpers/UIHelpers.dart';
import '../../change_notifiers/WebSocketService.dart';
import '../../cutsom_widget/LazyExpansionTile.dart';
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

  Map<String, dynamic> allDocumentsData = {}; // Full document content (path -> content)
  Map<String, List<String>> documentKeywords = {}; // For fast searching


  List<String> filteredAvailableData = [];
  List<List<String>> filteredAuctionTools = [];
  List<String> filteredDocuments = [];
  Map<String, dynamic> filteredDocumentsData = {};


  List<String> allAvailableData = [];
  List<String> documentsData = [];
  List<List<String>> auctionsTools = [
    ["Watch List", "watchlist"],
    ["Bidding List", "biddinglist"],
    ["Bulk Bid", "bulkbid"],
    ["Bulk Fetch", "bulkfetch"],
  ];

  bool isLoading=true;

  String query="";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(Duration(milliseconds: 500), () {
      a();
    });
    haptic();
  }

  void a()async{

    if(await buildSearchIndexInBackground()){
      setState(() {
        isLoading=false;
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


        allDocumentsData[path] = data; // Save actual content
        documentKeywords[path] = extractSearchableStrings(data, excludedKeys: ["uibuttons", "device_notification","actionsDone"]);

      } catch (e) {
        print("Failed to index $path: $e");
      }
    }

    // Initially show everything
    filteredDocuments = List.from(allDocumentsData.keys);
    filteredDocumentsData = Map.from(allDocumentsData);

    return true;
  }

  List<String> extractSearchableStrings(dynamic data, {List<String> excludedKeys = const []}) {
    List<String> result = [];

    // Normalize excluded keys to lowercase once
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

  List<List<String>> searchedItem = [];

  void search() {
    query = textEditingController.text.trim().toLowerCase();

    setState(() {

      // Filter available paths
      filteredAvailableData = allAvailableData
          .where((item) => item.toLowerCase().contains(query))
          .toList();

      // Filter auction tools
      filteredAuctionTools = auctionsTools
          .where((item) => item[0].toLowerCase().contains(query))
          .toList();

      // In-memory filtering using preloaded data
      filteredDocuments = [];
      filteredDocumentsData = {};

      allDocumentsData.forEach((path, data) {
        List<String> keywords = documentKeywords[path] ?? [];

        if (path.toLowerCase().contains(query) ||
            keywords.any((k) => k.contains(query))) {
          filteredDocuments.add(path);
          filteredDocumentsData[path] = data;
        }
      });

    });
      isLoading=false;

      setState(() {

      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 30.sp),
                  Padding(
                    padding: const EdgeInsets.only(left:10,right: 10,top: 10),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Color(0xFFB71C1C)),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, bottom: 1),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )),
                            ),
                            Expanded(
                              child: TextField(
                                controller: textEditingController,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "Search Here",
                                  hintStyle: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.sp),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Bounceable(
                                onTap: (){
                                  setState(() {
                                    isLoading=true;
                                  });
                                  search();
                                },
                                child: Image.asset(
                                  "assets/images/home_screen_images/searchwhite.png",
                                  width: 15.0,
                                  height: 15.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  isLoading?
                  const CircularProgressIndicator(padding: EdgeInsets.all(50),):
                  SuperAnimatedWidget(
                    effects: const [AnimationEffect.fade],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (filteredAuctionTools.isEmpty && filteredDocumentsData.isEmpty && filteredAvailableData.isEmpty)
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
                          padding: const EdgeInsets.only(left: 20, top: 10),
                          child: Text(
                            "Auctions Tools",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
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
                                              MaterialPageRoute(
                                                  builder: (context) => WatchList()));
                                          break;
                                        case "biddinglist":
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      BiddingList()));
                                          break;
                                        case "bulkbid":
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => BulkBid()));
                                          break;
                                        case "bulkfetch":
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => BulkFetch()));
                                          break;
                                      }
                                    },
                                    child: Shimmer.fromColors(
                                        baseColor: Colors.black,
                                        highlightColor: Colors.white,
                                        child: _buildActionItem(
                                            item[0], item[1], 20, 8)),
                                  );
                                }).toList()),
                          ),
                        if (filteredDocuments.isNotEmpty && query.isNotEmpty)
                          Column(
                            children: filteredDocumentsData.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                      color: Color(0xfff2f2f2),
                                      borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(entry.key.toString(),style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xff292929),
                                            ),),
                                          )
                                        ],
                                      ),
                                      buildPreview(entry.value,entry.key.toString(),entry.key.toString())
                                    ],
                                  ),
                                ),
                            );
                            }
                          ).toList())
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
      String label, String iconPath, double iconSize, double fontSize) {
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
              color: Colors.black87,
              fontSize: fontSize.sp),
        ),
      ],
    );
  }

  Widget buildSimpleCategoryUI(List<String> input) {
    // Parse input and categorize
    Map<String, Map<String, Set<String>>> categoryMap = {};

    // Organize the input data
    for (var item in input) {
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

    // Build the UI
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: categoryMap.length,
      itemBuilder: (context, index) {
        final category = categoryMap.keys.elementAt(index);
        final subCategories = categoryMap[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title for the category
            if (index > 0)
              SizedBox(
                height: 20,
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 20),
              child: Text(
                category.capitalize(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            // Iterate through sub-categories
            ...subCategories.entries.map<Widget>((entry) {
              String subCategoryName = entry.key;
              List<String> items = entry.value.toList();

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Title for the sub-category
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                  width: 100,
                                  child: _buildActionItem(
                                      subCategoryName.capitalize(),
                                      subCategoryName,
                                      20,
                                      8)),
                            ),
                            Icon(
                              Icons.arrow_right_alt_sharp,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            // Buttons for each item in this sub-category

                            Row(
                                children: items.map<Widget>((item) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(context, PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                              secondaryAnimation) {
                                        return LiveDetailsScreen(
                                          mainCollection: category,
                                          subCollection: subCategoryName,
                                          subSubCollection: item,
                                          showHighlightsButton:
                                              category.contains("live")
                                                  ? true
                                                  : false,
                                          img: (subCategoryName == "godaddy" ||
                                                  subCategoryName ==
                                                      "dropcatch" ||
                                                  subCategoryName ==
                                                      "dynadot" ||
                                                  subCategoryName ==
                                                      "namecheap" ||
                                                  subCategoryName == "namesilo")
                                              ? "assets/images/home_screen_images/livelogos/$subCategoryName.png"
                                              : "assets/images/home_screen_images/appbar_images/notification.png",
                                        );
                                      }));
                                    },
                                    child: Text(
                                      item,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 10),
                                    ),
                                    style: ButtonStyle(
                                        padding: WidgetStatePropertyAll(
                                            EdgeInsets.all(10)),
                                        backgroundColor: WidgetStatePropertyAll(
                                            Colors.green),
                                        textStyle: WidgetStateProperty.all(
                                            GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        foregroundColor: WidgetStatePropertyAll(
                                            Colors.white)),
                                  ),
                                ),
                              );
                            }).toList()),
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
}

Widget buildPreview(Map<String, dynamic> filteredDocumentData,String hiveDatabasePath,String appBarTitle) {
  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      // Extract data from filteredDocumentData
      var data = filteredDocumentData['data'] as Map<dynamic, dynamic>? ?? {};
      var uiButtons = filteredDocumentData['uiButtons'];
      List<dynamic>? buttons;
      var actionDoneList = filteredDocumentData['actionsDone'];

      // Handle ring status
      bool ringStatus = false;
      try {
        var ringStatusString = filteredDocumentData['device_notification']?.toString() ?? '';
        ringStatus = ringStatusString.contains("ringAlarm: true");
      } catch (e) {
        // Handle error silently
      }

      // Handle read status
      String readStatus = filteredDocumentData['read']?.toString() ?? 'no';

      // Handle buttons
      if (uiButtons is List && uiButtons.isNotEmpty) {
        buttons = uiButtons;
      }

      var itemId = filteredDocumentData['id']?.toString() ?? '';
      var path = filteredDocumentData['path']?.toString() ?? ''; // Assuming path is included

      return VisibilityDetector(
        key: Key('document-item-$itemId'),
        onVisibilityChanged: (info) async {
          if (info.visibleFraction > 0.9 && readStatus == 'no') {
            // Mark as read logic
            await HiveHelper.markAsRead(path);
            setState(() {}); // Update UI to reflect read status
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
                          ? BorderSide(color: Colors.redAccent, width: 2)
                          : BorderSide(color: Colors.transparent, width: 0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and sort button (for highlights)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['h1'] ?? 'No Title',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xffB71C1C),
                                ),
                              ),
                              if (appBarTitle.contains("highlights"))
                                Icon(
                                  Icons.compare_arrows_outlined,
                                  size: 18,
                                ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          // Data display: Table for highlights, chips otherwise
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
                                          velocity: Velocity(pixelsPerSecond: Offset(10, 10)),
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
                            ...data.entries.where((entry) => entry.key != 'h1').map(
                                  (entry) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.h),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8.w,
                                      runSpacing: 6.h,
                                      children: entry.value
                                          .toString()
                                          .split('|')
                                          .map(
                                            (item) => Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 6.h,
                                            horizontal: 10.w,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.shade300,
                                                blurRadius: 3,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            item.trim(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 8.sp,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 10),
                          // Action buttons
                          if (buttons != null)
                            Container(
                              alignment: AlignmentDirectional.center,
                              child: Wrap(
                                alignment: WrapAlignment.spaceAround,
                                spacing: 40.0,
                                runSpacing: 5,
                                children: buttons.map((buttonData) {
                                  final button = buttonData.values.first as Map<dynamic, dynamic>;
                                  final buttonText = button['button_text'] as String;
                                  return Padding(
                                    padding: EdgeInsets.all(5),
                                    child: Column(
                                      children: [
                                        getIconForButton(buttonText, 18),
                                        SizedBox(height: 10),
                                        Text(
                                          buttonText,
                                          style: GoogleFonts.poppins(fontSize: 8),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          SizedBox(height: 5),
                          // Timestamp
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                textAlign: TextAlign.right,
                                filteredDocumentData['datetime']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          // Actions done
                          if (actionDoneList != null)
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 10,
                                runSpacing: 5,
                                children: (actionDoneList as List<dynamic>).map<Widget>((actionDone) {
                                  return Container(
                                    width: 80.sp,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                    ),
                                    padding: EdgeInsets.all(10),
                                    alignment: Alignment.center,
                                    child: TextScroll(
                                      actionDone.toString(),
                                      velocity: Velocity(pixelsPerSecond: Offset(10, 0)),
                                      delayBefore: Duration(seconds: 5),
                                      intervalSpaces: 10,
                                      style: GoogleFonts.poppins(
                                        fontSize: 8,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}