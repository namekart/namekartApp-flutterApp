import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/DbAccountHelper.dart';
import 'package:namekart_app/activity_helpers/DbSqlHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:text_scroll/text_scroll.dart';

import '../../activity_helpers/GlobalFunctions.dart';
import '../../cutsom_widget/_HashtagInputWidgetState.dart';
import '../live_screens/live_details_screen.dart';

class StarsScreen extends StatefulWidget {
  @override
  State<StarsScreen> createState() => _StarsScreenState();
}

class _StarsScreenState extends State<StarsScreen> {
  Map<String, List<dynamic>> pathsData = {};
  bool isLoading = true;
  bool hasError = false;



  @override
  void initState() {
    super.initState();
    loadStars();
  }

  Future<void> loadStars() async {
    try {
      Map<String, dynamic>? fetchedData = await getStars();
      if (fetchedData != null) {
        setState(() {
          pathsData = fetchedData.map((key, value) {
            return MapEntry(key, value as List<dynamic>);
          });
          isLoading = false;
        });
      } else {
        setState(() {
          pathsData = {};
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading stars: $e");
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<Map<String, dynamic>?> getStars() async {
    try {
      final stars = await DbAccountHelper.getStar("account~user~details", GlobalProviders.userId);
      return stars;
    } catch (e) {
      print("Error fetching stars from DB: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> paths = ["All", ...pathsData.keys.toList()];

    return DefaultTabController(
      length: paths.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black,
          title: text(text: "Paths & IDs",color: Color(0xff1e1e1e),fontWeight: FontWeight.bold,size: 12.sp),
          iconTheme: IconThemeData(size: 17),
          titleSpacing: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold,fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal,fontSize: 12),
            tabs: paths.map((p) => Tab(text: p)).toList(),
          ),
        ),
        body: isLoading
            ? const Center(child:  SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 12,
            )),)
            : hasError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 10),
              const Text("Failed to load stars. Please try again later."),
            ],
          ),
        )
            : pathsData.isEmpty && paths.length == 1
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/home_screen_images/nostars.png',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
            ],
          ),
        )
            : TabBarView(
          children: paths.map((currentTabPath) { // Renamed 'path' to 'currentTabPath' for clarity
            List<dynamic> ids;
            List<Map<String, String>> itemsToDisplay = []; // Stores {id: '...', originalPath: '...'}

            if (currentTabPath == "All") {
              // For "All" tab, iterate through all known paths and their IDs
              // to build a list of {id, originalPath}
              pathsData.forEach((originalPath, idList) {
                for (var id in idList) {
                  itemsToDisplay.add({
                    'id': id.toString(),
                    'originalPath': originalPath,
                  });
                }
              });
            }
            else {
              // For specific tabs, just use the IDs from that path
              ids = pathsData[currentTabPath] ?? [];
              for (var id in ids) {
                itemsToDisplay.add({
                  'id': id.toString(),
                  'originalPath': currentTabPath,
                });
              }
            }

            return itemsToDisplay.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/home_screen_images/nostars.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentTabPath == "All" ? "No Stars Yet!" : "No Stars in '$currentTabPath'",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentTabPath == "All"
                        ? "Looks like you haven't starred anything across all categories."
                        : "There are no starred items in this category.",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: itemsToDisplay.length,
              itemBuilder: (context, index) {
                final itemData = itemsToDisplay[index];
                final String itemId = itemData['id']!;
                final String originalPath = itemData['originalPath']!;

                return FutureBuilder( // Expecting String or null
                  future: DbSqlHelper.getById(originalPath, itemId), // **FIXED HERE: Using originalPath**
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading:  SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 12,
                            )),
                        title: Text("Loading details...", style: TextStyle(color: Colors.grey)),
                      );
                    } else if (snapshot.hasError) {
                      print("Error fetching details for $itemId from $originalPath: ${snapshot.error}");
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.error, color: Colors.red),
                        title: Text(
                          "Error loading data: ${snapshot.error.toString().split(':')[0]}",
                          style: const TextStyle(color: Colors.red),
                        ),
                        subtitle: Text("ID: $itemId (Path: $originalPath)"),
                      );
                    } else if (snapshot.hasData && snapshot.data != null) {
                      // Successfully fetched data
                      final auctionItem = snapshot.data!;
                      var data = auctionItem['data'] as Map<dynamic, dynamic>;

                      var uiButtons = auctionItem['uiButtons'];
                      List<dynamic>? buttons;

                      var actionDoneList = auctionItem['actionsDone'];

                      bool ringStatus = false;

                      try {
                        var ringStatusString =
                        auctionItem['device_notification'].toString();
                        ringStatus =
                            ringStatusString.contains("ringAlarm: true");
                      } catch (e) {}

                      String readStatus = auctionItem['read'];

                      if (uiButtons is List && uiButtons.isNotEmpty) {
                        buttons = uiButtons;
                      }

                      final date = extractDate(auctionItem['datetime_id']);
                      final nextDate = index < snapshot.data!.length - 1
                          ? extractDate(snapshot.data!['datetime_id'])
                          : null;

                      final showHeader = date != nextDate;

                      print(auctionItem['notes']);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: currentTabPath == "All" ? TextScroll(
                          "$originalPath $itemId",
                          velocity: Velocity(pixelsPerSecond: Offset(20, 10)),
                          mode: TextScrollMode.bouncing,
                          pauseBetween: Duration(seconds: 3),
                          style: TextStyle(color: Color(0xff717171),fontSize: 10.sp,fontWeight: FontWeight.bold),) : null, // Show path only in "All" tab
                        subtitle:Column(
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (showHeader)
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin:
                                        EdgeInsets.symmetric(vertical: 8),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        child: text(
                                          text: date,
                                          color: Colors.black54,
                                          size: 9,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (ringStatus)
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(right: 18.0),
                                    child: Container(
                                      width: 110.sp,
                                      decoration: BoxDecoration(
                                          color: Color(0xff3DB070),
                                          borderRadius:
                                          BorderRadius.circular(15),
                                          border: Border.all(
                                              color: Colors.white, width: 1)),
                                      padding: EdgeInsets.all(10),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Acknowledge",
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 8.sp,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 19,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: ringStatus
                                        ? BorderSide(
                                      color: Colors.redAccent,
                                      width: 2,
                                    )
                                        : BorderSide(
                                        color: Colors.transparent,
                                        width: 0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  margin: const EdgeInsets.only(top: 0),
                                  // Example: adds 8px margin around the card
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            text(
                                              text: data['h1'] ?? 'No Title',
                                              size: 12.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
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
                                                        shape: BoxShape.circle,
                                                      ),
                                                      padding:
                                                      const EdgeInsets.all(
                                                          3),
                                                    ),
                                                  ),
                                                if (originalPath.contains("Highlights"))
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
                                                                  content:
                                                                  Container(
                                                                      width: MediaQuery.of(context)
                                                                          .size
                                                                          .width,
                                                                      height: 200
                                                                          .sp,
                                                                      child:
                                                                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                                        AppBar(
                                                                          title: Text(
                                                                            "Enter First Row Value To Sort",
                                                                            style: GoogleFonts.poppins(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                                                          ),
                                                                          backgroundColor: Colors.white,
                                                                          iconTheme: IconThemeData(size: 20, color: Colors.white),
                                                                          titleSpacing: 0,
                                                                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                                                                        ),
                                                                        Container(
                                                                          child: Padding(
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
                                                                          padding: const EdgeInsets.only(right: 20),
                                                                          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
                                        // h2, h3, ... as bubble-like items
                                        if (originalPath.contains("Highlights"))
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
                                                List<String> items = entry.value
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
                                                          color:
                                                          Colors.white,
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
                                                        alignment: Alignment
                                                            .center,
                                                        child: TextScroll(
                                                          item,
                                                          velocity: Velocity(
                                                              pixelsPerSecond:
                                                              Offset(10,
                                                                  10)),
                                                          style: GoogleFonts.poppins(
                                                              fontSize:
                                                              8.sp,
                                                              color: Color(
                                                                  0xff717171),
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                      .toList(),
                                                );
                                              },
                                            ).toList(),
                                          ),
                                        if (!originalPath
                                            .contains("Highlights")) ...[
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 5.h),
                                            child: Wrap(
                                              spacing: 8.w,
                                              runSpacing: 8.h,
                                              children: [
                                                ...[
                                                  data['h2'],
                                                  data['h3'],
                                                  data['h4'],
                                                  data['h5'],
                                                  data['h6'],
                                                  data['h7'],
                                                  data['h8'],
                                                  data['h9'],
                                                  data['h10'],
                                                  // Add more fields if needed
                                                ]
                                                    .where((value) =>
                                                value != null)
                                                    .join(' | ')
                                                    .split('|')
                                                    .map(
                                                      (item) => Container(
                                                    padding: EdgeInsets
                                                        .symmetric(
                                                        vertical: 6.h,
                                                        horizontal:
                                                        10.w),
                                                    decoration:
                                                    BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(8),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            color: Colors.black12,
                                                            blurRadius: 3,
                                                            blurStyle: BlurStyle.outer
                                                        ),
                                                      ],
                                                    ),
                                                    child: text(
                                                        text: item.trim(),
                                                        size: 8.sp,
                                                        color: Color(
                                                            0xff717171),
                                                        fontWeight:
                                                        FontWeight
                                                            .bold),
                                                  ),
                                                )
                                                    .toList(),
                                              ],
                                            ),
                                          )
                                        ],

                                        // Buttons with icons
                                        SizedBox(
                                          height: 10,
                                        ),
                                        if (buttons != null)
                                          Wrap(
                                            alignment: WrapAlignment.start,
                                            runSpacing: 5,
                                            children: buttons.map((buttonData) {
                                              final button =
                                              buttonData.values.first
                                              as Map<dynamic, dynamic>;
                                              final buttonText =
                                              button['button_text']
                                              as String;

                                              return SizedBox(
                                                width: 73,
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.all(5),
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
                                                                  actionDoneList.toString().contains("Watch") &&
                                                                      buttonText.contains("Watch")
                                                                      ? "remove watch"
                                                                      : buttonText,
                                                                  18),
                                                            ),
                                                            SizedBox(
                                                                height: 10),
                                                            text(
                                                              text: actionDoneList
                                                                  .toString()
                                                                  .contains(
                                                                  "Watch") &&
                                                                  buttonText
                                                                      .contains("Watch")
                                                                  ? "Remove watch"
                                                                  : buttonText,
                                                              color: Color(
                                                                  0xff717171),
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                              size: 7.sp,
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        // Compact datetime
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.end,
                                          children: [
                                            text(
                                              text: formatToIST(
                                                  auctionItem['datetime_id']),
                                              size: 8,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.bold,
                                            ),

                                            FutureBuilder(
                                                future: DbAccountHelper.isStarred(
                                                    "account~user~details",
                                                    GlobalProviders.userId,
                                                    originalPath,
                                                    auctionItem['datetime_id']),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasError) {
                                                    return Text(
                                                        'Error: ${snapshot.error}');
                                                  } else {
                                                    bool isStarred =
                                                        snapshot.data ?? false;

                                                    return buildStarToggleButton(
                                                        isStarred: isStarred,
                                                        onStarredClicked: () {},
                                                        onNotStarredClicked:
                                                            ()  {}
                                                    );
                                                  }
                                                }),

                                          ],
                                        ),



                                        FutureBuilder(
                                          future: Future.delayed(
                                              Duration(seconds: 5), () => true),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: text(
                                                    text: 'Hashtags loading...',
                                                    size: 8,
                                                    color: Colors.black54,
                                                    fontWeight:
                                                    FontWeight.bold),
                                              );
                                            }
                                            return createHashtagAndNotesInputWidget(
                                              initialHashtags:(auctionItem['hashtags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                                              initialNotes: (auctionItem['notes'] as List?)
                                                  ?.map((e) => (e as Map?)?.map(
                                                    (k, v) => MapEntry(k.toString(), v.toString()),
                                              ) ?? {})
                                                  .toList() ?? []
                                              ,
                                              // Pass the item's notes
                                              notesAuthorName:
                                              GlobalProviders.userId,
                                              onHashtagsChanged: (newHashtags) {},
                                              onNotesChanged: (newNotes) {
                                              },
                                            );
                                          },
                                        ),

                                        // if (actionDoneList != null)
                                        //   Padding(
                                        //     padding:
                                        //         const EdgeInsets.only(top: 8.0),
                                        //     child: Wrap(
                                        //         alignment: WrapAlignment.start,
                                        //         spacing: 5,
                                        //         runSpacing: 5,
                                        //         children: (actionDoneList as List<dynamic>)
                                        //             .map<Widget>((actionDone) {
                                        //           return Container(
                                        //             width: 70.sp,
                                        //             decoration: BoxDecoration(
                                        //               color: Colors.white,
                                        //               boxShadow: [
                                        //                 BoxShadow(
                                        //                   color: Colors
                                        //                       .grey.shade300,
                                        //                   blurRadius: 0.5,
                                        //                 )
                                        //               ],
                                        //               borderRadius:
                                        //                   BorderRadius.only(
                                        //                       topLeft: Radius
                                        //                           .circular(10),
                                        //                       bottomRight:
                                        //                           Radius
                                        //                               .circular(
                                        //                                   10)),
                                        //             ),
                                        //             padding: EdgeInsets.all(10),
                                        //             alignment: Alignment.center,
                                        //             child: text(
                                        //                 text: actionDone
                                        //                     .toString(),
                                        //                 size: 7.sp,
                                        //                 color:
                                        //                     Colors.black54,
                                        //                 fontWeight:
                                        //                     FontWeight.w400),
                                        //           );
                                        //         }).toList()),
                                        //   ),
                                        // Divider
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => LiveDetailsScreen(
                                    mainCollection: originalPath.split("~")[0],
                                    subCollection: originalPath.split("~")[1],
                                    subSubCollection: originalPath.split("~")[2],
                                    showHighlightsButton: originalPath.split("~")[1].contains("live"),
                                    img:originalPath.split("~")[2]=="Live-DC" ? "assets/images/home_screen_images/livelogos/dropcatch.png"
                                        : originalPath.split("~")[2]=="Live-DD" ? "assets/images/home_screen_images/livelogos/dynadot.png"
                                        : originalPath.split("~")[2]=="Live-SAV" ? "assets/images/home_screen_images/livelogos/sav.png"
                                        : originalPath.split("~")[2]=="Live-GD" ? "assets/images/home_screen_images/livelogos/godaddy.png"
                                        : originalPath.split("~")[2]=="Live-NC" ? "assets/images/home_screen_images/livelogos/namecheap.png"
                                        : originalPath.split("~")[2]=="Live-NS" ? "assets/images/home_screen_images/livelogos/namesilo.png":
                                    "assets/images/home_screen_images/appbar_images/notification.png",
                                    scrollToDatetimeId: itemId,
                                  )));
                          loadStars();
                        },
                      );
                    } else {
                      // Data is null or empty
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.info_outline, color: Colors.grey),
                        title: Text(
                          "No details found for ID: $itemId",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        subtitle: currentTabPath == "All" ? Text("Path: $originalPath") : null,
                      );
                    }
                  },
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildStarToggleButton({
    Key? key,
    required bool isStarred,
    required VoidCallback onStarredClicked,
    required VoidCallback onNotStarredClicked,
    double iconSize = 24.0,
    Color? filledColor,
    Color? outlinedColor,
  }) {
    return StatefulBuilder(
      key: key, // Pass the key to StatefulBuilder
      builder: (BuildContext context, StateSetter setState) {
        // Internal state to manage the current appearance of the star.
        // We use a mutable list to hold the boolean, allowing us to update it
        // within the builder's closure. This is a common pattern with StatefulBuilder.
        final List<bool> _isCurrentlyStarred = [isStarred];

        // To handle external changes to 'isStarred' prop, we need to ensure
        // our internal state reflects it. This is a simplified equivalent of didUpdateWidget.
        // If the incoming 'isStarred' is different from our current internal state,
        // we update the internal state.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isCurrentlyStarred[0] != isStarred) {
            setState(() {
              _isCurrentlyStarred[0] = isStarred;
            });
          }
        });

        /// Handles the tap event on the star button.
        void _handleStarTap() {
          setState(() {
            // Toggle the internal state.
            _isCurrentlyStarred[0] = !_isCurrentlyStarred[0];
          });

          // Call the appropriate callback based on the new state.
          if (_isCurrentlyStarred[0]) {
            onStarredClicked();
          } else {
            onNotStarredClicked();
          }
        }

        return IconButton(
          icon: Icon(
            _isCurrentlyStarred[0]
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: iconSize,
            color: _isCurrentlyStarred[0]
                ? (filledColor ?? Colors.yellow[700])
                : (outlinedColor ?? Colors.grey),
          ),
          onPressed: _handleStarTap,
          tooltip: _isCurrentlyStarred[0]
              ? 'Unstar'
              : 'Star', // Accessibility tooltip
        );
      },
    );
  }
}