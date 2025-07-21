import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:namekart_app/activity_helpers/DbAccountHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/fcm/FcmHelper.dart';
import 'package:namekart_app/activity_helpers/DbSqlHelper.dart'; // Import DbSqlHelper

import '../../../../../activity_helpers/UIHelpers.dart';


class NotificationsScreen extends StatefulWidget {
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Map<String, Map<String, List<String>>> _displayNotificationsMap = {};
  late Set<String> _mutedItems;
  late Set<String> _initialMutedItems; // To store the state when the screen loads
  bool _isLoading = true; // Loading state

  /// Helper to generate full path key for notification channels
  String buildNotificationPath(String main, String sub, String leaf) => "$main~$sub~$leaf";


  @override
  void initState() {
    super.initState();
    _mutedItems = {}; // Initialize as empty
    _initialMutedItems = {}; // Initialize as empty
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      _isLoading = true; // Start loading

      // 1. Get all available notification paths from DbSqlHelper
      final List<String> allAvailablePaths = await DbSqlHelper.getAllAvailablePaths(maxDepth: 3);
      print("All available paths from DbSqlHelper: $allAvailablePaths");

      // Filter to only include paths that start with "notifications~"
      final List<String> notificationPaths = allAvailablePaths
          .where((path) => path.startsWith("notifications~"))
          .toList();

      // Build the _displayNotificationsMap from these paths
      _displayNotificationsMap = _groupPathsIntoMap(notificationPaths);
      print("Display Notifications Map: $_displayNotificationsMap");


      // 2. Load user's saved muted items from DbAccountHelper
      Map<dynamic, dynamic>? accountData = await DbAccountHelper.readData("account~user~details", GlobalProviders.userId);

      if (accountData != null &&
          accountData.containsKey('notifications') &&
          accountData['notifications'] is Map &&
          accountData['notifications'].containsKey('muted') &&
          accountData['notifications']['muted'] is List) {
        _mutedItems = Set<String>.from(accountData['notifications']['muted']);
        print("Loaded muted items: $_mutedItems");
      } else {
        _mutedItems = {}; // No muted items found, default to empty
        print("No muted items found in user data.");
      }

      // Store the initial state of muted items
      _initialMutedItems = Set<String>.from(_mutedItems);

    } catch (e) {
      print("Error loading notification settings: $e");
      // Handle error gracefully, e.g., show a message to the user
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  // Helper function to group flat paths into the desired nested map structure
  Map<String, Map<String, List<String>>> _groupPathsIntoMap(List<String> paths) {
    final Map<String, Map<String, List<String>>> groupedMap = {};

    for (String fullPath in paths) {
      final parts = fullPath.split('~');
      // Ensure the path starts with "notifications" and has at least two parts after it
      if (parts.length >= 3 && parts[0] == "notifications") {
        final mainCategory = parts[1]; // e.g., "AMP-LIVE", "namekart"
        final subKeyOrLeaf = parts[2]; // Can be the sub-category or the leaf itself

        if (parts.length == 3) {
          // Path is like "notifications~mainCategory~leafID"
          // We'll put these under a "default" sub-category for display purposes
          if (!groupedMap.containsKey(mainCategory)) {
            groupedMap[mainCategory] = {};
          }
          if (!groupedMap[mainCategory]!.containsKey("default")) {
            groupedMap[mainCategory]!["default"] = [];
          }
          if (!groupedMap[mainCategory]!["default"]!.contains(subKeyOrLeaf)) {
            groupedMap[mainCategory]!["default"]!.add(subKeyOrLeaf);
          }
        } else {
          // Path is like "notifications~mainCategory~subCategory~leafID"
          final subCategory = subKeyOrLeaf;
          final leaf = parts.sublist(3).join('~'); // Join remaining parts if leaf itself contains '~'
          if (!groupedMap.containsKey(mainCategory)) {
            groupedMap[mainCategory] = {};
          }
          if (!groupedMap[mainCategory]!.containsKey(subCategory)) {
            groupedMap[mainCategory]![subCategory] = [];
          }
          if (!groupedMap[mainCategory]![subCategory]!.contains(leaf)) {
            groupedMap[mainCategory]![subCategory]!.add(leaf);
          }
        }
      }
    }
    return groupedMap;
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          elevation: 10,
          backgroundColor: const Color(0xffF7F7F7),
          foregroundColor: const Color(0xffF7F7F7),
          surfaceTintColor:const Color(0xffF7F7F7) ,
          iconTheme: const IconThemeData(color: Color(0xff3F3F41), size: 15),
          title: Row(
            children: [
              text(
                  text: "Notifications",
                  fontWeight: FontWeight.w300,
                  size: 12.sp,
                  color: const Color(0xff3F3F41)),
            ],
          ),
          titleSpacing: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 5,
          backgroundColor: const Color(0xffffffff),
          shadowColor: Colors.black12,
          surfaceTintColor:const Color(0xffffffff) ,
          iconTheme: const IconThemeData(color: Color(0xff3F3F41), size: 15),
          actions: [
            Container(
              width: 2,
              height: 25.sp,
              color: Colors.black12,
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.notifications,
                size: 15.sp,
              ),
            )
          ],
          title: Row(
            children: [
              text(
                  text: "Notifications",
                  fontWeight: FontWeight.w300,
                  size: 12.sp,
                  color: const Color(0xff3F3F41)),
            ],
          ),
          titleSpacing: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: _displayNotificationsMap.entries.map((mainEntry) {
                  final mainKey = mainEntry.key; // e.g., "AMP-LIVE", "namekart"
                  final subMap = mainEntry.value; // Map<String, List<String>>

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main title
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 10),
                        child: text(
                          text: mainKey,
                          fontWeight: FontWeight.w400,
                          size: 12.sp,
                          color: const Color(0xff717171),
                        ),
                      ),
                      const SizedBox(height: 8),

                      ...subMap.entries.map((subEntry) {
                        final subKey = subEntry.key; // e.g., "Live-DC", "Ankur" or "default"
                        final leafList = subEntry.value; // List of notification IDs/topics

                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subcategory (display only if not "default")
                                if (subKey != "default")
                                  text(
                                    text: subKey,
                                    fontWeight: FontWeight.w300,
                                    size: 10.sp,
                                    color: const Color(0xff3F3F41),
                                  ),
                                if (subKey != "default")
                                  const SizedBox(height: 10),

                                // Scrollable list of leaves (notification IDs/topics)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: leafList.map((leaf) {
                                      // Construct the full path for FCM topic subscription/unsubscription
                                      String path;
                                      if (subKey == "default") {
                                        // Path was originally "notifications~mainCategory~leaf"
                                        path = "notifications~${mainKey}~${leaf}";
                                      } else {
                                        // Path was originally "notifications~mainCategory~subCategory~leaf"
                                        path = "notifications~${mainKey}~${subKey}~${leaf}";
                                      }

                                      final isMuted = _mutedItems.contains(path);

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isMuted) {
                                              _mutedItems.remove(path);
                                            } else {
                                              _mutedItems.add(path);
                                            }
                                          });
                                        },
                                        child: Container(
                                          margin:
                                          const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: isMuted
                                                ? Colors.white
                                                : Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black12,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              text(
                                                text: leaf,
                                                fontWeight: FontWeight.w400,
                                                size: 10.sp,
                                                color: const Color(0xff3F3F41),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                isMuted
                                                    ? Icons.notifications_off
                                                    : Icons.notifications,
                                                size: 16,
                                                color: isMuted
                                                    ? Colors.red
                                                    : Colors.black26,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                    ],
                  );
                }).toList(),
              ),
            ),

            // Save Settings button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_isLoading) return; // Prevent double-tap while loading

                    setState(() {
                      _isLoading = true; // Show loading indicator while saving
                    });

                    try {
                      // Get the current state of muted items from the UI
                      final Set<String> currentMutedItems = Set<String>.from(_mutedItems);
                      final Set<String> currentActiveItems = (await DbSqlHelper.getAllAvailablePaths(maxDepth: 3))
                          .where((path) => path.startsWith("notifications~"))
                          .toSet()
                          .difference(currentMutedItems);

                      final Set<String> topicsBecomingMuted = currentMutedItems.difference(_initialMutedItems);

// Calculate topics that moved from MUTED to ACTIVE -> SUBSCRIBE these
                      final Set<String> topicsBecomingActive = _initialMutedItems.difference(currentMutedItems);

                      print("Topics becoming Muted (Unsubscribe): $topicsBecomingMuted");
                      for (String topic in topicsBecomingMuted) {
                        await FCMHelper().unsubscribeFromTopic(topic);
                        print("Unsubscribed from FCM topic: $topic");
                      }

                      print("Topics becoming Active (Subscribe): $topicsBecomingActive");
                      for (String topic in topicsBecomingActive) {
                        await FCMHelper().subscribeToTopic(topic);
                        print("Subscribed to FCM topic: $topic");
                      }

                      // Update the 'muted' and 'active' lists in the user's main JSON data in DbAccountHelper
                      Map<dynamic, dynamic>? accountData = await DbAccountHelper.readData("account~user~details", GlobalProviders.userId);
                      accountData ??= <String, dynamic>{};

                      Map<String, dynamic> notificationsSection = (accountData['notifications'] != null && accountData['notifications'] is Map<String, dynamic>)
                          ? accountData['notifications'] as Map<String, dynamic>
                          : <String, dynamic>{};

                      notificationsSection['muted'] = currentMutedItems.toList();
                      notificationsSection['active'] = currentActiveItems.toList();

                      accountData['notifications'] = notificationsSection;

                      await DbAccountHelper.addData("account~user~details", GlobalProviders.userId, accountData);

                      // After saving, update _initialMutedItems to reflect the new saved state
                      _initialMutedItems = Set<String>.from(currentMutedItems);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Notification Settings Saved")),
                      );
                    } catch (e) {
                      print("Error saving notification settings: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error saving settings: ${e.toString()}")),
                      );
                    } finally {
                      setState(() {
                        _isLoading = false; // Stop loading
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    "Save Settings",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}