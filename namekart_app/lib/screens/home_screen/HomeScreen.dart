import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/activity_helpers/DbSqlHelper.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:namekart_app/screens/home_screen/tabs/home_tab.dart';
import 'package:namekart_app/screens/home_screen/tabs/channels_tab.dart';
import 'package:namekart_app/screens/home_screen/tabs/profile_tab/ProfileTab.dart';
import 'package:namekart_app/screens/home_screen/tabs/profile_tab/options_tab/Options.dart';
import 'package:provider/provider.dart';

import '../../activity_helpers/FirestoreHelper.dart';
import '../../activity_helpers/GlobalFunctions.dart';
import '../../activity_helpers/GlobalVariables.dart';
import '../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../../change_notifiers/WebSocketService.dart';
import '../../custom_widget/customSyncWidget.dart';
import '../info_screens/HelpDesk.dart';
import 'StarsScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late NotificationDatabaseChange notificationDatabaseChange;
  int homeReadCount = 0, channelReadCount = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const ChannelsTab(),
    Options(),
    ProfileTab(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();


    if (!GlobalProviders.isHomeScreenLoaded) {
      connectToWebsocket();
      getHomeScreenAndChannelReadCount();
      GlobalProviders.isHomeScreenLoaded = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clean up old listener if it exists
      notificationDatabaseChange =
          Provider.of<NotificationDatabaseChange>(context, listen: false);
      notificationDatabaseChange.addListener(getHomeScreenAndChannelReadCount);
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
      Provider.of<SnackBarSuccessNotifier>(context, listen: false),
      Provider.of<SnackBarFailedNotifier>(context, listen: false),
      Provider.of<ShowDialogNotifier>(context, listen: false),
    );
  }

  Future<void> getHomeScreenAndChannelReadCount() async {
    // Get count for Home Screen (notifications in AMP-LIVE channel)
    final String homeScreenPath = 'notifications~AMP-LIVE';
    homeReadCount = await DbSqlHelper.getReadCount(homeScreenPath);

    // Get total unread count across ALL channels
    final String allNotificationsPath = 'notifications';
    final int totalUnreadCount = await DbSqlHelper.getReadCount(allNotificationsPath);

    // Calculate channelReadCount (all unread EXCEPT AMP-LIVE)
    // This ensures that only notifications from other channels contribute to channelReadCount.
    channelReadCount = totalUnreadCount - homeReadCount;

    // Ensure channelReadCount doesn't go negative if there's a data discrepancy,
    // although theoretically, with correct logic, it shouldn't.
    if (channelReadCount < 0) {
      channelReadCount = 0;
    }

    // Update the UI
    setState(() {});

    print('Home Screen Unread Count (AMP-LIVE): $homeReadCount');
    print('Channel Screen Unread Count (Others): $channelReadCount');
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
          Bounceable(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StarsScreen()),
              );
            },
            child: Image.asset(
              "assets/images/home_screen_images/star.png",
              width: 23,
              height: 23,
            ),
          ),
          SizedBox(
            width: 15,
          ),
          Bounceable(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpDesk()),
                );
              },
              child: Image.asset(
                "assets/images/home_screen_images/chat.png",
                width: 23,
                height: 23,
              )),
          SizedBox(
            width: 15,
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
              Icons.dashboard_customize,
              color: Colors.black,
            ),
            title: const Text("Options", style: TextStyle(color: Colors.black)),
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
}
