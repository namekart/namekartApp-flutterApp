import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/activity_helpers/NotificationSettingsHelper.dart';
import 'package:namekart_app/cutsom_widget/AnimatedSlideTransition.dart';
import 'package:namekart_app/screens/features/BiddingListAndWatchListScreen.dart';
import 'package:namekart_app/screens/features/WatchlistScreen.dart'; // This might be redundant if BiddingListAndWatchListScreen handles both
import 'package:namekart_app/screens/features/BulkBid.dart';
import 'package:namekart_app/screens/features/BulkFetch.dart';
import 'package:namekart_app/screens/home_screen/tabs/channels_tab.dart';
import 'package:namekart_app/screens/live_screens/live_details_screen.dart';
import 'package:namekart_app/screens/search_screen/SearchScreen.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:provider/provider.dart';
import '../../../activity_helpers/DbSqlHelper.dart';
import '../../../activity_helpers/FirestoreHelper.dart';
import '../../../activity_helpers/GlobalFunctions.dart';
import '../../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import 'package:animations/animations.dart'; // IMPORT THIS PACKAGE

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<String> ringAlarmActiveList = [];
  late NotificationDatabaseChange notificationDatabaseChange;
  late NotificationPathNotifier notificationPathNotifier;

  late VoidCallback _syncListener;
  static bool hasSyncedAlready = false;

  late BuildContext dialogContext;

  int readDropcatch = 0;
  int readDynadot = 0;
  int readGodaddy = 0;
  int readNamecheap = 0;
  int readNamesilo = 0;
  int readSav = 0;

  @override
  void initState() {
    super.initState();
    getRingAlarmList();

    _syncListener = () => Future.delayed(Duration(seconds: 1), () async {
      await syncAllPaths(context);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notificationPathNotifier =
          Provider.of<NotificationPathNotifier>(context, listen: false);
      notificationPathNotifier.addListener(_syncListener);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clean up old listener if it exists
      notificationDatabaseChange =
          Provider.of<NotificationDatabaseChange>(context, listen: false);
      notificationDatabaseChange.addListener(getReadCount);
    });

    getReadCount();
  }

  Future<void> getReadCount() async {
    readGodaddy = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-GD");
    readDynadot = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-DD");
    readDropcatch = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-DC");
    readNamecheap = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-NC");
    readNamesilo = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-NS");
    readSav = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-SAV");

    if (mounted) {
      setState(() {});
    }

    print(
        "readDropcatch: $readDropcatch, readDynadot: $readDynadot, readGodaddy: $readGodaddy, readNamecheap: $readNamecheap, readNamesilo: $readNamesilo, readSav: $readSav");
  }

  Future<void> syncAllPaths(BuildContext context) async {
    if (!hasSyncedAlready) {
      showSyncDialog(context);
      NotificationSettingsHelper.subscribeToAllNotificationsIfNoneSet(GlobalProviders.userId);
      try {
        final readedData = await readAllCloudPath();
        final outerDecoded = jsonDecode(readedData!);
        final dataField = outerDecoded['data'];
        final innerDecoded = dataField is String ? jsonDecode(dataField) : dataField;
        final responseRaw = innerDecoded['response'];
        final List<dynamic> paths = responseRaw is String ? jsonDecode(responseRaw) : responseRaw;
        await DbSqlHelper.removeDataKeepingLatestTwoDaysPerPath(paths.cast<String>());
        for (final String path in paths) {
          try {
            var lastItem = await DbSqlHelper.getLast(path.toString());
            if (lastItem?['datetime_id'] != null) {
              String lastDatetime_id = lastItem?["datetime_id"];
              await syncFirestoreFromDocIdTimestamp(path, lastDatetime_id, false);
            } else {
              await getLatestDocuments(path);
            }
          } catch (e) {
            print('Error syncing $path: $e');
            // Optionally log or retry this path later
          }
        } // Correct context — only dismisses the dialog
      } catch (e, st) {
        print('Failed to start sync: $e');
        print(st);
      }
      Navigator.of(context, rootNavigator: true).pop();
      notificationPathNotifier.removeListener(_syncListener);
      hasSyncedAlready = true;
    }
    await getReadCount();
  }

  Future<void> getRingAlarmList() async {
    var ringalarm = await DbSqlHelper.getRingAlarmPaths();
    setState(() {
      ringAlarmActiveList = ringalarm
          .where((e) => !e.startsWith("live~all"))
          .map((e) => e.split("~").take(3).join("~"))
          .toSet()
          .toList();
    });
  }

  @override
  void dispose() {
    notificationDatabaseChange.removeListener(getReadCount); // Remove listener here
    // _syncListener is removed in syncAllPaths, so no need to remove here if it always runs once.
    // If it might not run (e.g., if hasSyncedAlready is true from start),
    // you might want to add notificationPathNotifier.removeListener(_syncListener); here as well
    // to be safe, but only if _syncListener is never removed inside syncAllPaths.
    // Given current logic, it's removed after first successful sync.
    ringAlarmActiveList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xffF7F7F7),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedSlideTransition(
              animationType: BoxAnimationType.fadeInFromTop,
              duration: const Duration(seconds: 1),
              child: _buildSearchBar(context)),
          AnimatedSlideTransition(
            animationType: BoxAnimationType.fadeInFromBottom,
            duration: const Duration(seconds: 1),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [
                    _sectionHeader("Live Status", onSeeAllTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveDetailsScreen(
                            img: "assets/images/bubbles_images/seeall.png",
                            mainCollection: "live",
                            subCollection: "all",
                            subSubCollection: "auctions",
                            showHighlightsButton: true,
                            scrollToDatetimeId: "",
                          ),
                        ),
                      );
                    }),
                    _liveStatusRow(),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSlideTransition(
            animationType: BoxAnimationType.fadeInFromBottom,
            duration: const Duration(seconds: 1),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    children: [
                      _sectionHeader("Auction Tools"),
                      _auctionToolsRow(),
                    ],
                  )),
            ),
          ),
          AnimatedSlideTransition(
            animationType: BoxAnimationType.fadeInFromBottom,
            duration: const Duration(seconds: 1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text(
                      text: "Created For \nYou!",
                      size: 25.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600),
                  text(
                      text: "By Namekart",
                      size: 12.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w300),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Search()));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              text(
                  text: "Find what you need faster",
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff717171),
                  size: 10.sp),
              Image.asset("assets/images/home_screen_images/searchwhite.png",
                  width: 15, height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAllTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          text(
              text: title,
              size: 13.sp,
              color: Colors.black54,
              fontWeight: FontWeight.bold),
          if (onSeeAllTap != null)
            GestureDetector(
              onTap: onSeeAllTap,
              child: text(
                  text: "",
                  fontWeight: FontWeight.bold,
                  color: Colors.black26,
                  size: 8.sp),
            )
        ],
      ),
    );
  }

  Widget _liveStatusRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 15),
      child: Wrap(
        spacing: 30,
        runSpacing: 25,
        children: [
          _LiveStatusImage("livelogos/dropcatch", "Dropcatch"),
          _LiveStatusImage("livelogos/dynadot", "Dynadot"),
          _LiveStatusImage("livelogos/godaddy", "Godaddy"),
          _LiveStatusImage("livelogos/namecheap", "Namecheap"),
          _LiveStatusImage("livelogos/namesilo", "Namesilo"),
          SizedBox(width: 45, child: _LiveStatusImage("livelogos/sav", "SAV")),
        ],
      ),
    );
  }

  Widget _auctionToolsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AuctionToolItem(
            imagePath: "features/biddinglist",
            title: "Bidding List",
            targetScreen: BiddingListAndWatchListScreen(api: "/getBiddingList"),
            closedWidgetColor: Colors.white, // Example color, adjust as needed
          ),
          _AuctionToolItem(
            imagePath: "features/watchlist",
            title: "Watch List",
            targetScreen: BiddingListAndWatchListScreen(api: "/getWatchList"),
            closedWidgetColor: Colors.white,
          ),
          _AuctionToolItem(
            imagePath: "features/bulkbid",
            title: "Bulk Bid",
            targetScreen: BulkBid(),
            closedWidgetColor: Colors.white,
          ),
          _AuctionToolItem(
            imagePath: "features/bulkfetch",
            title: "Bulk Fetch",
            targetScreen: BulkFetch(),
            closedWidgetColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // Modified _LiveStatusImage to use OpenContainer
  Widget _LiveStatusImage(String image, String title) {
    String subSubCollectionName = image.contains("dropcatch")
        ? "Live-DC"
        : image.contains("dynadot")
        ? "Live-DD"
        : image.contains("godaddy")
        ? "Live-GD"
        : image.contains("namecheap")
        ? "Live-NC"
        : image.contains("sav")
        ? "Live-SAV"
        : image.contains("namesilo")
        ? "Live-NS"
        : "";

    String readCount = image.contains("dropcatch")
        ? readDropcatch.toString()
        : image.contains("dynadot")
        ? readDynadot.toString()
        : image.contains("godaddy")
        ? readGodaddy.toString()
        : image.contains("namecheap")
        ? readNamecheap.toString()
        : image.contains("sav")
        ? readSav.toString()
        : image.contains("namesilo")
        ? readNamesilo.toString()
        : "0";

    // Since _LiveStatusImage handles both live logos and features,
    // and we only want OpenContainer for live logos (as per your request for YouTube/Keep style),
    // we'll keep the `image.contains("features")` check outside the OpenContainer.
    // If you want the features to also animate like this, wrap them similarly.
    if (image.contains("features")) {
      return Column(
        children: [
          Image.asset(
            "assets/images/home_screen_images/$image.png",
            width: image.contains("livelogos") ? 27.sp : 23.sp,
            height: image.contains("livelogos") ? 27.sp : 23.sp,
            color: image.contains("livelogos") ? null : Colors.red,
          ),
          const SizedBox(height: 10),
          text(
              text: title,
              size: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w300),
        ],
      );
    }

    return OpenContainer(
      openColor: Colors.white,
      middleColor: Colors.white,
      transitionDuration: const Duration(milliseconds:500), // Adjust as needed
      transitionType: ContainerTransitionType.fadeThrough, // Google Keep style
      closedElevation: 0.0, // Match your current flat look
      closedColor: Colors.white, // Important: make it transparent so the underlying widget is seen
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return Bounceable(
          onTap: () {
            openContainer(); // This triggers the animation to the OpenBuilder
            // Delay the getReadCount after the animation completes or when the screen is popped
            Future.delayed(const Duration(milliseconds: 500), () { // Adjust delay based on transitionDuration
              if (mounted) getReadCount();
            });
          },
          child: Column(children: [
            Image.asset(
              "assets/images/home_screen_images/$image.png",
              width: 27.sp, // Use actual sp values
              height: 27.sp,
              // color: image.contains("livelogos") ? null : Colors.red, // Original color logic
            ),
            const SizedBox(height: 10),
            text(
                text: title,
                size: 10,
                color: Colors.black54,
                fontWeight: FontWeight.w300),
            if (!readCount.contains("0")) ...[
              const SizedBox(
                height: 5,
              ),
              Container(
                child: text(
                    text: "$readCount New!",
                    size: 7.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.w300),
              ),
            ],
          ]),
        );
      },
      openBuilder: (BuildContext context, VoidCallback closeContainer) {
        // This is the screen that the item expands into
        return LiveDetailsScreen(
          img: "assets/images/home_screen_images/$image.png",
          mainCollection: "notifications",
          subCollection: "AMP-LIVE",
          subSubCollection: subSubCollectionName,
          showHighlightsButton: true,
          scrollToDatetimeId: "",
        );
      },
      onClosed: (data) {
        // This callback fires when the opened screen is popped.
        // It's a good place to refresh counts, etc.
        getReadCount();
      },
    );
  }

  // New Widget for Auction Tools to apply OpenContainer
  Widget _AuctionToolItem({
    required String imagePath,
    required String title,
    required Widget targetScreen,
    Color closedWidgetColor = Colors.transparent, // Default background for the icon container
  }) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds:500),
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0.0,
      closedColor: closedWidgetColor, // The color of the "closed" widget (e.g., the white container behind the icon)
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // Adjust if your icon has a specific shape
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return Bounceable(
          onTap: openContainer, // Triggers the animation
          child: Column(
            children: [
              Image.asset(
                "assets/images/home_screen_images/$imagePath.png",
                width: 23.sp,
                height: 23.sp,
                color: Colors.red, // Assuming red color for auction tools
              ),
              const SizedBox(height: 10),
              text(
                  text: title,
                  size: 10,
                  color: Colors.black54,
                  fontWeight: FontWeight.w300),
            ],
          ),
        );
      },
      openBuilder: (BuildContext context, VoidCallback closeContainer) {
        return targetScreen; // The screen that opens
      },
    );
  }

  Widget buildCriticalErrorBanner(
      BuildContext context, List<String> errors, VoidCallback onClear) {
    if (errors.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Critical Error Occurred",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold)),
                  Bounceable(
                    onTap: onClear,
                    child: const Icon(Icons.hide_source_outlined,
                        size: 20, color: Colors.white),
                  )
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: errors.take(20).map((item) {
                final parts = item.split("~");
                final isLive = parts[0].contains("live");
                final imgPath =
                    "assets/images/home_screen_images/livelogos/${parts[1]}.png";

                return Bounceable(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => isLive
                              ? LiveDetailsScreen(
                            img: imgPath,
                            mainCollection: parts[0],
                            subCollection: parts[1],
                            subSubCollection: parts[2],
                            showHighlightsButton: true,
                            scrollToDatetimeId: "",
                          )
                              : const ChannelsTab()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: text(
                        text: item,
                        size: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.black),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 5),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.all(20),
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
              const SizedBox(height: 20),
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