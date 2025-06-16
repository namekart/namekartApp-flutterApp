import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/screens/features/BiddingList.dart';
import 'package:namekart_app/screens/features/WatchList.dart';
import 'package:namekart_app/screens/features/BulkBid.dart';
import 'package:namekart_app/screens/features/BulkFetch.dart';
import 'package:namekart_app/screens/home_screen/tabs/channels_tab.dart';
import 'package:namekart_app/screens/live_screens/live_details_screen.dart';
import 'package:namekart_app/screens/search_screen/SearchScreen.dart';
import 'package:namekart_app/database/HiveHelper.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<String> ringAlarmActiveList = [];

  @override
  void initState() {
    super.initState();

    getRingAlarmList();
  }



    Future<void> getRingAlarmList() async {
    setState(() {
      ringAlarmActiveList = HiveHelper.getRingAlarmPaths()
          .where((e) => !e.startsWith("live~all"))
          .map((e) => e.split("~").take(3).join("~"))
          .toSet()
          .toList();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    ringAlarmActiveList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          buildCriticalErrorBanner(
            context,
            ringAlarmActiveList,
                () => setState(() => ringAlarmActiveList.clear()),
          ),
          _buildSearchBar(context),
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
                  )),
            );
          }),
          _liveStatusRow(),
          _sectionHeader("Auction Tools"),
          _auctionToolsRow(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                    text: "Created For \nYou!",
                    size: 25.sp,
                    color: Color(0xffA8A7A7),
                    fontWeight: FontWeight.w600),
                text(
                    text: "By Namekart",
                    size: 12.sp,
                    color: Color(0xffA8A7A7),
                    fontWeight: FontWeight.w300),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => Search()));
        },
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
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              text(
                  text: "Find what you need faster",
                  fontWeight: FontWeight.w400,
                  color: Color(0xff717171),
                  size: 10.sp),
              Icon(Icons.search_rounded, color: Color(0xff717171), size: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAllTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          text(
              text: title,
              size: 12.sp,
              color: Color(0xff3F3F41),
              fontWeight: FontWeight.w500),
          if (onSeeAllTap != null)
            GestureDetector(
              onTap: onSeeAllTap,
              child: text(
                  text: "See All",
                  fontWeight: FontWeight.bold,
                  color: Color(0xff717171),
                  size: 8.sp),
            )
        ],
      ),
    );
  }

  Widget _liveStatusRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30,top: 10 ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LiveStatusImage("livelogos/dropcatch", "Dropcatch"),
          _LiveStatusImage("livelogos/dynadot", "Dynadot"),
          _LiveStatusImage("livelogos/godaddy", "Godaddy"),
          _LiveStatusImage("livelogos/namecheap", "Namecheap"),
          _LiveStatusImage("livelogos/namesilo", "Namesilo"),
        ],
      ),
    );
  }

  Widget _auctionToolsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30,top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Bounceable(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => BiddingList())),
              child: _LiveStatusImage("features/biddinglist", "Bidding List")),
          Bounceable(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => WatchList())),
              child: _LiveStatusImage("features/watchlist", "Watch List")),
          Bounceable(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => BulkBid())),
              child: _LiveStatusImage("features/bulkbid", "Bulk Bid")),
          Bounceable(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => BulkFetch())),
              child: _LiveStatusImage("features/bulkfetch", "Bulk Fetch")),
        ],
      ),
    );
  }

  Widget _LiveStatusImage(String image, String title) {
    return Bounceable(
      onTap: (){
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LiveDetailsScreen(
                  img: "assets/images/home_screen_images/$image.png",
                  mainCollection: "live",
                  subCollection: title.toLowerCase(),
                  subSubCollection: "auctions",
                  showHighlightsButton: true,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity:
                CurvedAnimation(parent: animation, curve: Curves.easeIn),
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 350),
          ),
        );
      },
      child: Column(
        children: [
          Image.asset(
            "assets/images/home_screen_images/$image.png",
            width: image.contains("livelogos") ? 25.sp : 20.sp,
            height: image.contains("livelogos") ? 25.sp : 20.sp,
            color: image.contains("livelogos") ? null : Colors.black54,
          ),
          SizedBox(height: 10),
          text(
              text: title,
              size: 8,
              color: Color(0xff717171),
              fontWeight: FontWeight.w300),
        ],
      ),
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
                    child: Icon(Icons.hide_source_outlined,
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
                              showHighlightsButton: true)
                              : ChannelsTab()),
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
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
