import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:namekart_app/screens/home_screen/tabs/ProfileTab.dart';
import 'package:namekart_app/screens/home_screen/tabs/home_tab.dart';
import 'package:namekart_app/screens/home_screen/tabs/channels_tab.dart';
import 'package:provider/provider.dart';

import '../../activity_helpers/FirestoreHelper.dart';
import '../../activity_helpers/GlobalFunctions.dart';
import '../../activity_helpers/GlobalVariables.dart';
import '../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../../change_notifiers/WebSocketService.dart';
import '../../cutsom_widget/customSyncWidget.dart';
import '../../database/HiveHelper.dart';
import '../info_screens/HelpDesk.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late NotificationPathNotifier notificationPathNotifier;
  late BuildContext dialogContext;

  late VoidCallback _syncListener;

  late NotificationDatabaseChange notificationDatabaseChange;
  int homeReadCount = 0, channelReadCount = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const ChannelsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    connectToWebsocket();

    _syncListener = () => syncAllPaths(context);

    getHomeScreenAndChannelReadCount();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clean up old listener if it exists
      notificationDatabaseChange =
          Provider.of<NotificationDatabaseChange>(context, listen: false);
      notificationDatabaseChange.addListener(getHomeScreenAndChannelReadCount);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notificationPathNotifier =
          Provider.of<NotificationPathNotifier>(context, listen: false);
      notificationPathNotifier.addListener(_syncListener);
    });
  }

  void connectToWebsocket() async {
    await WebSocketService().connect(
      GlobalProviders.userId,
      Provider.of<LiveDatabaseChange>(context, listen: false),
      Provider.of<ReconnectivityNotifier>(context, listen: false),
      Provider.of<NotificationDatabaseChange>(context, listen: false),
      Provider.of<CheckConnectivityNotifier>(context, listen: false),
      Provider.of<DatabaseDataUpdatedNotifier>(context, listen: false),
      Provider.of<BubbleButtonClickUpdateNotifier>(context, listen: false),
      Provider.of<NotificationPathNotifier>(context, listen: false),
    );

    WebSocketService().sendMessage({
      "query": "firebase-all_collection_info",
    });
  }

  Future<void> syncAllPaths(BuildContext context) async {
    showSyncDialog(context);
    try {
      final readedData = await readAllCloudPath();
      final outerDecoded = jsonDecode(readedData!);
      final dataField = outerDecoded['data'];
      final innerDecoded =
          dataField is String ? jsonDecode(dataField) : dataField;
      final responseRaw = innerDecoded['response'];
      final List<dynamic> paths =
          responseRaw is String ? jsonDecode(responseRaw) : responseRaw;

      for (final String path in paths) {
        try {
          if (HiveHelper.getLast(path)?['datetime_id'] != null) {
            String lastDatetime_id = HiveHelper.getLast(path)?["datetime_id"];
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
  }

  void getHomeScreenAndChannelReadCount() {
    setState(() {
      homeReadCount = HiveHelper.getHomeScreenReadCount();
      print("object $homeReadCount");
      channelReadCount = HiveHelper.getChannelScreenReadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF7F7F7),
      appBar: AppBar(
        backgroundColor: Color(0xffF7F7F7),
        shadowColor: Colors.black,
        title: Image.asset(
          "assets/images/login_screen_images/loginpagenamekartlogo.png",
          width: 120.sp,
        ),
        actions: [
          Icon(
            Icons.refresh_rounded,
            color: Color(0xff717171),
          ),
          SizedBox(
            width: 10,
          ),
          Bounceable(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpDesk()),
                );
              },
              child: Icon(
                Icons.help_center,
                color: Color(0xff717171),
              )),
          SizedBox(
            width: 10,
          )
        ],
      ),
      body: AlertWidget(
          onReconnectSuccess: () {}, path: '', child: _tabs[_selectedIndex]),
      bottomNavigationBar: FlashyTabBar(
        selectedIndex: _selectedIndex,
        height: 55.sp,
        showElevation: true,
        backgroundColor: Color(0xffF7F7F7),
        onItemSelected: (index) {
          getHomeScreenAndChannelReadCount();
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          FlashyTabBarItem(
            icon: Icon(Icons.home_outlined,
                color: (homeReadCount == 0) ? Colors.black : Colors.green),
            title: const Text(
              "Home",
              style: TextStyle(color: Colors.black),
            ),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.live_tv_rounded,
                color: (channelReadCount == 0) ? Colors.black : Colors.green),
            title: const Text(
              "Channels",
              style: TextStyle(color: Colors.black),
            ),
          ),
          FlashyTabBarItem(
            icon: const Icon(
              Icons.person_2_outlined,
              color: Colors.black,
            ),
            title: const Text("Profile", style: TextStyle(color: Colors.black)),
          ),
        ],
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
