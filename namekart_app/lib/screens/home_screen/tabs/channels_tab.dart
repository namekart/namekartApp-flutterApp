import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:provider/provider.dart';

import '../../../activity_helpers/FirestoreHelper.dart';
import '../../../activity_helpers/UIHelpers.dart';
import '../../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../../../change_notifiers/WebSocketService.dart';
import '../../../cutsom_widget/SuperAnimatedWidget.dart';
import '../../../database/HiveHelper.dart';
import '../../../fcm/FcmHelper.dart';
import '../../live_screens/live_details_screen.dart';

class ChannelsTab extends StatefulWidget {
  const ChannelsTab({super.key});

  @override
  State<ChannelsTab> createState() => _ChannelsTabState();
}

class _ChannelsTabState extends State<ChannelsTab> with WidgetsBindingObserver {
  late ScrollController _scrollController;
  late FCMHelper _fcmHelper;
  late StreamSubscription<void> _notificationSubscription;

  bool isDataLoaded=false;
  Map<String, List<String>> parsedMap = {};
  Map<String, bool> isExpandedMap = {};

  late NotificationPathNotifier notificationPathNotifier;
  TextEditingController searchController = TextEditingController();
  String searchText = '';

  String dataMessage="Syncing";


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _fcmHelper = FCMHelper();

