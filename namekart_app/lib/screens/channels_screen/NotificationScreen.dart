// import 'dart:async';
// import 'dart:convert';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bounceable/flutter_bounceable.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:haptic_feedback/haptic_feedback.dart';
// import 'package:hive_flutter/adapters.dart';
// import 'package:namekart_app/change_notifiers/WebSocketService.dart';
// import 'package:namekart_app/cutsom_widget/AnimatedAvatarIcon.dart';
// import 'package:namekart_app/cutsom_widget/AutoAnimatedContainerWidget.dart';
// import 'package:namekart_app/cutsom_widget/CustomShimmer.dart';
// import 'package:namekart_app/cutsom_widget/SuperAnimatedWidget.dart';
// import 'package:namekart_app/database/HiveHelper.dart';
// import 'package:namekart_app/screens/live_screens/live_details_screen.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
//
// import '../../activity_helpers/FirestoreHelper.dart';
// import '../../activity_helpers/UIHelpers.dart';
// import '../../change_notifiers/AllDatabaseChangeNotifiers.dart';
// import '../../fcm/FcmHelper.dart';
//
// class ChannelsScreen extends StatefulWidget {
//   @override
//   State<ChannelsScreen> createState() => _ChannelsScreenState();
// }
//
// class _ChannelsScreenState extends State<ChannelsScreen>
//     with WidgetsBindingObserver {
//   final GlobalKey<AnimatedListState> _listkey = GlobalKey<AnimatedListState>();
//   late ScrollController _scrollController;
//
//   late Future<List<Map<String, dynamic>>> data;
//   List<Map<String, dynamic>> dataList = [];
//
//   static bool databaseRefresh = false;
//
//   late StreamSubscription<void> _notificationSubscription;
//   late FCMHelper _fcmHelper;
//
//   List<String> subCollections = [];
//   Map<String, String> subCollectionsWithNotificationsCount = {};
//   List<Map<List<String>, List<String>>> subSubCollectionsWithNotificationsCount = [{}];
//
//   List<String> responseList=[];
//
//
//   Map<String, bool> isExpandedMap = {}; // key = subCollectionName
//   Map<String, List<String>> subSubCollectionsMap = {}; // key = subCollectionName
//
//   String responseString="";
//
//   var getAllNotifications;
//
//   Map<String, List<String>> parsedMap={};
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//
//     WidgetsBinding.instance.addObserver(this);
//
//     _scrollController = ScrollController();
//
//     getSubCollections();
//
//     _fcmHelper = FCMHelper();
//
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final notificationDatabaseChange =
//       Provider.of<NotificationDatabaseChange>(context, listen: false);
//       notificationDatabaseChange.addListener(getAllData);
//     });
//
//     getAllData();
//   }
//
//   void getAllData() async {
//     WebSocketService w = WebSocketService();
//     final response = await w.sendMessageGetResponse({
//       "query": "firebase-allsubsubcollections",
//       "path": "notifications"
//     }, "user",expectedQuery: 'firebase-allsubsubcollections');
//
//     if(response.isEmpty){
//       print("sdfsdfsdfs");
//     }
//
//     final decoded = jsonDecode(response["data"]);
//     final Map<String, dynamic> rawMap = decoded["response"];
//
//     // Convert and sort by keys alphabetically
//     final sortedMap = Map.fromEntries(
//         rawMap.entries.toList()
//           ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()))
//     );
//
//     setState(() {
//       parsedMap = sortedMap.map(
//             (key, value) => MapEntry(key, List<String>.from(value)),
//       );
//     });
//
//     isExpandedMap = {
//       for (var key in parsedMap.keys) key: true // 👈 Set all to true
//     };
//
//   }
//
//
//
//   void getSubCollections() async {
//     subCollections = await getSubCollectionNames("notifications");
//
//     setState(() {
//       for (String subCollection in subCollections) {
//         int s = HiveHelper.getUnreadCountFlexible("notifications~$subCollection");
//         String subCollectionNotificationCount = s.toString();
//         subCollectionsWithNotificationsCount.addAll(
//             {subCollection: subCollectionNotificationCount});
//       }
//     });
//   }
//
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     super.dispose();
//     _notificationSubscription.cancel();
//     _scrollController.dispose();
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//
//     if (databaseRefresh) {
//       print("object");
//       databaseRefresh = false;
//     }
//
//     return Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           iconTheme: const IconThemeData(color: Colors.white, size: 20),
//           actions: [
//             Container(
//               width: 2,
//               height: 25.sp,
//               color: Colors.black12,
//             ),
//             IconButton(
//               onPressed: () {
//                 setState(() {});
//               },
//               icon: Image.asset(
//                 "assets/images/home_screen_images/appbar_images/notification.png",
//                 width: 20.sp,
//                 height: 20.sp,
//               ),
//             )
//           ],
//           actionsIconTheme: IconThemeData(color: Colors.white, size: 20),
//           title: Row(
//             children: [
//               Text("Notifications",
//                   style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15.sp,
//                       color: Colors.white)),
//             ],
//           ),
//           titleSpacing: 0,
//           toolbarHeight: 50,
//           flexibleSpace: Container(
//               decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                       colors: [Color(0xFF03A7FF), Color(0xFFAE002C)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight))),
//         ),
//         body:
//         Container(
//             width: MediaQuery
//                 .of(context)
//                 .size
//                 .width,
//             height: MediaQuery
//                 .of(context)
//                 .size
//                 .height,
//             color: Colors.transparent,
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   children: [
//                     Container(
//                         width: MediaQuery
//                             .of(context)
//                             .size
//                             .width,
//                         decoration: BoxDecoration(
//                             border: Border.all(color: Colors.black12, width: 1),
//                             borderRadius: BorderRadius.circular(15)
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.only(left: 15, right: 15),
//                           child: TextField(
//                             style: GoogleFonts.poppins(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black45,
//                               fontSize: 10
//                             ),
//                             decoration: InputDecoration(
//                               border: InputBorder.none,
//                               hintText: "Search",
//                             ),
//                           ),
//                         )),
//                     SizedBox(height: 20,),
//
//                     if(parsedMap.isNotEmpty)
//                     ListView.builder(
//                       itemCount: parsedMap.length,
//                       shrinkWrap: true,
//                       physics: NeverScrollableScrollPhysics(),
//                       itemBuilder: (context, index) {
//                         String subCollection = parsedMap.keys.elementAt(index);
//                         bool isExpanded = isExpandedMap[subCollection] ?? false;
//                         List<String> responseList = parsedMap[subCollection] ?? [];
//
//
//                         haptic();
//
//                         return SuperAnimatedWidget(
//                           effects: [AnimationEffect.fade, AnimationEffect.slide],
//                           child: Padding(
//                             padding: const EdgeInsets.only(left: 8.0, right: 8, top: 10, bottom: 15),
//                             child: Bounceable(
//                               onTap: () {
//                                 setState(() {
//                                   isExpandedMap[subCollection] = !isExpanded;
//                                 });
//                               },
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(20),
//                                   color: Color(0xfff2f2f2),
//                                   boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
//                                 ),
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(15),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Shimmer.fromColors(
//                                             baseColor: Colors.black87,
//                                             highlightColor: Colors.white,
//                                             child: Text(
//                                               subCollection,
//                                               style: GoogleFonts.poppins(
//                                                 fontSize: 12,
//                                                 fontWeight: FontWeight.bold,
//                                                 color: Colors.black87,
//                                               ),
//                                             ),
//                                           ),
//                                           AnimatedRotation(
//                                             turns: isExpanded ? 0.5 : 0.0,
//                                             duration: Duration(milliseconds: 300),
//                                             child: Icon(Icons.keyboard_arrow_down,size: 18,),
//                                           ),
//                                         ],
//                                       ),
//                                       AnimatedSize(
//                                         duration: Duration(milliseconds: 300),
//                                         curve: Curves.easeInOut,
//                                         alignment: Alignment.topCenter,
//                                         child: (isExpanded && responseList.isNotEmpty)
//                                             ? Column(
//                                           children: responseList.map((item) {
//                                             return Padding(
//                                               padding: responseList.indexOf(item) == 0
//                                                   ? const EdgeInsets.only(top: 20)
//                                                   : const EdgeInsets.only(top: 10),
//                                               child: Bounceable(
//                                                 onTap: (){
//                                                   Navigator.push(context, PageRouteBuilder(
//                                                       pageBuilder: (context, animation,
//                                                           secondaryAnimation) {
//                                                         return
//                                                           LiveDetailsScreen(
//                                                             mainCollection: "notifications",
//                                                             subCollection: subCollection.trim(),
//                                                             subSubCollection: item.trim()
//                                                                 .toString()
//                                                                 .trim(),
//                                                             showHighlightsButton: false,
//                                                             img: "assets/images/home_screen_images/appbar_images/notification.png",
//                                                           );
//                                                       }));
//                                                 },
//                                                 child: Container(
//                                                   padding: EdgeInsets.all(15),
//                                                   decoration: BoxDecoration(
//                                                     borderRadius: BorderRadius.circular(30),
//                                                     color: Colors.white,
//                                                   ),
//                                                   child: Row(
//                                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                                     children: [
//                                                       Expanded(
//                                                         child: Text(
//                                                           item.trim(),
//                                                           style: GoogleFonts.poppins(
//                                                             fontSize: 10,
//                                                             fontWeight: FontWeight.bold,
//                                                             color: Colors.black87,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       Padding(
//                                                         padding: const EdgeInsets.only(right: 80),
//                                                         child: Text(
//                                                           "${HiveHelper.getUnreadCountFlexible("notifications~$subCollection~${item.trim()}")} New Notification",
//                                                           style: GoogleFonts.poppins(
//                                                             fontSize: 8,
//                                                             fontWeight: FontWeight.bold,
//                                                             color: (HiveHelper.getUnreadCountFlexible(
//                                                                 "notifications~$subCollection~${item.trim()}") ==
//                                                                 0)
//                                                                 ? Colors.black45
//                                                                 : Color(0xff80B71C1C),
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       Icon(CupertinoIcons.arrow_right,size: 12,),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ),
//                                             );
//                                           }).toList(),
//                                         )
//                                             : SizedBox.shrink(),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//
//                     if(parsedMap.isEmpty)
//                       CircularProgressIndicator(),
//                     SizedBox(
//                       height: 50,
//                     )
//                   ],
//                 ),
//               ),
//             )));
//   }
// }