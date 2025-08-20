import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/DbSqlHelper.dart';
import 'package:namekart_app/activity_helpers/FirestoreHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/activity_helpers/NotificationSettingsHelper.dart';
import 'package:namekart_app/change_notifiers/AllDatabaseChangeNotifiers.dart';
import 'package:namekart_app/screens/features/BiddingListAndWatchListScreen.dart';
import 'package:namekart_app/screens/features/BulkBid.dart';
import 'package:namekart_app/screens/features/BulkFetch.dart';
import 'package:namekart_app/screens/live_screens/live_details_screen.dart';
import 'package:namekart_app/screens/search_screen/SearchScreen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../change_notifiers/WebSocketService.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // --- State Variables ---
  late NotificationDatabaseChange notificationDatabaseChange;
  late NotificationPathNotifier notificationPathNotifier;
  late VoidCallback _syncListener;

  static bool _isLoading = false;
  static bool hasSyncedAlready = false;

  int readDropcatch = 0, readDynadot = 0, readGodaddy = 0;
  int readNamecheap = 0, readNamesilo = 0, readSav = 0;

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _isLoading = !hasSyncedAlready;

    if(_isLoading){
      WebSocketService().sendMessage({
        "query": "firebase-all_collection_info",
      });
    }

    _syncListener = () => Future.delayed(const Duration(seconds: 1), syncAllPaths);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notificationPathNotifier = Provider.of<NotificationPathNotifier>(context, listen: false)
        ..addListener(_syncListener);
      notificationDatabaseChange = Provider.of<NotificationDatabaseChange>(context, listen: false)
        ..addListener(getReadCount);
    });
    getReadCount();
  }

  @override
  void dispose() {
    notificationDatabaseChange.removeListener(getReadCount);
    notificationPathNotifier.removeListener(_syncListener);
    super.dispose();
  }

  // --- Data & Syncing Methods ---
  Future<void> getReadCount() async {
    readGodaddy = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-GD");
    readDynadot = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-DD");
    readDropcatch = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-DC");
    readNamecheap = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-NC");
    readNamesilo = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-NS");
    readSav = await DbSqlHelper.getReadCount("notifications~AMP-LIVE~Live-SAV");
    if (mounted) setState(() {});
  }

  Future<void> syncAllPaths() async {
    if (hasSyncedAlready) return;
    if (mounted) setState(() => _isLoading = true);
    _isLoading = true;
    await NotificationSettingsHelper.subscribeToAllNotificationsIfNoneSet(GlobalProviders.userId);
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
            String lastDatetimeId = lastItem?["datetime_id"];
            await syncFirestoreFromDocIdTimestamp(path, lastDatetimeId, false);
          } else {
            await getLatestDocuments(path);
          }
        } catch (e) {
          print('Error syncing $path: $e');
        }
      }
    } catch (e, st) {
      print('Failed to start sync: $e\n$st');
    }

    notificationPathNotifier.removeListener(_syncListener);
    hasSyncedAlready = true;
    _isLoading = false;

    print("marked isloading $_isLoading sync $hasSyncedAlready");

    if (mounted) setState(() => _isLoading = false);
    await getReadCount();
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _isLoading ? _buildShimmerEffect() : _buildContent(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI Widget Builders ---
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(title: "Live Status", child: _liveStatusGrid()),
        const SizedBox(height: 24),
        _buildSection(title: "Auction Tools", child: _auctionToolsRow()),
        const SizedBox(height: 40),
        _buildFooter(),
      ],
    );
  }

  /// **ERROR FIXED HERE** & UI improved to match new design
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 20.h, width: 120.w, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: List.generate(6, (index) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(radius: 22, backgroundColor: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 10.h, width: 50.w, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                ],
              )),
            ),
          ),
          const SizedBox(height: 24),
          Container(height: 20.h, width: 140.w, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) => Column(
                children: [
                  Container(height: 44.h, width: 44.w, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                  const SizedBox(height: 8),
                  Container(height: 10.h, width: 60.w, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Search())),
      child: Container(
        padding: EdgeInsets.all(15),
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
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text( "Find what you need faster", style: GoogleFonts.poppins(color: const Color(0xff717171), fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(title, style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        Container(
          padding: EdgeInsets.all(10),
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
          child: child,
        ),
      ],
    );
  }

  Widget _liveStatusGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.95,
      children: [
        _LiveStatusCard("livelogos/dropcatch", "Dropcatch", readDropcatch.toString()),
        _LiveStatusCard("livelogos/dynadot", "Dynadot", readDynadot.toString()),
        _LiveStatusCard("livelogos/godaddy", "Godaddy", readGodaddy.toString()),
        _LiveStatusCard("livelogos/namecheap", "Namecheap", readNamecheap.toString()),
        _LiveStatusCard("livelogos/namesilo", "Namesilo", readNamesilo.toString()),
        _LiveStatusCard("livelogos/sav", "SAV", readSav.toString()),
      ],
    );
  }

  Widget _auctionToolsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _AuctionToolCard(iconData: Icons.gavel_rounded, title: "Bidding List", targetScreen: BiddingListAndWatchListScreen(api: "/getBiddingList")),
        _AuctionToolCard(iconData: Icons.visibility_outlined, title: "Watch List", targetScreen: BiddingListAndWatchListScreen(api: "/getWatchList")),
        _AuctionToolCard(iconData: Icons.add_to_queue_rounded, title: "Bulk Bid", targetScreen: const BulkBid()),
        _AuctionToolCard(iconData: Icons.manage_search_rounded, title: "Bulk Fetch", targetScreen: const BulkFetch()),
      ],
    );
  }

  Widget _LiveStatusCard(String image, String title, String readCount) {
    String subSubCollectionName = {
      "livelogos/dropcatch": "Live-DC", "livelogos/dynadot": "Live-DD", "livelogos/godaddy": "Live-GD",
      "livelogos/namecheap": "Live-NC", "livelogos/namesilo": "Live-NS", "livelogos/sav": "Live-SAV"
    }[image]!;

    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 400),
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0, openColor: Colors.white,
      closedColor: Colors.white,
      openBuilder: (context, _) => LiveDetailsScreen(
        img: "assets/images/home_screen_images/$image.png",
        mainCollection: "notifications", subCollection: "AMP-LIVE", subSubCollection: subSubCollectionName,
        showHighlightsButton: true, scrollToDatetimeId: "",
      ),
      onClosed: (_) => getReadCount(),
      closedBuilder: (context, openContainer) {
        return Bounceable(
          onTap: openContainer,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset("assets/images/home_screen_images/$image.png", width: 24.sp, height: 24.sp),
                  if (readCount != "0")
                    Positioned(
                      top: -5, right: -7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: Colors.green, borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF7F8FA), width: 1.5)
                        ),
                        child: Text(readCount, style: GoogleFonts.poppins(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.black54, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    );
  }

  Widget _AuctionToolCard({required IconData iconData, required String title, required Widget targetScreen}) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 400),
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0, closedColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      openBuilder: (context, _) => targetScreen,
      closedBuilder: (context, openContainer) {
        return Bounceable(
          onTap: openContainer,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Icon(iconData, color: Colors.red, size: 22.sp),
                ),
                const SizedBox(height: 8),
                Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.black54, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Created For You!", style: GoogleFonts.poppins(fontSize: 20.sp, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.2)),
          Text("By Namekart", style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.black45, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}