import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/activity_helpers/FirestoreHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:namekart_app/cutsom_widget/AnimatedAvatarIcon.dart';
import 'package:namekart_app/cutsom_widget/AutoAnimatedContainerWidget.dart';
import 'package:namekart_app/cutsom_widget/CalendarSlider.dart';
import 'package:namekart_app/database/HiveHelper.dart';
import 'package:namekart_app/fcm/FcmHelper.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/safe_area_values.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../../activity_helpers/GlobalVariables.dart';
import '../../activity_helpers/UIHelpers.dart';
import '../../change_notifiers/WebSocketService.dart';
import '../../cutsom_widget/customSyncWidget.dart';

class LiveDetailsScreen extends StatefulWidget {
  String img, mainCollection, subCollection, subSubCollection;
  bool showHighlightsButton;

  LiveDetailsScreen({
    super.key,
    required this.img,
    required this.mainCollection,
    required this.subCollection,
    required this.subSubCollection,
    required this.showHighlightsButton,
  });

  @override
  _LiveDetailsScreenState createState() => _LiveDetailsScreenState();
}

class _LiveDetailsScreenState extends State<LiveDetailsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> auctions = [];
  List<Map<String, dynamic>> highlights = [];

  String dateCurrent = "";
  String datePast = "";

  late RebuildNotifier rebuildNotifier;
  late LiveDatabaseChange liveDatabaseChange;
  late LiveListDatabaseChange liveListDatabaseChange;
  late DatabaseDataUpdatedNotifier databaseDataUpdatedNotifier;

  late int lastIndexOfList = 0;

  List<dynamic> auctionsItem = [];
  List<dynamic> highlightsItem = [];

  bool isHighlightOpened = false;

  List<String> day = [];

  int currentlyOpenCustom = -1;

  int seenCounter = 0;

  int enteredCustomBidAmount = 0;

  late String hiveDatabasePath;

  bool showCalender = false;

  late DateResult todayDate, calenderSelectedDate;

  late String previousDay;
  late String nextDay;

  late String appBarTitle;
  String hightlightTitle = "Highlights";

  String searchText = "";

  StreamSubscription? _subscriptionForButtons;

  final ScrollController _scrollController =
      ScrollController(); // Step 1: Create a ScrollController

  final TextEditingController _enterAmountController = TextEditingController();
  TextEditingController searchQueryController = TextEditingController();

  var parsedAuctions = [];

  AnimationController? syncFirebaseController;

  @override
  void initState() {
    super.initState();



    assignThingsForRespectedScreen();

    syncToFirestore();

    fetchDataByDate(todayDate.formattedDate,true);

    setAppBarTitle();

    preprocessAuctions();

    FCMHelper().subscribeToTopic("godaddy");


    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clean up old listener if it exists

      liveDatabaseChange =
          Provider.of<LiveDatabaseChange>(context, listen: false);
      liveDatabaseChange.setPath(hiveDatabasePath);
      liveDatabaseChange.addListener(fetchNewAuction);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      databaseDataUpdatedNotifier =
          Provider.of<DatabaseDataUpdatedNotifier>(context, listen: false);
      databaseDataUpdatedNotifier.setPath(hiveDatabasePath);
      databaseDataUpdatedNotifier.addListener(updateChangesAndUI);
    });

    searchQueryController.addListener(getSearchedText);

    _enterAmountController.addListener(getEnteredCustomAmount);
  }

  Future<bool> syncToFirestore() async {
      WebSocketService w = WebSocketService();

      final response = await w.sendMessageGetResponse(
          {"query": "database-sync", "path": hiveDatabasePath}, "user");

      await syncFirestoreFromDocIdRange(
          hiveDatabasePath,
          int.parse(await HiveHelper.getLast(hiveDatabasePath)!['id']),
          int.parse(jsonDecode(response['data'])['response']),
          false
      );

      if (syncFirebaseController != null) {
        syncFirebaseController!.reverse();
      }
    return true;
  }

  void assignThingsForRespectedScreen() {
    todayDate = calenderSelectedDate = getToday();

    previousDay = getPreviousDay(todayDate.formattedDate).formattedDate;
    nextDay = "";

    hiveDatabasePath =
        "${widget.mainCollection}~${widget.subCollection}~${widget.subSubCollection}";


    setState(() {
      final allPaths = HiveHelper.getRingAlarmPaths();
      print(allPaths.last);
      print("All available paths: $allPaths");
    });
  }

  void fetchDataByDate(String datetime,bool goToBottom) {
    var rawData = HiveHelper.getDataForDate(hiveDatabasePath, datetime);
    auctions = rawData;
    setState(() {
      if(goToBottom) {
        scrollToBottom();
      }
    }); // Trigger UI rebuild after parsing
  }

  void fetchNewAuction() async {
    print("hellow");
    final item = HiveHelper.getLast(hiveDatabasePath);
    if (mounted &&
        calenderSelectedDate.formattedDate.contains(todayDate.formattedDate)) {
      setState(() {
        auctions.add(item!);
        if (seenCounter < 0) {
          seenCounter = 0;
        }
        seenCounter += 1;
      });
    }

    haptic();
  }

  void updateChangesAndUI() {
    String path = databaseDataUpdatedNotifier.getUpdatedPath();
    String id = path.split("~").last;
    var updatedData = HiveHelper.read(path);
    if (updatedData == null) return;

    setState(() {
      int index = auctions.indexWhere((element) => element['id'] == id);
      if (index != -1) {
        auctions[index] = updatedData;
      }
    });
  }

  void setAppBarTitle() {
    appBarTitle =
        widget.subCollection + "/" + widget.subSubCollection.capitalize();
  }

  void getSearchedText() {
    searchText = searchQueryController.text;
  }

  void preprocessAuctions() {
    parsedAuctions = auctions.map((auction) {
      return {
        "datetime": auction["datetime"],
        "date": auction["datetime"].toString().split("T")[0],
        "data": Map<dynamic, dynamic>.from(auction['data']),
        "uiButtons": List<Map<dynamic, dynamic>>.from(auction['uiButtons']),
      };
    }).toList();
  }

  void markAuctionAsReadLocallyAndInDB(int index, String path) async {
    final item = auctions[index];

    if (item['read'] == 'yes') return; // Already read, skip

    // 1. Update in-memory list
    auctions[index]['read'] = 'yes';

    // 2. Update Hive storage
    await HiveHelper.markAsRead(path);

    if (seenCounter >= 0) {
      seenCounter -= 1;
    }
    // 3. Trigger UI update
    setState(() {});
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void getEnteredCustomAmount() {
    setState(() {
      enteredCustomBidAmount = int.parse(_enterAmountController.text);
    });
  }

  void configureGotoNextDayButton(bool wantToFetchDataByDate) {
    setState(() {
      calenderSelectedDate = getNextDay(calenderSelectedDate.formattedDate)!;
      previousDay =
          getPreviousDay(calenderSelectedDate.formattedDate).formattedDate;
      if (wantToFetchDataByDate) {
        fetchDataByDate(calenderSelectedDate.formattedDate,true);
      }
      if (nextDay != todayDate.formattedDate) {
        nextDay = getNextDay(calenderSelectedDate.formattedDate)!.formattedDate;
      } else {
        nextDay = "";
      }
    });
  }

  void configureGoToPreviousButton(bool wantToFetchDataByDate) {
    setState(() {
      calenderSelectedDate = getPreviousDay(calenderSelectedDate.formattedDate);
      previousDay =
          getPreviousDay(calenderSelectedDate.formattedDate).formattedDate;
      nextDay = getNextDay(calenderSelectedDate.formattedDate)!.formattedDate;
      if (wantToFetchDataByDate) {
        fetchDataByDate(calenderSelectedDate.formattedDate,true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _enterAmountController.removeListener(getEnteredCustomAmount);
    _enterAmountController.dispose();
    _subscriptionForButtons?.cancel();
    rebuildNotifier.removeListener(() {});
    liveDatabaseChange.removeListener(fetchNewAuction);
    liveListDatabaseChange.removeListener(fetchNewAuction);
    databaseDataUpdatedNotifier.removeListener(updateChangesAndUI);


    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return

        // ---- it is for the background color
        Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2e4d47), // dark greenish tone
            Color(0xFFe9d9b4), // light beige/cream
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),

      //-- main layout starts
      child: Scaffold(
        backgroundColor: Colors.transparent,

        //---  top appbar code here
        appBar: AppBar(
          shadowColor: Colors.black,
          elevation: 5,
          scrolledUnderElevation: 20,
          iconTheme: const IconThemeData(color: Colors.white, size: 20),
          actions: [
            IconButton(
              onPressed: () {

                setState(() {
                  setState(() {
                    //--- the on click feature to selected date add filters searching
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.5,
                        // Start with 40% of the screen
                        minChildSize: 0.5,
                        // Minimum height
                        maxChildSize: 1.0,
                        // Maximum height (Full screen)
                        expand: false,
                        builder: (context, scrollController) {

                          haptic();
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                Transform.scale(
                                  scale: 0.9,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width -
                                          20,
                                      padding: const EdgeInsets.all(15),
                                      decoration: const BoxDecoration(
                                        color: Color(0xfff2f2f2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                      ),
                                      child: CalendarSlider(
                                        initialDate: DateTime(2021, 1, 1),
                                        finalDate: DateTime(
                                            todayDate.dateTime.year,
                                            todayDate.dateTime.month,
                                            todayDate.dateTime.day),
                                        defaultSelectedDate: DateTime(
                                            calenderSelectedDate.dateTime.year,
                                            calenderSelectedDate.dateTime.month,
                                            calenderSelectedDate.dateTime.day),
                                        onDateSelected: (selectedDate) {
                                          setState(() {
                                            calenderSelectedDate = DateResult(
                                                dateTime: selectedDate,
                                                formattedDate: selectedDate
                                                    .toString()
                                                    .split(" ")[0]);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 25, right: 25),
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width - 20,
                                    margin: const EdgeInsets.only(bottom: 18.0),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFB71C1C),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                    ),
                                    child: TextField(
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 10.sp,
                                        decoration: TextDecoration.none,
                                      ),
                                      controller: searchQueryController,
                                      decoration: InputDecoration(
                                          labelText: 'SearchQuery',
                                          border: InputBorder.none,
                                          labelStyle: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 8.sp,
                                            decoration: TextDecoration.none,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.search_rounded,
                                            size: 18,
                                          ),
                                          prefixIconColor: Colors.white),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20, right: 20, bottom: 10),
                                  child: Bounceable(
                                    onTap: () {
                                      haptic();
                                      fetchDataByDate(
                                          calenderSelectedDate.formattedDate,true);
                                      setState(() {
                                        if (searchText != "") {
                                          auctions =
                                              HiveHelper.searchInDataList(
                                                  auctions, searchText);

                                          AnimationController?
                                              topSnackBarController; // store controller globally or in your widget state

                                          showTopSnackBar(
                                            Overlay.of(context),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Color(0xFFB71C1C),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 10),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Search Filter: $searchText",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                        fontSize: 8.sp,
                                                        decoration:
                                                            TextDecoration.none,
                                                      ),
                                                    ),
                                                    IconButton(
                                                        onPressed: () {
                                                          topSnackBarController
                                                              ?.reverse(); // this closes it manually
                                                          setState(() {
                                                            fetchDataByDate(
                                                                calenderSelectedDate
                                                                    .formattedDate,true);
                                                          });
                                                        },
                                                        icon: Icon(
                                                          Icons.close_rounded,
                                                          color: Colors.white,
                                                        )),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            persistent: true,
                                            dismissType: DismissType.none,
                                            onAnimationControllerInit:
                                                (controller) {
                                              topSnackBarController =
                                                  controller;
                                            },
                                          );
                                        }
                                        configureGoToPreviousButton(false);
                                        configureGotoNextDayButton(false);
                                      });

                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      width: MediaQuery.sizeOf(context).width,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18.0),
                                        child: Shimmer.fromColors(
                                          baseColor: Colors.white,
                                          highlightColor: Colors.black,
                                          child: Text(
                                            "Done",
                                            style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  });
                });
              },
              icon: const Icon(
                Icons.date_range_rounded,
                size: 18,
              ),
            ),
            Container(
              width: 2,
              height: 25.sp,
              color: Colors.black12,
            ),
            AnimatedAvatarIcon(
              animationType: AnimationType.flyUpLoop,
              duration: Duration(seconds: 5),
              child: IconButton(
                onPressed: () {},
                icon: Image.asset(
                  widget.img,
                  width: 20.sp,
                  height: 20.sp,
                ),
              ),
            )
          ],
          actionsIconTheme: const IconThemeData(color: Colors.white, size: 20),
          title: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.white,
                highlightColor: Colors.black,
                child: Text(appBarTitle.capitalize(),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        color: Colors.white)),
              ),
            ],
          ),
          titleSpacing: 0,
          toolbarHeight: 50,
          flexibleSpace: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF03A7FF), Color(0xFFAE002C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight))),
        ),
        body: AlertWidget(
          onReconnectSuccess: () async {
            showTopSnackBar(
              snackBarPosition: SnackBarPosition.bottom,
              safeAreaValues:
                  SafeAreaValues(minimum: EdgeInsets.only(bottom: 30)),
              Overlay.of(context),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFF6347),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "✅ Reconnected !",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 10.sp,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF00C8FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Cloud Sync in Progress...",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 10.sp,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 12,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              persistent: true,
              dismissType: DismissType.none,
              onAnimationControllerInit: (controller) {
                syncFirebaseController = controller;
              },
            );

            if(await syncToFirestore()){
            fetchDataByDate(calenderSelectedDate.formattedDate,false);
            }

          },
          path: hiveDatabasePath,
          child: Expanded(
            child: Column(
              children: [
                if (auctions.isEmpty)
                  Column(
                    children: [
                      // Go to Previous Day Button
                      previousDayButton(),

                      // Center Cloud Image + Message
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Column(
                            children: [
                              AnimatedAvatarIcon(
                                animationType: AnimationType.slide,
                                reverse: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 100, left: 100, right: 100),
                                  child: Image.asset(
                                      "assets/images/bubbles_images/clouddatabase.png"),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Shimmer.fromColors(
                                  baseColor: Colors.white,
                                  highlightColor: Colors.black12,
                                  period: const Duration(seconds: 20),
                                  child: Text(
                                    "No local data available. Would you like to fetch it from the cloud?",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 20, right: 20, bottom: 20),
                                child: Bounceable(
                                  onTap: () async {

                                    haptic();
                                    await getFullDatabaseForPath(
                                        hiveDatabasePath);

                                    setState(() {
                                      fetchDataByDate(
                                          calenderSelectedDate.formattedDate,true);
                                    });
                                  },
                                  child: Container(
                                    width: MediaQuery.sizeOf(context).width,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),

                                        boxShadow: [BoxShadow(color: Colors.white,blurRadius: 5,spreadRadius: 1)]
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Text(
                                        "Get Data From Cloud",
                                        style: GoogleFonts.poppins(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      // Go to Next Day Button (only if available)
                      if (nextDay != "") nextDayButton(),

                      if (widget.showHighlightsButton)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              highlightsButton(),
                            ],
                          ),
                        )
                    ],
                  ),
                if (auctions.isNotEmpty)
                  Expanded(
                    child: Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(12.0),
                          itemCount: auctions.length,
                          itemBuilder: (context, index) {
                            final auctionItem = auctions[index];
                            var data = auctionItem['data'] as Map<dynamic, dynamic>;

                            var uiButtons = auctionItem['uiButtons'];
                            List<dynamic>? buttons;


                            var actionDoneList=auctionItem['actionsDone'];

                            bool ringStatus=false;

                            try{
                              var ringStatusString=auctionItem['device_notification'].toString();
                              ringStatus=ringStatusString.contains("ringAlarm: true");
                            }catch(e){}





                            String readStatus = auctionItem['read'];

                            if (uiButtons is List && uiButtons.isNotEmpty) {
                              buttons = uiButtons;
                            }
                            var itemId,path;

                            return VisibilityDetector(
                              key: Key('auction-item-$index'),
                              onVisibilityChanged: (info) async {
                                if (info.visibleFraction >0.9) {
                                  // Compose the path based on ID (assuming you have the ID in auction item)
                                  itemId =
                                      auctions[index]['id'].toString();
                                  path = '$hiveDatabasePath~$itemId';

                                  markAuctionAsReadLocallyAndInDB(index, path);
                                  await HiveHelper.markAsRead(path);
                                }
                              },
                              child: Column(
                                children: [
                                  if (index == 0) previousDayButton(),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (readStatus == "no")
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 18.0),
                                            child: Container(
                                              width: 100.sp,
                                              decoration: BoxDecoration(
                                                color: Color(0xff4CAF50),
                                                borderRadius: BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(20),
                                                    topRight:
                                                        Radius.circular(20)),

                                              ),
                                              padding: EdgeInsets.all(10),
                                              alignment: Alignment.center,
                                              child: Text("New",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 8.sp,
                                                    color: Colors.white,
                                                  )),
                                            ),
                                          ),


                                        if(ringStatus)
                                          Bounceable(
                                            onTap:() async {
                                              WebSocketService websocketService=new WebSocketService();

                                              Map<String,String> a={
                                                "update-data-of-path":"update-data-of-path",
                                                "calledDocumentPath":path,
                                                "calledDocumentPathFields":"device_notification[3].ringAlarm",
                                                "type":"ringAlarmFalse"
                                              };

                                              //sending response to server imp
                                              await websocketService.sendMessageGetResponse(a,"broadcast");


                                              setState(() {
                                                fetchDataByDate(calenderSelectedDate.formattedDate,false);
                                              });


                                              haptic();

                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 18.0),
                                              child: Container(
                                                width: 110.sp,
                                                decoration: BoxDecoration(color: Color(0xff3DB070), borderRadius: BorderRadius.circular(15),border: Border.all(color: Colors.white,width: 1)),
                                                padding: EdgeInsets.all(10),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text("Acknowledge",style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 8.sp,
                                                      color: Colors.white,
                                                    ),),
                                                    SizedBox(width: 5,),

                                                    Icon(Icons.close,color: Colors.white,size: 19,),

                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        Card(
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            side: ringStatus?BorderSide(color: Colors.redAccent,width:2,):BorderSide(color: Colors.transparent,width: 0),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      data['h1'] ?? 'No Title',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xffB71C1C),
                                                      ),
                                                    ),
                                                    if (appBarTitle.contains("Highlights"))
                                                    Bounceable(
                                                          onTap: () {

                                                            haptic();
                                                            TextEditingController
                                                                _inputTextFieldController =
                                                                new TextEditingController();
                                                            showDialog(
                                                                context:
                                                                    context,
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
                                                                              title: Text(
                                                                                "Enter First Row Value To Sort",
                                                                                style: GoogleFonts.poppins(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                                                              ),
                                                                              backgroundColor: Color(0xffB71C1C),
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
                                                                                Bounceable(
                                                                                  onTap: () {

                                                                                    haptic();
                                                                                    print(auctions[index]['data']);

                                                                                    setState(() {
                                                                                      auctions[index]['data'] = autosort(
                                                                                        auctions[index]['data'],
                                                                                        _inputTextFieldController.text,
                                                                                      );

                                                                                      print(auctions[index]['data']);
                                                                                    });

                                                                                    Navigator.pop(context);
                                                                                  },
                                                                                  child: Container(
                                                                                    decoration: const BoxDecoration(
                                                                                      color: Color(0xffE7E7E7),
                                                                                      borderRadius: BorderRadius.all(Radius.circular(10)),
                                                                                    ),
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsets.all(10),
                                                                                      child: Text("Sort", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                                                                                    ),
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
                                                ),
                                                SizedBox(height: 5.h),
                                                // h2, h3, ... as bubble-like items
                                                if (appBarTitle.contains("Highlights"))
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
                                                        List<String> items =
                                                            entry.value
                                                                .toString()
                                                                .split('|')
                                                                .map((e) =>
                                                                    e.trim())
                                                                .toList();

                                                        // Ensure the list has exactly 3 items
                                                        if (items.length < 3) {
                                                          items.addAll(
                                                              List.filled(
                                                                  3 -
                                                                      items
                                                                          .length,
                                                                  ''));
                                                        } else if (items
                                                                .length >
                                                            3) {
                                                          items = items.sublist(
                                                              0, 3);
                                                        }

                                                        return TableRow(
                                                          children: items
                                                              .map(
                                                                (item) =>
                                                                    Padding(
                                                                  padding: EdgeInsets
                                                                      .symmetric(
                                                                          vertical:
                                                                              8.h),
                                                                  child: Center(
                                                                    child:
                                                                        TextScroll(
                                                                      item,
                                                                      velocity: Velocity(
                                                                          pixelsPerSecond: Offset(
                                                                              10,
                                                                              10)),
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontSize:
                                                                            10.sp,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                        );
                                                      },
                                                    ).toList(),
                                                  ),
                                                if (!appBarTitle.contains("Highlights"))
                                                  ...data.entries.where((entry) => entry.key != 'h1')
                                                      .map(
                                                        (entry) => Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical:
                                                                      5.h),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              // Styled text items
                                                              Wrap(
                                                                spacing: 8.w,
                                                                runSpacing: 6.h,
                                                                children: entry
                                                                    .value
                                                                    .toString()
                                                                    .split('|')
                                                                    .map(
                                                                      (item) =>
                                                                          Container(
                                                                        padding: EdgeInsets.symmetric(
                                                                            vertical:
                                                                                6.h,
                                                                            horizontal: 10.w),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color: Colors
                                                                              .grey
                                                                              .shade100,
                                                                          borderRadius:
                                                                              BorderRadius.circular(8),
                                                                          boxShadow: [
                                                                            BoxShadow(
                                                                              color: Colors.grey.shade300,
                                                                              blurRadius: 3,
                                                                              offset: Offset(0, 1),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          item.trim(),
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                8.sp,
                                                                            color:
                                                                                Colors.black,
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
                                                // Buttons with icons
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                if (buttons != null)
                                                  Container(
                                                    alignment:
                                                        AlignmentDirectional
                                                            .center,
                                                    child: Wrap(
                                                      alignment: WrapAlignment
                                                          .spaceAround,
                                                      spacing: 40.0,
                                                      runSpacing: 5,
                                                      children: buttons
                                                          .map((buttonData) {
                                                        final button =
                                                            buttonData.values
                                                                    .first
                                                                as Map<dynamic,
                                                                    dynamic>;
                                                        final buttonText =
                                                            button['button_text']
                                                                as String;

                                                        return Bounceable(
                                                          onTap: () async {

                                                            await dynamicDialog(
                                                                context,
                                                                button,
                                                                widget.subCollection,
                                                                auctionItem['id'].toString(),
                                                                int.parse(buttonData.keys.toList()[0]
                                                                        .toString()
                                                                        .replaceAll(
                                                                            "button",
                                                                            "")) -
                                                                    1,
                                                                buttonData.keys
                                                                    .toList()[0],buttonText,data['h1']!);

                                                            syncFirestoreFromDocIdRange(await HiveHelper.getLast(hiveDatabasePath)!['id'],
                                                                int.parse(auctionItem['id'])-1,
                                                                int.parse(auctionItem['id']),true
                                                            );

                                                            setState(() {
                                                            fetchDataByDate(calenderSelectedDate.formattedDate,false);
                                                            });


                                                            haptic();


                                                          },
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(5),
                                                            child: Column(
                                                              children: [
                                                                getIconForButton(
                                                                    buttonText,
                                                                    18),
                                                                SizedBox(
                                                                    height: 10),
                                                                Text(
                                                                  buttonText,
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                          fontSize:
                                                                              8),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                SizedBox(height: 5),
                                                // Compact datetime
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      textAlign:
                                                          TextAlign.right,
                                                      auctionItem['datetime'],
                                                      style: TextStyle(
                                                        fontSize:8,
                                                        color: Colors.grey[600],
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontWeight: FontWeight.bold
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                SizedBox(height: 15),

                                                if(actionDoneList!=null)
                                                  Container(
                                                    width: MediaQuery.of(context).size.width,
                                                    child: Wrap(
                                                        alignment: WrapAlignment
                                                            .spaceBetween,
                                                        spacing: 10,
                                                        runSpacing: 5,
                                                        children: (actionDoneList as List<dynamic>).map<Widget>((actionDone) {
                                                      return Container(
                                                        width: 80.sp,
                                                        decoration: BoxDecoration(color: Colors.black12,borderRadius: BorderRadius.only(topLeft: Radius.circular(10),bottomRight: Radius.circular(10)),),
                                                        padding: EdgeInsets.all(10),
                                                        alignment: Alignment.center,
                                                        child: TextScroll(
                                                          actionDone.toString(),
                                                          velocity: Velocity(pixelsPerSecond: Offset(10,0)),
                                                          delayBefore: Duration(seconds: 5),
                                                          intervalSpaces: 10,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 8,
                                                            color: Colors.black54,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList()),
                                                  ),
                                                // Divider
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index == auctions.length - 1 &&
                                      nextDay != "")
                                    nextDayButton()
                                ],
                              ),
                            );
                          },
                        ),
                        if (widget.showHighlightsButton) highlightsButton(),
                        Positioned(
                            bottom: 110,
                            right: 20,
                            child: GestureDetector(
                                onTap: () {

                                  haptic();
                                  seenCounter = 0;
                                  scrollToBottom();
                                },
                                child: const Icon(
                                  Icons.expand_circle_down_sharp,
                                  size: 40,
                                ))),
                        if (seenCounter > 0)
                          Positioned(
                            bottom: 135,
                            right: 20,
                            child: Container(
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    seenCounter.toString(),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 8),
                                  ),
                                )),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget showDateContainer(String currentDate) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          currentDate,
          style: GoogleFonts.poppins(
            color: const Color(0xff50000000),
            fontWeight: FontWeight.bold,
            fontSize: 8,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget previousDayButton() {
    return Bounceable(
      onTap: () {

        haptic();
        configureGoToPreviousButton(true);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                "Go to $previousDay",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
              ),
            )),
      ),
    );
  }

  Widget nextDayButton() {
    return Bounceable(
      onTap: () {

        haptic();
        configureGotoNextDayButton(true);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              "Go to $nextDay",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget highlightsButton() {
    return Positioned(
      bottom: 60,
      right: 20,
      child: Bounceable(
        onTap: () {
          showTopSnackBar(
            Overlay.of(context),
            displayDuration: Duration(milliseconds: 100),
            animationDuration: Duration(seconds: 1),
            CustomSnackBar.success(
              message:
                  "Switched to ${hightlightTitle == 'Highlights' ? 'Highlights' : 'Live'}",
            ),
          );

          setState(() {
            if (hightlightTitle == "Highlights") {
              widget.subSubCollection = "highlights";
              assignThingsForRespectedScreen();
              setAppBarTitle();
              hightlightTitle = "Live";
            } else if (hightlightTitle == "Live") {
              widget.subSubCollection = "auctions";
              assignThingsForRespectedScreen();
              setAppBarTitle();
              hightlightTitle = "Highlights";
            }
            liveDatabaseChange.setPath(hiveDatabasePath);

            fetchDataByDate(calenderSelectedDate.formattedDate,true);
          });


          haptic();
        },
        child: AutoAnimatedContainerWidget(
          curve: Curves.bounceInOut,
          child: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.pinkAccent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                boxShadow: [BoxShadow(color: Colors.black54,blurRadius: 5)]

              ),
              padding: const EdgeInsets.only(
                  top: 10, left: 10, right: 10, bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Text(hightlightTitle,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                            color: Colors.white)),
                  ),
                  const Icon(
                    Icons.checklist_sharp,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
