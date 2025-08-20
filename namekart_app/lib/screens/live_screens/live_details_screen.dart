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
import 'package:namekart_app/custom_widget/CalendarSlider.dart';
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
import '../../custom_widget/_HashtagInputWidgetState.dart';
import '../../custom_widget/customSyncWidget.dart';

// (The LiveDetailsScreen StatefulWidget remains the same)
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
  // All your state variables and methods remain here...
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


  // --- All your functions (initState, initialSetup, etc.) remain unchanged ---
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

    await DbSqlHelper.markAllAsRead(hiveDatabasePath);

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
          Haptics.vibrate(HapticsType.light);

          if (widget.scrollToDatetimeId != "") {
            scrollToDate(widget.scrollToDatetimeId);
          }
        });
      });
    });

    if (rebuild) {
      showSyncDialog(context);

      Future.delayed(const Duration(seconds: 30), () {
        if(Navigator.of(dialogContext).canPop()){
          Navigator.of(dialogContext, rootNavigator: true).pop();
        }
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
        message: "The dialog has loaded. If it hasn’t opened, please tap the button again.",
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
    appBarTitle = "${widget.subCollection}/${widget.subSubCollection.capitalize()}";
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
    final index = auctions.lastIndexWhere(
            (item) => (item['datetime_id'])?.toString()?.trim() == date.trim());

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
  void dispose()  {
    _enterAmountController.removeListener(getEnteredCustomAmount);
    _enterAmountController.dispose();
    _subscriptionForButtons?.cancel();
    liveDatabaseChange.removeListener(fetchNewAuction);
    databaseDataUpdatedNotifier.removeListener(updateChangesAndUI);
    super.dispose();
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 24.0,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Container(
            width: 150.0,
            height: 16.0,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 10),
          Container(
            width: 200.0,
            height: 16.0,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  /// CHANGE 1: This widget is refactored for a grid layout.
  /// It now fills the grid cell and centers its content.
  Widget _buildActionButton(BuildContext context, Map<dynamic, dynamic> auctionItem, Map<dynamic, dynamic> buttonData) {
    final button = buttonData.values.first as Map<dynamic, dynamic>;
    final buttonText = button['button_text'] as String;
    final buttonKey = "${auctionItem['id']} + ${buttonData.keys.toList()[0]}";
    final actionDoneList = auctionItem['actionsDone'] as List<dynamic>? ?? [];

    bool isWatched = actionDoneList.toString().contains("Watch") && buttonText.contains("Watch");
    String displayText = isWatched ? "Remove Watch" : buttonText;

    return Bounceable(
      onTap: () async {
        setState(() {
          buttonloading = buttonKey;
        });

        haptic();

        if (GlobalProviders.loadedDynamicDialogAgain) {
          GlobalProviders.loadedDynamicDialogAgain = false;
        }

        await dynamicDialog(
            context,
            button,
            hiveDatabasePath,
            auctionItem['datetime_id'].toString(),
            int.parse(buttonData.keys.toList()[0].toString().replaceAll("button", "")) - 1,
            buttonData.keys.toList()[0],
            buttonText,
            auctionItem['data']['h1']!,
            showDialogPopup);

        showTopSnackBar(
            Overlay.of(context),
            displayDuration: Duration(milliseconds: 100),
            animationDuration: Duration(milliseconds: 500),
            CustomSnackBar.info(message: "Fetching dialog, please wait.."));

        var lastItem = await DbSqlHelper.getLast(hiveDatabasePath);
        await syncFirestoreFromDocIdTimestamp(hiveDatabasePath, lastItem?['datetime_id'], false);

        setState(() {
          fetchDataByDate(false);
        });

        Future.delayed(Duration(seconds: 5), () {
          resetButtonLoading();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isWatched ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: buttonloading.contains(buttonKey)
            ? Center(
          child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade700,
              )),
        )
            : Row(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF0F2F5),
      appBar: AppBar(
        elevation: 10,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black26,
        iconTheme: const IconThemeData(color: Colors.black, size: 20),
        actions: [
          SizedBox(
            width: 10,
          ),
          Bounceable(
            onTap: () {
              setState(() {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.5,
                    minChildSize: 0.5,
                    maxChildSize: 1.0,
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
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                color: Colors.black)),
        titleSpacing: 0,
      ),
      body: AlertWidget(
        onReconnectSuccess: () async {
          // The AlertWidget and its logic remains the same
        },
        path: hiveDatabasePath,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (widget.showHighlightsButton && !isLoadingData)
            //   Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            //     child: buildTabSwitcher(), // Refined switcher
            //   ),
            if (isLoadingData)
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildShimmerCard(),
                ),
              ),
            if (auctions.isEmpty && !isLoadingData)
              _buildEmptyState(), // Refined empty state

            if (auctions.isNotEmpty && !isLoadingData)
              Expanded(
                child: Stack(
                  children: [
                    ScrollablePositionedList.builder(
                      itemScrollController: itemScrollController,
                      itemPositionsListener: !searched ? itemPositionsListener : null,
                      physics: const BouncingScrollPhysics(),
                      reverse: true,
                      padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
                      itemCount: auctions.length + (isLoadingMore ? 1 : 0),
                      minCacheExtent: 2000,
                      itemBuilder: (context, index) {
                        if (index == auctions.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: Colors.deepPurple),
                            ),
                          );
                        }

                        final auctionItem = auctions[index];
                        final date = extractDate(auctionItem['datetime_id']);
                        final nextDate = index < auctions.length - 1
                            ? extractDate(auctions[index + 1]['datetime_id'])
                            : null;
                        final showHeader = date != nextDate;

                        return Column(
                          children: [
                            if (showHeader)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
                                  date,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            _buildAuctionCard(auctionItem)
                          ],
                        );
                      },
                    ),
                    _buildFloatingActionButton(), // Refined FAB
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionCard(Map<dynamic, dynamic> auctionItem) {
    var data = auctionItem['data'] as Map<dynamic, dynamic>;
    var uiButtons = auctionItem['uiButtons'] as List<dynamic>?;
    var actionDoneList = auctionItem['actionsDone'] as List<dynamic>? ?? [];
    bool ringStatus = (auctionItem['device_notification']?.toString() ?? "").contains("ringAlarm: true");
    String readStatus = auctionItem['read'] ?? 'yes';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: ringStatus ? Border.all(color: Colors.redAccent.withOpacity(0.8), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ringStatus)
              GestureDetector(
                onTap: () {
                  Map<String, String> a = {
                    "update-data-of-path": "update-data-of-path",
                    "calledDocumentPath": hiveDatabasePath,
                    "calledDocumentPathFields": "device_notification[3].ringAlarm",
                    "type": "ringAlarmFalse"
                  };
                  websocketService.sendMessage(a);
                  setState(() { fetchDataByDate(false); });
                  haptic();
                },
                child: Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_active, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Acknowledge Alarm",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (readStatus == "no")
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, top: 6),
                          child: CircleAvatar(radius: 4, backgroundColor: Color(0xff4CAF50)),
                        ),
                      Expanded(
                        child: Text(
                          data['h1'] ?? 'No Title',
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
                          hiveDatabasePath,
                          auctionItem['datetime_id'],
                        ),
                        builder: (context, snapshot) {
                          return buildStarToggleButton(
                            isStarred: snapshot.data ?? false,
                            onStarredClicked: () async {
                              await DbAccountHelper.addStar("account~user~details", GlobalProviders.userId, hiveDatabasePath, auctionItem['datetime_id']);
                              final getStars = await DbAccountHelper.getStar("account~user~details", GlobalProviders.userId);
                              Map<String, dynamic> a = {"query": "update-star", "path": "account~${GlobalProviders.userId}~stars", "stars_info": getStars};
                              websocketService.sendMessage(a);
                              setState(() {});
                            },
                            onNotStarredClicked: () async {
                              await DbAccountHelper.deleteStar("account~user~details", GlobalProviders.userId, hiveDatabasePath, auctionItem['datetime_id']);
                              final getStars = await DbAccountHelper.getStar("account~user~details", GlobalProviders.userId);
                              Map<String, dynamic> a = {"query": "update-star", "path": "account~${GlobalProviders.userId}~stars", "stars_info": getStars};
                              websocketService.sendMessage(a);
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  if (appBarTitle.contains("Highlights"))
                    _buildHighlightsTable(data),
                  if (!appBarTitle.contains("Highlights"))
                    _buildDetailsWrap(data),

                  SizedBox(height: 16.h),

                  /// CHANGE 2: The Wrap widget is replaced by GridView.count for a 3-column grid.
                  if (uiButtons != null && uiButtons.isNotEmpty)
                    GridView.count(
                      crossAxisCount: 3, // Defines 3 columns
                      shrinkWrap: true, // Needed to embed a grid in a scrollable list
                      physics: const NeverScrollableScrollPhysics(), // Delegate scrolling to the parent list
                      crossAxisSpacing: 8, // Horizontal space between buttons
                      mainAxisSpacing: 8,  // Vertical space between buttons
                      childAspectRatio: 2.5, // Adjust for desired button proportions (width/height)
                      children: uiButtons
                          .map((buttonData) => _buildActionButton(context, auctionItem, buttonData))
                          .toList(),
                    ),

                  Divider(color: Colors.grey.shade200),

                  createHashtagAndNotesInputWidget(
                    initialHashtags: (auctionItem['hashtags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                    initialNotes: (auctionItem['notes'] as List?)?.map((e) => (e as Map?)?.map((k, v) => MapEntry(k.toString(),v.toString()),) ?? {}).toList() ?? [],
                    notesAuthorName: GlobalProviders.userId,
                    onHashtagsChanged: (newHashtags) {
                      Map<String, dynamic> a = {"query": "update-hashtags", "calledDocumentPath": "$hiveDatabasePath~${auctionItem['datetime_id']}", "update_hashtags": newHashtags};
                      websocketService.sendMessage(a);
                    },
                    onNotesChanged: (newNotes) {
                      Map<String, dynamic> a = {"query": "update-notes", "calledDocumentPath": "$hiveDatabasePath~${auctionItem['datetime_id']}", "update_notes": newNotes};
                      websocketService.sendMessage(a);
                    },
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
          ],
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

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          haptic();
          setState(() { seenCounter = 0; });
          scrollToBottom();
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              if (seenCounter > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2)
                    ),
                    constraints: BoxConstraints(minWidth: 22, minHeight: 22),
                    child: Center(
                      child: Text(
                        seenCounter.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/bubbles_images/clouddatabase.png", width: 150),
            SizedBox(height: 20),
            Text(
              "No Local Data Available",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Would you like to fetch it from the cloud to get started?",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                haptic();
                showSyncDialog(context);
                await getFullDatabaseForPath(hiveDatabasePath);
                if(Navigator.of(dialogContext).canPop()){
                  Navigator.pop(dialogContext);
                }
                setState(() {
                  fetchDataByDate(false);
                });
              },
              icon: Icon(Icons.cloud_download_rounded, size: 20),
              label: Text("Fetch From Cloud"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTab([bool? toLive]) {
    setState(() {
      isLive = toLive ?? !isLive;
    });
  }

  Widget buildTabSwitcher() {
    return GestureDetector(
        onTap: () => _toggleTab(),
        child: Container(
            height: 45,
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30)),
            child: Stack(
                children: [
                  AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: isLive ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 40) / 2,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5)
                            ]
                        ),
                      )
                  ),
                  Row(
                      children: [
                        Expanded(child: Center(child: Text("Live", style: GoogleFonts.poppins(color: isLive ? Colors.black : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 10.sp)))),
                        Expanded(child: Center(child: Text("Highlights", style: GoogleFonts.poppins(color: !isLive ? Colors.black : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 10.sp)))),
                      ]
                  )
                ]
            )
        )
    );
  }

  void showSyncDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext ctx) {
        dialogContext = ctx; // Save context
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.all(25),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.black),
              SizedBox(height: 25),
              Text(
                'Cloud sync in progress...',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 10),
              ),
              SizedBox(height: 8),
              Text(
                'Please don\'t close the app.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w400, color: Colors.grey.shade600, fontSize: 10),
              ),
            ],
          ),
        );
      },
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
}