import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';

import '../../../../activity_helpers/UIHelpers.dart';
import '../../../../database/HiveHelper.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Map<String, Map<String, List<String>>>? map;
  late Set<String> mutedItems;

  /// Helper to generate full path key
  String buildPath(String main, String sub, String leaf) => "$main~$sub~$leaf";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    map = returnMap(HiveHelper.getAllAvailablePaths(maxDepth: 3));
    map?.remove("account");

    try{
      mutedItems = Set<String>.from(HiveHelper.read("account~user~${GlobalProviders.userId}")["notifications"]["muted"]);
    }catch (e){
      mutedItems={};
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          elevation: 10,
          backgroundColor: Color(0xffF7F7F7),
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
                  color: Color(0xff3F3F41)),
            ],
          ),
          titleSpacing: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: map!.entries.map((mainEntry) {
                  final mainKey = mainEntry.key;
                  final subMap = mainEntry.value;

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
                        final subKey = subEntry.key;
                        final leafList = subEntry.value;

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
                                // Subcategory
                                text(
                                  text: subKey,
                                  fontWeight: FontWeight.w300,
                                  size: 10.sp,
                                  color: const Color(0xff3F3F41),
                                ),
                                const SizedBox(height: 10),

                                // Scrollable list of leaves
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: leafList.map((leaf) {
                                      final path = "$mainKey~$subKey~$leaf";
                                      final isMuted = mutedItems.contains(path);

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isMuted) {
                                              mutedItems.remove(path);
                                            } else {
                                              mutedItems.add(path);
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
                                                ? Colors.grey.shade300
                                                : Colors.blue.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                                    ? Colors.grey
                                                    : Colors.blue,
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

                      const Divider(height: 32),
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
                  onPressed: () {
                    // 👇 Collect all paths
                    final Set<String> allPaths = {};
                    map!.forEach((main, subMap) {
                      subMap.forEach((sub, leaves) {
                        for (var leaf in leaves) {
                          allPaths.add("$main~$sub~$leaf");
                        }
                      });
                    });

                    // 👇 Derive activeItems = all - muted
                    final Set<String> activeItems =
                        allPaths.difference(mutedItems);

                    // 👇 Save to Hive
                    final userBoxKey = "account~user~${GlobalProviders.userId}";
                    final settingsData = {
                      "muted": mutedItems.toList(),
                      "active": activeItems.toList(),
                    };

                    final boxData = HiveHelper.read(userBoxKey);

                    if (boxData != null && boxData.containsKey("notifications")) {
                      HiveHelper.updateDataOfHive("account~user~${GlobalProviders.userId}~notifications", "notifications", settingsData);
                    } else {
                      HiveHelper.addDataToHive(userBoxKey, "notifications", settingsData);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Settings Saved")),
                    );
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
