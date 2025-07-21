import 'dart:async';
import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:namekart_app/activity_helpers/DbAccountHelper.dart';
import 'package:namekart_app/activity_helpers/FirestoreHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:namekart_app/cutsom_widget/CalendarSlider.dart';
import 'package:namekart_app/fcm/FcmHelper.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/safe_area_values.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../activity_helpers/DbSqlHelper.dart';
import '../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../../activity_helpers/GlobalVariables.dart';
import '../../activity_helpers/UIHelpers.dart';
import '../../change_notifiers/WebSocketService.dart';
import '../../cutsom_widget/_HashtagInputWidgetState.dart';
import '../../cutsom_widget/customSyncWidget.dart';

class LiveDetailsScreen extends StatefulWidget {
  String img,
      mainCollection,
      subCollection,
      subSubCollection,
      scrollToDatetimeId;
  bool showHighlightsButton;

  LiveDetailsScreen(
      {super.key,
      required this.img,
      required this.mainCollection,
      required this.subCollection,
      required this.subSubCollection,
      required this.showHighlightsButton,
      required this.scrollToDatetimeId});

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
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  final TextEditingController _enterAmountController = TextEditingController();
  TextEditingController searchQueryController = TextEditingController();

  String buttonloading = "";

  AnimationController? syncFirebaseController;

  bool showUi = true;

  late BuildContext dialogContext;

  bool isLoadingData = true;

  ValueNotifier<String?> currentDateNotifier = ValueNotifier<String?>(null);

  final Map<String, GlobalKey> dateKeys = {};

  bool isLoadingMore = false;
  bool hasMoreItems = true;

  bool searched = false;

  WebSocketService websocketService = WebSocketService();

  @override
  void initState() {
    super.initState();

    assignThingsForRespectedScreen();
    setAppBarTitle();

    initialSetup();

    Future.delayed(Duration(seconds: 3), () {


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

      itemPositionsListener.itemPositions.addListener(() {
        final positions = itemPositionsListener.itemPositions.value;

        final maxIndex = positions.isNotEmpty
            ? positions.map((e) => e.index).reduce((a, b) => a > b ? a : b)
            : null;

        if (maxIndex != null &&
            maxIndex >= auctions.length - 1 &&
            !isLoadingMore &&
            !searched &&
            hasMoreItems) {
          // ✅ add guard

          setState(() {
            isLoadingMore = true;
          });

          final latestDatetimeId = auctions.last['datetime_id'];

          addCloud10PreviousItems(latestDatetimeId).then((newItems) {
            setState(() {
              isLoadingMore = false;
              if (newItems.isEmpty) {
                hasMoreItems = false; // ✅ stop forever
              }
            });
          });
        }

        if (positions.isNotEmpty) {
          final visibleIndex =
              positions.map((e) => e.index).reduce((a, b) => a > b ? a : b);
          final visibleItem = auctions[visibleIndex];
          final visibleDatetimeId = visibleItem['datetime_id'];

          if (currentDateNotifier.value != visibleDatetimeId) {
            currentDateNotifier.value = visibleDatetimeId;
          }
        }
      });
    });
  }

  Future<List<Map<String, dynamic>>> addCloud10PreviousItems(
      String beforeDatetimeId) async {
    final got10Previous =
        await get10BeforeTimestamp(hiveDatabasePath, beforeDatetimeId);

    setState(() {
      auctions.addAll(got10Previous.reversed);
    });

    return got10Previous; // ✅ let listener know
  }

  Future<void> initialSetup() async {
    if (await DbSqlHelper.getLast(hiveDatabasePath) != null) {
      syncToFirestore();
      fetchDataByDate(false);
      FCMHelper().subscribeToTopic("godaddy");
    }
  }

  Future<bool> syncToFirestore() async {
    var lastItem = await DbSqlHelper.getLast(hiveDatabasePath);
    String datetime_id = lastItem?['datetime_id'];

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

    hiveDatabasePath =
        "${widget.mainCollection}~${widget.subCollection}~${widget.subSubCollection}";
  }

