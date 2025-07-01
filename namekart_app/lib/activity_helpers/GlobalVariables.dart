// globals.dart
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:msal_auth/msal_auth.dart';
import 'package:provider/provider.dart';
import '../change_notifiers/AllDatabaseChangeNotifiers.dart';

// Create a class to hold global providers
class GlobalProviders {
  static late LiveDatabaseChange liveDatabaseChange;
  static late ReconnectivityNotifier reconnectivityNotifier;
  static late NotificationDatabaseChange notificationDatabaseChange;
  static late CheckConnectivityNotifier checkConnectivityNotifier;
  static late DatabaseDataUpdatedNotifier databaseDataUpdatedNotifier;

  static late String userId;
  static late Account loginToken;

  String redirectUri='msauth://com.example.namekart_app/wOnWDw1F6gWy4TyhdXzYaD4bm4I%3D';

  static bool previouslyOpen=false;

  // Initialize all providers in one method
  static void initialize(BuildContext context) {
    liveDatabaseChange = Provider.of<LiveDatabaseChange>(context, listen: false);
    reconnectivityNotifier = Provider.of<ReconnectivityNotifier>(context, listen: false);
    notificationDatabaseChange = Provider.of<NotificationDatabaseChange>(context, listen: false);
    checkConnectivityNotifier = Provider.of<CheckConnectivityNotifier>(context, listen: false);
    databaseDataUpdatedNotifier = Provider.of<DatabaseDataUpdatedNotifier>(context, listen: false);
  }
}

final Map<String, Widget Function(double)> _iconMap = {
  "watch": (size) => Icon(Icons.bookmark_border, size: size,color: Colors.black54,),
  "stats": (size) => Icon(Icons.query_stats , size: size,color: Colors.black54,),
  "search": (size) => Icon(Icons.search_rounded , size: size,color: Colors.black54,),
  "leads": (size) => Icon(Icons.label_important_outline , size: size,color: Colors.black54,),
  "refresh": (size) => Icon(Icons.update , size: size,color: Colors.black54,),
  "links": (size) => Icon(Icons.link_sharp , size: size,color: Colors.black54,),
  "bid 100": (size) => Icon(Icons.confirmation_number_outlined , size: size,color: Colors.black54,),
  "bid 500": (size) => Icon(Icons.confirmation_number_outlined , size: size,color: Colors.black54,),
  "customs": (size) => Icon(Icons.currency_exchange_rounded , size: size,color: Colors.black54,),
  "links": (size) => Icon(Icons.link_sharp , size: size,color: Colors.black54,),
  "google": (size) => Brand(Brands.google, size: size),
  "instagram": (size) => Brand(Brands.instagram, size: size),

  "godaddy": (size) => Image.asset("assets/images/home_screen_images/livelogos/godaddy.png",width: size,height: size,),
  "namecheap": (size) => Image.asset("assets/images/home_screen_images/livelogos/namecheap.png",width: size,height: size,),
  "namesilo": (size) => Image.asset("assets/images/home_screen_images/livelogos/namesilo.png",width: size,height: size,),
  "dropcatch": (size) => Image.asset("assets/images/home_screen_images/livelogos/dropcatch.png",width: size,height: size,),
  "dynadot": (size) => Image.asset("assets/images/home_screen_images/livelogos/dynadot.png",width: size,height: size,),
  "biddinglist": (size) => Image.asset("assets/images/home_screen_images/features/biddinglist.png",width: size,height: size,),
  "bulkbid": (size) => Image.asset("assets/images/home_screen_images/features/bulkbid.png",width: size,height: size,),
  "bulkfetch": (size) => Image.asset("assets/images/home_screen_images/features/bulkfetch.png",width: size,height: size,),
  "watchlist": (size) => Image.asset("assets/images/home_screen_images/features/watchlist.png",width: size,height: size,),
  "Bid Activity": (size) => Image.asset("assets/images/notifications_images/BidActivity.jpg",width: size,height: size,),
  "Bot Activity": (size) => Image.asset("assets/images/notifications_images/BotActivity.jpg",width: size,height: size,),
  "Closeout Activity": (size) => Image.asset("assets/images/notifications_images/CloseoutsActivity.jpg",width: size,height: size,),
  "Daily Live Report": (size) => Image.asset("assets/images/notifications_images/DailyLiveReports.jpg",width: size,height: size,),
  "all":(size)=>Icon(Icons.all_inclusive,size: size,color: Colors.black54),













  // Add more mappings as needed
};

Widget getIconForButton(String buttonText, double iconSize) {
  String name = buttonText.toLowerCase().trim();
  final iconBuilder = _iconMap[name];
  return iconBuilder != null
      ? iconBuilder(iconSize)
      : Icon(Icons.account_circle, size: iconSize); // fallback icon with proper size
}
