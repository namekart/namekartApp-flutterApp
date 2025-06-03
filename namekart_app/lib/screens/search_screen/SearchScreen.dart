import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
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

  List<String> filteredAvailableData = [];
  List<List<String>> filteredAuctionTools = [];
  List<String> filteredDocuments=[];
  Map<String,dynamic> filteredDocumentsData={};

  Map<String, List<String>> searchIndex = {};

  List<String> allAvailableData = [];
  List<String> documentsData = [];
  List<List<String>> auctionsTools=[
    ["Watch List","watchlist"],
    ["Bidding List","biddinglist"],
    ["Bulk Bid","bulkbid"],
    ["Bulk Fetch","bulkfetch"],
  ];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();


    textEditingController.addListener(_onTextChanged);

    allAvailableData = HiveHelper.getCategoryPathsOnly();

    filteredAvailableData = List.from(allAvailableData);
    filteredAuctionTools = List.from(auctionsTools);

    filteredDocuments=HiveHelper.getAllAvailablePaths();

    // Build filteredDocumentsData for UI rendering
    for (int i = 0; i < filteredDocuments.length; i++) {
      filteredDocumentsData[filteredDocuments[i]] =
          HiveHelper.read(filteredDocuments[i]);
    }

    // Build index AFTER UI is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      buildSearchIndexInBackground();
    });


    haptic();

  }

  void buildSearchIndexInBackground() async {
    List<String> paths = HiveHelper.getAllAvailablePaths();

    for (String path in paths) {
      try {
        var data = HiveHelper.read(path);
        List<String> keywords = extractSearchableStrings(data);
        searchIndex[path] = keywords.toSet().toList(); // Remove duplicates
      } catch (e) {
        print("Failed to index $path: $e");
      }
    }

    setState(() {}); // Trigger rebuild if needed
  }

  List<String> extractSearchableStrings(dynamic data) {
    List<String> result = [];

    if (data is Map) {
      data.forEach((key, value) {
        result.add(key.toString().toLowerCase());
        result.addAll(extractSearchableStrings(value));
      });
    } else if (data is List) {
      for (var item in data) {
        result.addAll(extractSearchableStrings(item));
      }
    } else if (data != null) {
      result.add(data.toString().toLowerCase());
    }

    return result;
  }



  List<List<String>> searchedItem = [];

  void _onTextChanged() {
    String query = textEditingController.text.trim().toLowerCase();

    setState(() {
      // Filter static data
      filteredAvailableData = allAvailableData.where((item) => item.toLowerCase().contains(query)).toList();

      filteredAuctionTools = auctionsTools.where((item) => item[0].toLowerCase().contains(query)).toList();

      // Filter documents by path or index content
      filteredDocuments = searchIndex.entries
          .where((entry) =>
      entry.key.toLowerCase().contains(query) ||
          entry.value.any((v) => v.contains(query)))
          .map((e) => e.key)
          .toList();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30.sp),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Color(0xFFB71C1C)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15,bottom: 1),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Icon(Icons.arrow_back_rounded,
                                      color: Colors.white,size: 18,)),
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
                              child: Image.asset(
                                "assets/images/home_screen_images/searchwhite.png",
                                width: 15.0,
                                height: 15.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if(filteredAvailableData.isNotEmpty)
                  buildSimpleCategoryUI(filteredAvailableData),
                  Padding(
                    padding: const EdgeInsets.only(left: 20,top: 20),
                    child: Text(
                      "Auctions Tools",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  if(filteredAuctionTools.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: filteredAuctionTools.map<Widget>((item) {
                        return Bounceable(
                          onTap: (){
                            switch(item[1]){
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
                                        builder: (context) => BiddingList()));
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
                                  item[0], item[1], 20,8)),
                        );
                      }
                    ).toList()),
                  ),

                  if(filteredDocuments.isNotEmpty)
                    buildAuctionExpandableList(context,filteredDocuments,filteredDocumentsData)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(String label, String iconPath,double iconSize,double fontSize) {
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
      }catch(e){
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
                    scrollDirection: Axis.horizontal,child:Row(
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
                                      20,8)
                              ),
                            ),
                            Icon(
                              Icons.arrow_right_alt_sharp,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            // Buttons for each item in this sub-category

                            Row(children: items.map<Widget>((item) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),

                                  child: ElevatedButton(

                                    onPressed: () {
                                      Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) {
                                        return
                                          LiveDetailsScreen(
                                            mainCollection:category,
                                            subCollection:subCategoryName,
                                            subSubCollection:item,
                                            showHighlightsButton: category.contains("live")?true:false,
                                            img: (subCategoryName=="godaddy"||subCategoryName=="dropcatch"||subCategoryName=="dynadot"||subCategoryName=="namecheap"||subCategoryName=="namesilo")?
                                            "assets/images/home_screen_images/livelogos/$subCategoryName.png":"assets/images/home_screen_images/appbar_images/notification.png",
                                          );}));
                                    },
                                    child: Text(item,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 10
                                    ),),
                                    style: ButtonStyle(
                                      padding: WidgetStatePropertyAll(EdgeInsets.all(10)),
                                        backgroundColor:
                                            WidgetStatePropertyAll(Colors.green),
                                        textStyle: WidgetStateProperty.all(
                                            GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        foregroundColor:
                                            WidgetStatePropertyAll(Colors.white)),
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


Widget buildAuctionExpandableList(
    BuildContext context, List<String> filteredDocumentPaths, Map<String, dynamic> filteredDocumentsData) {
  // Group filtered items by first 3 parts of their path
  Map<String, List<String>> groupedData = {};

  for (var item in filteredDocumentPaths) {
    var parts = item.split("~");
    if (parts.length >= 3) {
      var prefix = parts.take(3).join("~");
      groupedData.putIfAbsent(prefix, () => []).add(item);
    }
  }

  return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState)
  {
    return Column(
      children: groupedData.entries.map((entry) {
        String appBarTitle = entry.key;
        List<String> paths = entry.value;

        String hiveDatabasePath = entry.key;

        return LazyExpansionTile(
          title: appBarTitle,
          children: [
            ListView.builder(
              shrinkWrap: true,
              // Ensure it fits within the parent widget
              physics: NeverScrollableScrollPhysics(),
              // Disable scrolling inside ListView
              itemCount: paths.length,
              itemBuilder: (context, index) {
                final auctionItem = filteredDocumentsData[paths[index]];
                var data = auctionItem['data'] as Map<dynamic, dynamic>? ??
                    {};
                var uiButtons = auctionItem['uiButtons'];
                List<dynamic>? buttons;
                var actionDoneList = auctionItem['actionsDone'];

                bool ringStatus = false;
                try {
                  var ringStatusString = auctionItem['device_notification']
                      ?.toString() ?? '';
                  ringStatus = ringStatusString.contains("ringAlarm: true");
                } catch (e) {
                  // Handle error silently
                }

                String readStatus = auctionItem['read']?.toString() ?? 'no';

                if (uiButtons is List && uiButtons.isNotEmpty) {
                  buttons = uiButtons;
                }

                var itemId = auctionItem['id']?.toString() ?? '';
                var path = paths[index];

                return VisibilityDetector(
                  key: Key('auction-item-$index'),
                  onVisibilityChanged: (info) async {
                    if (info.visibleFraction > 0.9) {
                      // Mark as read logic
                      await HiveHelper.markAsRead(path);
                      // Update local state and Firestore if needed
                      // Note: markAuctionAsReadLocallyAndInDB is not defined in the provided code
                      setState(() {}); // Assuming setState is available in the parent widget
                    }
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (readStatus == "no")
                              Padding(
                                padding: const EdgeInsets.only(right: 18.0),
                                child: Container(
                                  width: 100.sp,
                                  decoration: BoxDecoration(
                                    color: Color(0xff4CAF50),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  padding: EdgeInsets.all(10),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "New",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            if (ringStatus)
                              Bounceable(
                                onTap: () async {
                                  WebSocketService websocketService = WebSocketService();
                                  Map<String, String> a = {
                                    "update-data-of-path": "update-data-of-path",
                                    "calledDocumentPath": path,
                                    "calledDocumentPathFields": "device_notification[3].ringAlarm",
                                    "type": "ringAlarmFalse"
                                  };
                                  await websocketService
                                      .sendMessageGetResponse(
                                      a, "broadcast");
                                  setState(() {
                                    // Assuming fetchDataByDate is defined in the parent widget
                                    // fetchDataByDate(calenderSelectedDate.formattedDate, false);
                                  });
                                  haptic();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 18.0),
                                  child: Container(
                                    width: 110.sp,
                                    decoration: BoxDecoration(
                                      color: Color(0xff3DB070),
                                      borderRadius: BorderRadius.circular(
                                          15),
                                      border: Border.all(
                                          color: Colors.white, width: 1),
                                    ),
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .center,
                                      children: [
                                        Text(
                                          "Acknowledge",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 8.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Icon(Icons.close,
                                            color: Colors.white, size: 19),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: ringStatus
                                    ? BorderSide(
                                    color: Colors.redAccent, width: 2)
                                    : BorderSide(
                                    color: Colors.transparent, width: 0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween,
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
                                          Bounceable(
                                            onTap: () {
                                              haptic();
                                              TextEditingController _inputTextFieldController =
                                              TextEditingController();
                                              showDialog(
                                                context: context,
                                                builder: (
                                                    BuildContext context) {
                                                  return AlertDialog(
                                                    contentPadding: EdgeInsets
                                                        .all(0),
                                                    backgroundColor: Color(
                                                        0xffF5F5F5),
                                                    content: Container(
                                                      width: MediaQuery
                                                          .of(context)
                                                          .size
                                                          .width,
                                                      height: 200.sp,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment
                                                            .start,
                                                        children: [
                                                          AppBar(
                                                            title: Text(
                                                              "Enter First Row Value To Sort",
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 8,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight: FontWeight
                                                                    .bold,
                                                              ),
                                                            ),
                                                            backgroundColor: Color(
                                                                0xffB71C1C),
                                                            iconTheme: IconThemeData(
                                                                size: 20,
                                                                color: Colors
                                                                    .white),
                                                            titleSpacing: 0,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius
                                                                  .only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                    20),
                                                                topRight: Radius
                                                                    .circular(
                                                                    20),
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            child: Padding(
                                                              padding: EdgeInsets
                                                                  .all(20),
                                                              child: Container(
                                                                height: 50
                                                                    .sp,
                                                                alignment: Alignment
                                                                    .centerLeft,
                                                                decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius
                                                                      .circular(
                                                                      20),
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                child: TextField(
                                                                  controller: _inputTextFieldController,
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                    fontWeight: FontWeight
                                                                        .bold,
                                                                    color: Colors
                                                                        .black45,
                                                                    fontSize: 12
                                                                        .sp,
                                                                  ),
                                                                  decoration: InputDecoration(
                                                                    labelText: 'i.e Age 6 or modoo.blog or price 10',
                                                                    border: InputBorder
                                                                        .none,
                                                                    labelStyle: GoogleFonts
                                                                        .poppins(
                                                                      fontWeight: FontWeight
                                                                          .bold,
                                                                      color: Colors
                                                                          .black45,
                                                                      fontSize: 8
                                                                          .sp,
                                                                    ),
                                                                    prefixIcon: Icon(
                                                                        Icons
                                                                            .keyboard),
                                                                    prefixIconColor: Color(
                                                                        0xffB71C1C),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding: EdgeInsets
                                                                .only(
                                                                right: 20),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment
                                                                  .end,
                                                              children: [
                                                                Bounceable(
                                                                  onTap: () {
                                                                    haptic();
                                                                    print(
                                                                        auctionItem['data']);
                                                                    setState(() {
                                                                      auctionItem['data'] =
                                                                          autosort(
                                                                            auctionItem['data'],
                                                                            _inputTextFieldController
                                                                                .text,
                                                                          );
                                                                    });
                                                                    Navigator
                                                                        .pop(
                                                                        context);
                                                                  },
                                                                  child: Container(
                                                                    decoration: BoxDecoration(
                                                                      color: Color(
                                                                          0xffE7E7E7),
                                                                      borderRadius: BorderRadius
                                                                          .all(
                                                                          Radius
                                                                              .circular(
                                                                              10)),
                                                                    ),
                                                                    child: Padding(
                                                                      padding: EdgeInsets
                                                                          .all(
                                                                          10),
                                                                      child: Text(
                                                                        "Sort",
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          color: Colors
                                                                              .black,
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize: 10,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            child: Icon(
                                              Icons.compare_arrows_outlined,
                                              size: 18,
                                            ),
                                          ),
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
                                            .where((entry) =>
                                        entry.key != 'h1')
                                            .map((entry) {
                                          List<String> items = entry.value
                                              .toString().split('|').map((e) =>
                                              e.trim()).toList();
                                          if (items.length < 3) {
                                            items.addAll(List.filled(3 -
                                                items.length, ''));
                                          } else if (items.length > 3) {
                                            items = items.sublist(0, 3);
                                          }
                                          return TableRow(
                                            children: items
                                                .map(
                                                  (item) =>
                                                  Padding(
                                                    padding: EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.h),
                                                    child: Center(
                                                      child: TextScroll(
                                                        item,
                                                        velocity: Velocity(
                                                            pixelsPerSecond: Offset(
                                                                10, 10)),
                                                        style: GoogleFonts
                                                            .poppins(
                                                          fontSize: 10.sp,
                                                          color: Colors
                                                              .black87,
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
                                      ...data.entries.where((entry) =>
                                      entry.key != 'h1').map(
                                            (entry) =>
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 5.h),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  Wrap(
                                                    spacing: 8.w,
                                                    runSpacing: 6.h,
                                                    children: entry.value
                                                        .toString()
                                                        .split('|')
                                                        .map(
                                                          (item) =>
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                vertical: 6
                                                                    .h,
                                                                horizontal: 10
                                                                    .w),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .grey
                                                                  .shade100,
                                                              borderRadius: BorderRadius
                                                                  .circular(
                                                                  8),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade300,
                                                                  blurRadius: 3,
                                                                  offset: Offset(
                                                                      0, 1),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Text(
                                                              item.trim(),
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 8
                                                                    .sp,
                                                                color: Colors
                                                                    .black,
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
                                    if (buttons != null)
                                      Container(
                                        alignment: AlignmentDirectional
                                            .center,
                                        child: Wrap(
                                          alignment: WrapAlignment
                                              .spaceAround,
                                          spacing: 40.0,
                                          runSpacing: 5,
                                          children: buttons.map((buttonData) {
                                            final button = buttonData.values
                                                .first as Map<
                                                dynamic,
                                                dynamic>;
                                            final buttonText = button['button_text'] as String;
                                            return Bounceable(
                                              onTap: () async {
                                                await dynamicDialog(
                                                  context,
                                                  button,
                                                  '',
                                                  // Adjust subCollection as needed
                                                  auctionItem['id']
                                                      .toString(),
                                                  int.parse(buttonData.keys
                                                      .toList()[0]
                                                      .toString()
                                                      .replaceAll(
                                                      "button", "")) - 1,
                                                  buttonData.keys
                                                      .toList()[0],
                                                  buttonText,
                                                  data['h1'] ?? '',
                                                );
                                                syncFirestoreFromDocIdRange(
                                                  (await HiveHelper.getLast(
                                                      hiveDatabasePath))?['id'] ??
                                                      '',
                                                  int.parse(
                                                      auctionItem['id']) -
                                                      1,
                                                  int.parse(
                                                      auctionItem['id']),
                                                  true,
                                                );
                                                setState(() {
                                                  // Assuming fetchDataByDate is defined
                                                });
                                                haptic();
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.all(5),
                                                child: Column(
                                                  children: [
                                                    getIconForButton(
                                                        buttonText, 18),
                                                    SizedBox(height: 10),
                                                    Text(
                                                      buttonText,
                                                      style: GoogleFonts
                                                          .poppins(
                                                          fontSize: 8),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .end,
                                      children: [
                                        Text(
                                          textAlign: TextAlign.right,
                                          auctionItem['datetime']
                                              ?.toString() ?? '',
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
                                    if (actionDoneList != null)
                                      Container(
                                        width: MediaQuery
                                            .of(context)
                                            .size
                                            .width,
                                        child: Wrap(
                                          alignment: WrapAlignment
                                              .spaceBetween,
                                          spacing: 10,
                                          runSpacing: 5,
                                          children: (actionDoneList as List<
                                              dynamic>).map<Widget>((
                                              actionDone) {
                                            return Container(
                                              width: 80.sp,
                                              decoration: BoxDecoration(
                                                color: Colors.black12,
                                                borderRadius: BorderRadius
                                                    .only(
                                                  topLeft: Radius.circular(
                                                      10),
                                                  bottomRight: Radius
                                                      .circular(10),
                                                ),
                                              ),
                                              padding: EdgeInsets.all(10),
                                              alignment: Alignment.center,
                                              child: TextScroll(
                                                actionDone.toString(),
                                                velocity: Velocity(
                                                    pixelsPerSecond: Offset(
                                                        10, 0)),
                                                delayBefore: Duration(
                                                    seconds: 5),
                                                intervalSpaces: 10,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 8,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight
                                                      .bold,
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
            ),
          ],
        );
      }).toList(),
    );
  }
  );
}