  fetchDataByDate(bool rebuild) async {
    var rawData = await DbSqlHelper.getFullData(hiveDatabasePath);
    auctions = rawData;
    setState(() {
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          isLoadingData = false;
          Haptics.vibrate(HapticsType.error);

          if (widget.scrollToDatetimeId != "") {
            scrollToDate(widget.scrollToDatetimeId);
          }
        });
      });
    }); // Trigger UI rebuild after parsing

    if (rebuild) {
      showSyncDialog(context);

      Future.delayed(const Duration(seconds: 30), () {
        Navigator.of(dialogContext, rootNavigator: true).pop();
      });
    }
  }

  void fetchNewAuction() async {
    final item = await DbSqlHelper.getLast(hiveDatabasePath);
    if (mounted &&
        calenderSelectedDate.formattedDate.contains(todayDate.formattedDate)) {
      setState(() {
        auctions.insert(0, item!);
        if (seenCounter < 0) {
          seenCounter = 0;
        }
        seenCounter += 1;
      });
    }
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

  Future<void> updateChangesAndUI() async {
    String path = databaseDataUpdatedNotifier.getPathOfUpdatedDocument();
    String id = path.split("~").last;
    var updatedData = await DbSqlHelper.getById(path, id);
    if (updatedData == null) return;
    setState(() {
      int index =
          auctions.indexWhere((element) => element['datetime_id'] == id);
      if (index != -1) {
        auctions[index] = updatedData;
      }
    });

    resetButtonLoading();
  }

  void setAppBarTitle() {
    appBarTitle =
        "${widget.subCollection}/${widget.subSubCollection.capitalize()}";
  }

  void getSearchedText() {
    setState(() {
      searchText = searchQueryController.text;
    });
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
    print("Looking for date: $date");
    for (var item in auctions) {
      final itemDate = item['datetime_id'];
      print("Comparing item date: $itemDate");
    }

    final index = auctions.lastIndexWhere(
        (item) => (item['datetime_id'])?.toString()?.trim() == date.trim());

    print("Found index: $index");

    if (index != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        itemScrollController.scrollTo(
          index: index,
          duration: Duration(milliseconds: 500),
          alignment: 0.4,
        );
      });
    } else {
      showTopSnackBar(
        Overlay.of(context),
        displayDuration: Duration(milliseconds: 100),
        animationDuration: Duration(milliseconds: 500),
        CustomSnackBar.error(
          message: "No items found for $date",
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
    await DbSqlHelper.markAllAsRead(hiveDatabasePath);
    _enterAmountController.removeListener(getEnteredCustomAmount);
    _enterAmountController.dispose();
    _subscriptionForButtons?.cancel();
    liveDatabaseChange.removeListener(fetchNewAuction);
    databaseDataUpdatedNotifier.removeListener(updateChangesAndUI);
    super.dispose();
  }

  void scrollToAuctionByDatetimeId(String datetimeId) {
    final index = auctions.indexWhere((auction) {
      final id = auction["datetime_id"]?.toString();
      return id == datetimeId;
    });

    if (index != -1) {
      itemScrollController.scrollTo(
        index: index,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      print("✅ Scrolled to index $index for datetime_id: $datetimeId");
    } else {
      print("❌ datetime_id '$datetimeId' not found in auctions list");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF7F7F7),
      //---  top appbar code here
      appBar: AppBar(
        elevation: 10,
        backgroundColor: Color(0xffF7F7F7),
        surfaceTintColor: Color(0xffF7F7F7),
        iconTheme: const IconThemeData(color: Colors.black, size: 15),
        actions: [
          SizedBox(
            width: 10,
          ),
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
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, right: 20),
                                child: GestureDetector(
                                  onTap: () async {
                                    showSyncDialog(context);
                                    haptic();
                                    await getFullDatabaseForPath(
                                        hiveDatabasePath);
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.sync_rounded,
                                            color: Colors.white,
                                            size: 17,
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
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
                                    width:
                                        MediaQuery.of(context).size.width - 20,
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
                                    searched = true;

                                    if (searchText.isNotEmpty) {
                                      var filtered =
                                          await DbSqlHelper.searchInDataList(
                                              auctions, searchText);

                                      setState(() {
                                        auctions = filtered;
                                      });

                                      AnimationController?
                                          topSnackBarController;

                                      showTopSnackBar(
                                        Overlay.of(context),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xFFB71C1C),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 10),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Search Filter: $searchText",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontSize: 8.sp,
                                                    decoration:
                                                        TextDecoration.none,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    topSnackBarController
                                                        ?.reverse(); // manually close
                                                    await fetchDataByDate(
                                                        false); // restore full list

                                                    setState(() {
                                                      searched = false;
                                                      searchText = "";
                                                      searchQueryController
                                                          .clear();
                                                    });
                                                  },
                                                  icon: Icon(
                                                      Icons.close_rounded,
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        persistent: true,
                                        dismissType: DismissType.none,
                                        onAnimationControllerInit:
                                            (controller) {
                                          topSnackBarController = controller;
                                        },
                                      );
                                    }

                                    scrollToDate(extractDate(
                                        calenderSelectedDate.formattedDate
                                            .toString()));

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
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: text(
                      text: extractDate(date),
                      // Format it as "June 27, 2025" or "3:40 PM"
                      color: Colors.white,
                      size: 8,
                      fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Container(
            width: 2,
            height: 25.sp,
            color: Colors.black12,
          ),
          IconButton(
            onPressed: () {},
            icon: Image.asset(
              widget.img,
              width: 17.sp,
              height: 17.sp,
            ),
          )
        ],
        title: TextScroll(
            velocity: Velocity(pixelsPerSecond: Offset(20, 20)),
            pauseBetween: Duration(seconds: 3),
            appBarTitle.capitalize(),
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
                color: Colors.black54)),
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
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
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
            if (isLoadingMore)
              const Center(
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
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
            if (auctions.isNotEmpty && !isLoadingData)
              Expanded(
                child: Stack(
                  children: [
                    ScrollablePositionedList.builder(
                      itemScrollController: itemScrollController,
                      itemPositionsListener:
                          !searched ? itemPositionsListener : null,
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

                        final date = extractDate(auctionItem['datetime_id']);
                        final nextDate = index < auctions.length - 1
                            ? extractDate(auctions[index + 1]['datetime_id'])
                            : null;

                        final showHeader = date != nextDate;

                        print(auctionItem['notes']);

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
                                  GestureDetector(
                                    onTap: () async {
                                      Map<String, String> a = {
                                        "update-data-of-path":
                                            "update-data-of-path",
                                        "calledDocumentPath": hiveDatabasePath,
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
                                  margin: const EdgeInsets.only(top: 10),
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
                                                                                style: GoogleFonts.poppins(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
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
                                                                color: Colors
                                                                    .black12,
                                                                blurRadius: 3,
                                                                blurStyle:
                                                                    BlurStyle
                                                                        .outer),
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
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    setState(() {
                                                      buttonloading =
                                                          "${auctionItem['id']} + ${buttonData.keys.toList()[0]}";
                                                    });

                                                    if (GlobalProviders
                                                        .loadedDynamicDialogAgain) {
                                                      GlobalProviders
                                                              .loadedDynamicDialogAgain =
                                                          false;
                                                    }

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
                                                    var lastItem =
                                                        await DbSqlHelper.getLast(
                                                            hiveDatabasePath);
                                                    await syncFirestoreFromDocIdTimestamp(
                                                        hiveDatabasePath,
                                                        lastItem?[
                                                            'datetime_id'],
                                                        false);

                                                    setState(() {
                                                      fetchDataByDate(false);
                                                    });
                                                    haptic();

                                                    Future.delayed(
                                                        Duration(seconds: 5),
                                                        () {
                                                      resetButtonLoading();
                                                    });
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
                                                future:
                                                    DbAccountHelper.isStarred(
                                                        "account~user~details",
                                                        GlobalProviders.userId,
                                                        hiveDatabasePath,
                                                        auctionItem[
                                                            'datetime_id']),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasError) {
                                                    return Text(
                                                        'Error: ${snapshot.error}');
                                                  } else {
                                                    bool isStarred =
                                                        snapshot.data ?? false;

                                                    return buildStarToggleButton(
                                                        isStarred: isStarred,
                                                        onStarredClicked:
                                                            () async {
                                                          await DbAccountHelper.addStar(
                                                              "account~user~details",
                                                              GlobalProviders
                                                                  .userId,
                                                              hiveDatabasePath,
                                                              auctionItem[
                                                                  'datetime_id']);

                                                          final getStars =
                                                              await DbAccountHelper.getStar(
                                                                  "account~user~details",
                                                                  GlobalProviders
                                                                      .userId);
                                                          Map<String, dynamic>
                                                              a = {
                                                            "query":
                                                                "update-star",
                                                            "path":
                                                                "account~${GlobalProviders.userId}~stars",
                                                            "stars_info":
                                                                getStars
                                                          };

                                                          websocketService
                                                              .sendMessage(a);

                                                          setState(() {
                                                            isStarred = true;
                                                          });
                                                        },
                                                        onNotStarredClicked:
                                                            () async {
                                                          await DbAccountHelper.deleteStar(
                                                              "account~user~details",
                                                              GlobalProviders
                                                                  .userId,
                                                              hiveDatabasePath,
                                                              auctionItem[
                                                                  'datetime_id']);

                                                          final getStars =
                                                              await DbAccountHelper.getStar(
                                                                  "account~user~details",
                                                                  GlobalProviders
                                                                      .userId);
                                                          Map<String, dynamic>
                                                              a = {
                                                            "query":
                                                                "update-star",
                                                            "path":
                                                                "account~${GlobalProviders.userId}~stars",
                                                            "stars_info":
                                                                getStars
                                                          };

                                                          websocketService
                                                              .sendMessage(a);

                                                          setState(() {
                                                            isStarred = false;
                                                          });
                                                        });
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
                                              initialHashtags: (auctionItem[
                                                              'hashtags']
                                                          as List<dynamic>?)
                                                      ?.map((e) => e.toString())
                                                      .toList() ??
                                                  [],
                                              initialNotes:
                                                  (auctionItem['notes']
                                                              as List?)
                                                          ?.map((e) =>
                                                              (e as Map?)?.map(
                                                                (k, v) => MapEntry(
                                                                    k.toString(),
                                                                    v.toString()),
                                                              ) ??
                                                              {})
                                                          .toList() ??
                                                      [],
                                              // Pass the item's notes
                                              notesAuthorName:
                                                  GlobalProviders.userId,
                                              onHashtagsChanged: (newHashtags) {
                                                setState(() {
                                                  Map<String, dynamic> a = {
                                                    "query": "update-hashtags",
                                                    "calledDocumentPath":
                                                        "$hiveDatabasePath~${auctionItem['datetime_id']}",
                                                    "update_hashtags":
                                                        newHashtags
                                                  };

                                                  websocketService
                                                      .sendMessage(a);

                                                  print(newHashtags);
                                                });
                                              },
                                              onNotesChanged: (newNotes) {
                                                // Handle notes changes
                                                setState(() {
                                                  Map<String, dynamic> a = {
                                                    "query": "update-notes",
                                                    "calledDocumentPath":
                                                        "$hiveDatabasePath~${auctionItem['datetime_id']}",
                                                    "update_notes": newNotes
                                                  };

                                                  websocketService
                                                      .sendMessage(a);
                                                  print(newNotes);
                                                  // Update the specific auctionItem in your main list
                                                  // Persist this change (e.g., to Hive or Firebase)
                                                  // HiveHelper.updateDocument(hiveDatabasePath, auctionItem['datetime_id'], {'custom_notes': newNotes});
                                                  // print('Notes for ${auctionItem['h1']} updated to: $newNotes');
                                                });
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
                        fontWeight: FontWeight.bold,
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
                          fontWeight: FontWeight.bold,
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