    getAllData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notificationPathNotifier = Provider.of<NotificationPathNotifier>(context, listen: false);
      notificationPathNotifier.addListener(getAllData);
    });

    searchController.addListener(() {
      setState(() {
        searchText = searchController.text.toLowerCase();
      });
    });

    WebSocketService().sendMessage({
      "query": "firebase-all_collection_info",
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationSubscription.cancel();
    notificationPathNotifier.dispose();
    searchController.dispose();
    super.dispose();
  }

  void getAllData() async {
    if (!mounted) {
      setState(() {
      dataMessage="No Data Found";
      });
      return;
    }
    try {
      final readedData = await readAllCloudPath();

      if(!mounted || readedData == null){
        setState(() {
          dataMessage="No Data Found";
        });
        return;
      }

      final outerDecoded = jsonDecode(readedData);
      final dataField = outerDecoded['data'];
      final innerDecoded = dataField is String ? jsonDecode(dataField) : dataField;
      final responseRaw = innerDecoded['response'];
      final responseList = responseRaw is String ? jsonDecode(responseRaw) : responseRaw;

      final Map<String, List<String>> tempMap = {};

      for (var item in responseList) {
        if (item is! String) continue;

        final parts = item.split("~");
        if (parts.length < 3 || parts[0] != "notifications") continue;


        final channel = parts[1];
        final subCollection = parts[2];

        if (channel.isEmpty || subCollection.isEmpty) continue;

        // Update tempMap
        tempMap.putIfAbsent(channel, () => []);
        if (!tempMap[channel]!.contains(subCollection)) {
          tempMap[channel]!.add(subCollection);
        }

        final hivePath = "notifications~$channel~$subCollection";
        final lastHiveData = HiveHelper.getLast(hivePath);
        final lastTimestamp = lastHiveData?['datetime_id'];

        if (lastTimestamp == null) {
          print("📭 No local data for $hivePath. Fetching 10 latest from Firestore...");

          final latestDocs = await getLatestDocuments(hivePath, limit: 10);
          if (latestDocs.isEmpty) {
            print("⚠️ No documents found on Firestore for $hivePath.");
            continue;
          }

          for (final doc in latestDocs) {
            final docId = doc['datetime_id']?.toString();
            if (docId != null) {
              try {
                await HiveHelper.addDataToHive(hivePath, docId, doc);
              } catch (e) {
                print("⚠️ Skipping existing doc $docId: $e");
              }
            }
          }

          final latestStored = HiveHelper.getLast(hivePath);
          final latestId = latestStored?['datetime_id'];
          if (latestId != null) {
            await syncFirestoreFromDocIdTimestamp(hivePath, latestId, false);
          }
        } else {
          print("📦 Found local data for $hivePath: $lastTimestamp");
          await syncFirestoreFromDocIdTimestamp(hivePath, lastTimestamp, false);
        }
      }

      if (!mounted){
        setState(() {
          dataMessage="No Data Found";
        });
        return;
      }
      // Sort and update state
      final sortedMap = Map.fromEntries(
        tempMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      setState(() {
        dataMessage="Data Found";

        parsedMap = sortedMap;
        isExpandedMap = {for (var key in parsedMap.keys) key: true};
      });

    } catch (e, st) {
      print("❌ Error in getAllData: $e\n$st");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, List<String>>> sortedEntries = parsedMap.entries.map((entry) {
      final subcollection = entry.key;
      final items = entry.value;

      // Step 1: Filter by search
      final filteredItems = items.where((item) {
        return subcollection.toLowerCase().contains(searchText) ||
            item.toLowerCase().contains(searchText);
      }).toList();

      // Step 2: Sort sub-subcollections by unread count
      filteredItems.sort((a, b) {
        final countA = HiveHelper.getUnreadCountFlexible("notifications~$subcollection~${a.trim()}");
        final countB = HiveHelper.getUnreadCountFlexible("notifications~$subcollection~${b.trim()}");

        if (countA > 0 && countB > 0) {
          return countB.compareTo(countA);
        }
        if (countA > 0) return -1;
        if (countB > 0) return 1;
        return a.compareTo(b);
      });

      return MapEntry(subcollection, filteredItems);
    }).where((entry) => entry.value.isNotEmpty).toList();

// Step 3: Sort subcollections by max unread count inside them
    sortedEntries.sort((a, b) {
      int maxA = a.value.map((item) =>
          HiveHelper.getUnreadCountFlexible("notifications~${a.key}~${item.trim()}")
      ).fold(0, (prev, curr) => curr > prev ? curr : prev);

      int maxB = b.value.map((item) =>
          HiveHelper.getUnreadCountFlexible("notifications~${b.key}~${item.trim()}")
      ).fold(0, (prev, curr) => curr > prev ? curr : prev);

      return maxB.compareTo(maxA); // Highest unread first
    });

    final filteredMap = Map<String, List<String>>.fromEntries(sortedEntries);

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: const Color(0xffF7F7F7),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // 🔍 Search Bar
              Container(
                width: double.infinity,
                height: 45.sp,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 15, bottom: 13),
                  child: TextField(
                    controller: searchController,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      color: const Color(0xffA8A7A7),
                      fontSize: 10,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search",
                    ),
                    textAlignVertical: TextAlignVertical.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔁 Channel list
              if (filteredMap.isNotEmpty)
                  ListView.builder(
                    itemCount: filteredMap.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      String subCollection = filteredMap.keys.elementAt(index);
                      bool isExpanded = isExpandedMap[subCollection] ?? false;
                      List<String> responseList = filteredMap[subCollection]!;

                      haptic();

                    return SuperAnimatedWidget(
                      effects: [AnimationEffect.fade, AnimationEffect.slide],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Bounceable(
                          onTap: () {
                            setState(() {
                              isExpandedMap[subCollection] = !isExpanded;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xffFFFFFF),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1)],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      text(
                                        text: subCollection,
                                        size: 10,
                                        fontWeight: FontWeight.w300,
                                        color: const Color(0xffA8A7A7),
                                      ),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: const Icon(Icons.keyboard_arrow_down, size: 18),
                                      ),
                                    ],
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    alignment: Alignment.topCenter,
                                    child: (isExpanded && responseList.isNotEmpty)
                                        ? Column(
                                      children: responseList.map((item) {
                                        print(HiveHelper.getUnreadCountFlexible("notifications~$subCollection~${item.trim()}"));
                                        final unread = HiveHelper.getUnreadCountFlexible("notifications~$subCollection~${item.trim()}");
                                        return Padding(
                                          padding: responseList.indexOf(item) == 0
                                              ? const EdgeInsets.only(top: 20)
                                              : const EdgeInsets.only(top: 10),
                                          child: Bounceable(
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) {
                                                    return LiveDetailsScreen(
                                                      mainCollection: "notifications",
                                                      subCollection: subCollection.trim(),
                                                      subSubCollection: item.trim(),
                                                      showHighlightsButton: false,
                                                      img: "assets/images/home_screen_images/appbar_images/notification.png",
                                                    );
                                                  },
                                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                    const begin = Offset(1.0, 0.0); // From right
                                                    const end = Offset.zero;
                                                    const curve = Curves.ease;

                                                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                                    final offsetAnimation = animation.drive(tween);

                                                    return SlideTransition(
                                                      position: offsetAnimation,
                                                      child: child,
                                                    );
                                                  },
                                                  transitionDuration: const Duration(milliseconds: 300), // Optional: adjust speed
                                                ),
                                              );

                                              getAllData();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: const Color(0xffFFFFFF),
                                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1)],
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: text(
                                                      text: item.trim(),
                                                      size: 10,
                                                      fontWeight: FontWeight.w300,
                                                      color: const Color(0xff3F3F41),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 80),
                                                    child: text(
                                                      text: "${unread} New Notification",
                                                      size: 8,
                                                      fontWeight: FontWeight.w300,
                                                      color: unread == 0
                                                          ? const Color(0xffA8A7A7)
                                                          : const Color(0xff80B71C1C),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    CupertinoIcons.arrow_right,
                                                    size: 10,
                                                    color: Color(0xff717171),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              if (dataMessage=="Syncing")  const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          color: Colors.black,
          strokeWidth: 12,
        )),
              if (dataMessage=="No Data Found") Column(
                children: [
                  text(
                    text: "No Data Found",
                    size: 10,
                    fontWeight: FontWeight.w300,
                    color: Color(0xffA8A7A7),
                  ),

                  MaterialButton(onPressed: (){
                    WebSocketService().sendMessage({
                      "query": "firebase-all_collection_info",
                    });
                  },child: text(text: "Try Again", size: 12, color: Colors.black, fontWeight: FontWeight.w300),)
                ],
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
