import 'dart:async';
import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/activity_helpers/FirestoreHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:namekart_app/cutsom_widget/CalendarSlider.dart';
import 'package:namekart_app/database/HiveHelper.dart';
import 'package:namekart_app/fcm/FcmHelper.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/safe_area_values.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../../activity_helpers/GlobalVariables.dart';
import '../../activity_helpers/UIHelpers.dart';
import '../../change_notifiers/WebSocketService.dart';
import '../../cutsom_widget/SlowScrollPhysics.dart';
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
  int pagingLastIndex = 0;

  List<Map<dynamic, dynamic>> auctions = [];
  List<Map<dynamic, dynamic>> auctionswithpaging = []; // paginated list

  List<Map<dynamic, dynamic>> highlights = [];

  bool isLive = true;

  String dateCurrent = "";
  String datePast = "";

  late LiveDatabaseChange liveDatabaseChange;
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

  ItemScrollController itemScrollController = ItemScrollController();


  final TextEditingController _enterAmountController = TextEditingController();
  TextEditingController searchQueryController = TextEditingController();

  String buttonloading = "";

  AnimationController? syncFirebaseController;

  bool showUi = true;

  late BuildContext dialogContext;

  bool isLoadingData = true;

  ValueNotifier<String?> currentDateNotifier = ValueNotifier<String?>(null);

  final Map<String, GlobalKey> dateKeys = {};

  @override
  void initState() {
    super.initState();

    assignThingsForRespectedScreen();
    setAppBarTitle();

    if (HiveHelper.getLast(hiveDatabasePath) != null) {
      syncToFirestore();
      fetchDataByDate(false);
      FCMHelper().subscribeToTopic("godaddy");
    }

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


    for (var auctionItem in auctions) {
      final date = extractDate(auctionItem['datetime_id']);
      dateKeys.putIfAbsent(date, () => GlobalKey());
    }

  }

  Future<bool> syncToFirestore() async {
    String datetime_id = HiveHelper.getLast(hiveDatabasePath)?['datetime_id'];

    await syncFirestoreFromDocIdTimestamp(hiveDatabasePath, datetime_id, false);

    if (syncFirebaseController != null) {
      syncFirebaseController!.reverse();
    }
    return true;
  }

  void assignThingsForRespectedScreen() {
    todayDate = calenderSelectedDate = getToday();

    previousDay = getPreviousDay(todayDate.formattedDate).formattedDate;
    nextDay = "";

    hiveDatabasePath = "${widget.mainCollection}~${widget.subCollection}~${widget.subSubCollection}";
  }

  fetchDataByDate(bool rebuild) {
    var rawData = HiveHelper.getFullData(hiveDatabasePath);
    auctions = rawData;
    setState(() {
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          isLoadingData = false;
        });
      });
    }); // Trigger UI rebuild after parsing

    if(rebuild){
      showSyncDialog(context);

      Future.delayed(const Duration(seconds: 30), () {
          Navigator.of(dialogContext, rootNavigator: true).pop();
      });
    }
  }

  void fetchNewAuction() async {
    final item = HiveHelper.getLast(hiveDatabasePath);
    if (mounted && calenderSelectedDate.formattedDate.contains(todayDate.formattedDate)) {
      setState(() {
        auctions.insert(0, item!);
        if (seenCounter < 0) {
          seenCounter = 0;
        }
        seenCounter += 1;
      });
    }
    haptic();
  }

  void showDialogPopup() {
    resetButtonLoading();

    showTopSnackBar(
      Overlay.of(context),
      displayDuration: Duration(milliseconds: 100),
      animationDuration: Duration(milliseconds: 500),
      CustomSnackBar.success(
        message:
            "The dialog has loaded successfully. If it hasn’t opened, please tap the button again.",
      ),
    );
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
    appBarTitle = "${widget.subCollection}/${widget.subSubCollection.capitalize()}";
  }

  void getSearchedText() {
    searchText = searchQueryController.text;
  }

  void resetButtonLoading() {
    setState(() {
      buttonloading = "";
    });
  }

  void scrollToBottom() async {
    if (itemScrollController.isAttached) {
      itemScrollController.jumpTo(index: 0);
    }
  }

  void scrollToDate(String date) {
    final index = auctions.lastIndexWhere((item) => extractDate(item['datetime_id']) == date);
    if (index != -1) {
      itemScrollController.scrollTo(
        index: index,
        duration: Duration(milliseconds: 500),
        alignment: 0.4
      );
    } else {
      showTopSnackBar(
        Overlay.of(context),
        displayDuration: Duration(milliseconds: 100),
        animationDuration: Duration(milliseconds: 500),
        CustomSnackBar.error(
          message:
          "No items found for $date",
        ),
      );
    }
  }





  void getEnteredCustomAmount() {
    setState(() {
      enteredCustomBidAmount = int.parse(_enterAmountController.text);
    });
  }

  @override
  Future<void> dispose() async {
    await HiveHelper.markAllAsRead(hiveDatabasePath);
    _enterAmountController.removeListener(getEnteredCustomAmount);
    _enterAmountController.dispose();
    _subscriptionForButtons?.cancel();
    liveDatabaseChange.removeListener(fetchNewAuction);
    databaseDataUpdatedNotifier.removeListener(updateChangesAndUI);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF7F7F7),
      //---  top appbar code here
      appBar: AppBar(
        elevation: 10,
        backgroundColor: Color(0xffF7F7F7),
        iconTheme: const IconThemeData(color: Color(0xff3F3F41), size: 15),
        actions: [
          SizedBox(width: 10,),
          Bounceable(
            onTap: () {
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
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child:SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 20, right: 20),
                                child: GestureDetector(
                                  onTap: () async {
                                    haptic();
                                    await getFullDatabaseForPath(hiveDatabasePath);
                                    Navigator.pop(context);
                          
                                    setState(() {
                                      fetchDataByDate(true);
                                    });
                          
                                  },
                                  child: Container(
                                    width: MediaQuery.sizeOf(context).width,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.sync_rounded, color: Colors.white,size: 15,),
                                          SizedBox(width: 10,),
                                          Text(
                                            "Sync With Cloud",
                                            style: GoogleFonts.poppins(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          
                              Transform.scale(
                                scale: 0.9,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width - 20,
                                    padding: const EdgeInsets.all(15),
                                    decoration: const BoxDecoration(
                                      color: Color(0xfff2f2f2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
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
                                padding:
                                    const EdgeInsets.only(left: 25, right: 25),
                                child: Container(
                                  width: MediaQuery.of(context).size.width - 20,
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
                                child: GestureDetector(
                                  onTap: () async {
                                    haptic();
                          
                                    if (searchText.isNotEmpty) {
                                      var filtered = HiveHelper.searchInDataList(auctions, searchText);
                          
                                      setState(() {
                                        auctions = filtered;
                                      });
                          
                                      AnimationController? topSnackBarController;
                          
                          
                                      showTopSnackBar(
                                        Overlay.of(context),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xFFB71C1C),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "Search Filter: $searchText",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontSize: 8.sp,
                                                    decoration: TextDecoration.none,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    topSnackBarController?.reverse(); // manually close
                                                    await fetchDataByDate(false); // restore full list
                                                  },
                                                  icon: Icon(Icons.close_rounded, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        persistent: true,
                                        dismissType: DismissType.none,
                                        onAnimationControllerInit: (controller) {
                                          topSnackBarController = controller;
                                        },
                                      );
                                    }

                                    scrollToDate(extractDate(calenderSelectedDate.formattedDate.toString()));

                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    width: MediaQuery.sizeOf(context).width,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18.0),
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
                              )
                          
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              });
            },
            child: ValueListenableBuilder<String?>(
              valueListenable: currentDateNotifier,
              builder: (context, date, _) {
                if (date == null) return SizedBox.shrink();
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: text(
                      text: extractDate(date),
                      // Format it as "June 27, 2025" or "3:40 PM"
                      color: Colors.white,
                      size: 8,
                      fontWeight: FontWeight.w300),
                );
              },
            ),
          ),
          SizedBox(width: 10,),
          Container(
            width: 2,
            height: 25.sp,
            color: Colors.black12,
          ),
          IconButton(
            onPressed: () {},
            icon: Image.asset(
              widget.img,
              width: 15.sp,
              height: 15.sp,
            ),
          )
        ],
        title: TextScroll(
            velocity: Velocity(pixelsPerSecond: Offset(20, 20)),
            pauseBetween: Duration(seconds: 3),
            appBarTitle.capitalize(),
            style: GoogleFonts.poppins(
            fontWeight: FontWeight.w300,
            fontSize: 12.sp,
            color: Color(0xff3F3F41))),
        titleSpacing: 0,
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
                          text(
                            text: "Cloud Sync in Progress...",
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              size: 8,
                            ),
                          const SizedBox(
                              width: 20,
                              height: 20,
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

          if (await syncToFirestore()) {
            fetchDataByDate(false);
          }
        },
        path: hiveDatabasePath,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoadingData)
              const Center(
                child:  Column(
                  children: [
                    SizedBox(height: 20,),
                    SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 12,
                        )),
                  ],
                ),
              ),
            if (widget.showHighlightsButton && !isLoadingData)
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                child: buildTabSwitcher(),
              ),
            if (auctions.isEmpty && !isLoadingData)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        // Cloud Image
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 100, vertical: 50),
                          child: Image.asset(
                              "assets/images/bubbles_images/clouddatabase.png"),
                        ),

                        // Message Text
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
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

                        // Fetch Button
                        GestureDetector(
                          onTap: () async {
                            haptic();
                            await getFullDatabaseForPath(hiveDatabasePath);
                            setState(() {
                              fetchDataByDate(false);
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 5,
                                    spreadRadius: 1),
                              ],
                            ),
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              "Get Data From Cloud",
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Optional Highlights Button
                ],
              ),
            if (auctions.isNotEmpty && !isLoadingData)
              Expanded(
                child: Stack(
                  children: [
                    ScrollablePositionedList.builder(
                      itemScrollController: itemScrollController,
                      physics: AlwaysScrollableScrollPhysics(),
                      reverse: true,
                      padding: EdgeInsets.all(12.0),
                      itemCount: auctions.length,
                      minCacheExtent: 2000,
                      itemBuilder: (context, index) {
                        final auctionItem = auctions[index];
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
                        var itemId, path;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (currentDateNotifier.value !=
                              auctionItem['datetime_id']) {
                            currentDateNotifier.value =
                                auctionItem['datetime_id'];
                          }
                        });


                        final date = extractDate(auctionItem['datetime_id']);
                        final nextDate = index < auctions.length - 1 ? extractDate(auctions[index + 1]['datetime_id']) : null;


                        final showHeader = date != nextDate;

                        return Column(
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (showHeader)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.symmetric(vertical: 8),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        child: text(
                                          text: date,
                                          color: Color(0xff717171),
                                          size: 8,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (ringStatus)
                                  GestureDetector(
                                    onTap: () async {
                                      WebSocketService websocketService =
                                          new WebSocketService();

                                      Map<String, String> a = {
                                        "update-data-of-path":
                                            "update-data-of-path",
                                        "calledDocumentPath": path,
                                        "calledDocumentPathFields":
                                            "device_notification[3].ringAlarm",
                                        "type": "ringAlarmFalse"
                                      };

                                      //sending response to server imp
                                      websocketService.sendMessage(a);

                                      setState(() {
                                        fetchDataByDate(false);
                                      });

                                      haptic();
                                    },
                                    child: Padding(
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
                                                        shape: BoxShape.circle,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              3),
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
                                                                                GestureDetector(
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
                                            )
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
                                        if (!appBarTitle
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
                                                              color: Colors.grey
                                                                  .shade300,
                                                              blurRadius: 0.5,
                                                            ),
                                                          ],
                                                        ),
                                                        child: text(
                                                            text: item.trim(),
                                                            size: 7.sp,
                                                            color: Color(
                                                                0xff717171),
                                                            fontWeight:
                                                                FontWeight
                                                                    .w400),
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
                                                width: 70,
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    setState(() {
                                                      buttonloading =
                                                          "${auctionItem['id']} + ${buttonData.keys.toList()[0]}";
                                                    });

                                                    await dynamicDialog(
                                                        context,
                                                        button,
                                                        hiveDatabasePath,
                                                        auctionItem[
                                                                'datetime_id']
                                                            .toString(),
                                                        int.parse(buttonData.keys
                                                                .toList()[0]
                                                                .toString()
                                                                .replaceAll(
                                                                    "button",
                                                                    "")) -
                                                            1,
                                                        buttonData.keys
                                                            .toList()[0],
                                                        buttonText,
                                                        data['h1']!,
                                                        showDialogPopup);

                                                    showTopSnackBar(
                                                      Overlay.of(context),
                                                      displayDuration: Duration(
                                                          milliseconds: 100),
                                                      animationDuration:
                                                          Duration(
                                                              milliseconds:
                                                                  500),
                                                      CustomSnackBar.info(
                                                        message:
                                                            "Fetching dialog, please wait..",
                                                      ),
                                                    );

                                                    await syncFirestoreFromDocIdTimestamp(
                                                        hiveDatabasePath,
                                                        HiveHelper.getLast(
                                                                hiveDatabasePath)?[
                                                            'datetime_id'],
                                                        false);

                                                    setState(() {
                                                      fetchDataByDate(false);
                                                    });
                                                    haptic();
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    child: Column(
                                                      children: [
                                                        if (buttonloading.contains(
                                                            "${auctionItem['id']} + ${buttonData.keys.toList()[0]}"))
                                                          const SizedBox(
                                                              width: 10,
                                                              height: 10,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                color: Colors
                                                                    .black54,
                                                              ))
                                                        else
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
                                                                    18),
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
                                                                size: 8.sp,
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        SizedBox(height: 10),
                                        // Compact datetime
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            text(
                                              text: formatToIST(
                                                  auctionItem['datetime_id']),
                                              size: 8,
                                              color: Color(0xff717171),
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ],
                                        ),

                                        if (actionDoneList != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
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
                                        // Divider
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    Positioned(
                        bottom: 50,
                        right: 20,
                        child: GestureDetector(
                            onTap: () {
                              haptic();
                              setState(() {
                              seenCounter = 0;
                              });
                              scrollToBottom();
                            },
                            child: const Icon(
                              Icons.expand_circle_down_sharp,
                              size: 40,
                            ))),
                    if (seenCounter > 0)
                      Positioned(
                        bottom: 70,
                        right: 20,
                        child: Container(
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.green),
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

  void _toggleTab([bool? toLive]) {
    setState(() {
      if (toLive != null) {
        isLive = toLive;
      } else {
        isLive = !isLive;
      }

      // if (widget.showHighlightsButton) {
      //   if (hightlightTitle == "Highlights") {
      //     auctions.clear();
      //     widget.subSubCollection = "highlights";
      //     assignThingsForRespectedScreen();
      //     setAppBarTitle();
      //     hightlightTitle = "Live";
      //   } else if (hightlightTitle == "Live") {
      //     auctions.clear();
      //     widget.subSubCollection = "auctions";
      //     assignThingsForRespectedScreen();
      //     setAppBarTitle();
      //     hightlightTitle = "Highlights";
      //   }
      //   fetchDataByDate(false);
      // }
    });
  }

  Widget buildTabSwitcher() {
    return GestureDetector(
      onTap: _toggleTab,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0) {
            _toggleTab(false); // Swipe Left -> Highlights
          } else {
            _toggleTab(true); // Swipe Right -> Live
          }
        }
      },
      child: Container(
        width: 200,
        height: 25,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: Duration(milliseconds: 300),
              alignment: isLive ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                  color: Color(0xffFFE6E6),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Live",
                      style: GoogleFonts.poppins(
                        color: isLive ? Color(0xffFF6B6B) : Colors.black,
                        fontWeight: FontWeight.w300,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Highlights",
                      style: GoogleFonts.poppins(
                          color: !isLive ? Color(0xffFF6B6B) : Colors.black,
                          fontWeight: FontWeight.w300,
                          fontSize: 12.sp),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void showSyncDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext ctx) {
        dialogContext = ctx; // Save context
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 12,
                  )),
              SizedBox(height: 20),
              text(
                text: 'Cloud sync is in progress...Do not close the app.',
                fontWeight: FontWeight.w300,
                color: Colors.black,
                size: 8,
              ),
            ],
          ),
        );
      },
    );
  }

}




