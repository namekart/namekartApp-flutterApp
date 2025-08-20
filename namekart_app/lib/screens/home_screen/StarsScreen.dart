import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/DbAccountHelper.dart';
import 'package:namekart_app/activity_helpers/DbSqlHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:text_scroll/text_scroll.dart';

import '../../activity_helpers/GlobalFunctions.dart';
import '../../custom_widget/_HashtagInputWidgetState.dart';
import '../live_screens/live_details_screen.dart';
import '../search_screen/SearchScreen.dart';

class StarsScreen extends StatefulWidget {
  @override
  State<StarsScreen> createState() => _StarsScreenState();
}

class _StarsScreenState extends State<StarsScreen> {
  Map<String, List<dynamic>> pathsData = {};
  bool isLoading = true;
  bool hasError = false;



  @override
  void initState() {
    super.initState();
    loadStars();
  }

  Future<void> loadStars() async {
    try {
      Map<String, dynamic>? fetchedData = await getStars();
      if (fetchedData != null) {
        setState(() {
          pathsData = fetchedData.map((key, value) {
            return MapEntry(key, value as List<dynamic>);
          });
          isLoading = false;
        });
      } else {
        setState(() {
          pathsData = {};
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading stars: $e");
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<Map<String, dynamic>?> getStars() async {
    try {
      final stars = await DbAccountHelper.getStar("account~user~details", GlobalProviders.userId);
      return stars;
    } catch (e) {
      print("Error fetching stars from DB: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> paths = ["All", ...pathsData.keys.toList()];

    return DefaultTabController(
      length: paths.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black,
          title: text(text: "Stars",color: Color(0xff717171),fontWeight: FontWeight.bold,size: 12.sp),
          iconTheme: IconThemeData(size: 17,color: Color(0xff717171)),
          titleSpacing: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold,fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal,fontSize: 12),
            tabs: paths.map((p) => Tab(text: p)).toList(),
          ),
        ),
        body: isLoading
            ? const Center(child:  SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 12,
            )),)
            : hasError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 10),
              const Text("Failed to load stars. Please try again later."),
            ],
          ),
        )
            : pathsData.isEmpty && paths.length == 1
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/home_screen_images/nostars.png',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
            ],
          ),
        )
            : TabBarView(
          children: paths.map((currentTabPath) { // Renamed 'path' to 'currentTabPath' for clarity
            List<dynamic> ids;
            List<Map<String, String>> itemsToDisplay = []; // Stores {id: '...', originalPath: '...'}

            if (currentTabPath == "All") {
              // For "All" tab, iterate through all known paths and their IDs
              // to build a list of {id, originalPath}
              pathsData.forEach((originalPath, idList) {
                for (var id in idList) {
                  itemsToDisplay.add({
                    'id': id.toString(),
                    'originalPath': originalPath,
                  });
                }
              });
            }
            else {
              // For specific tabs, just use the IDs from that path
              ids = pathsData[currentTabPath] ?? [];
              for (var id in ids) {
                itemsToDisplay.add({
                  'id': id.toString(),
                  'originalPath': currentTabPath,
                });
              }
            }

            return itemsToDisplay.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/home_screen_images/nostars.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentTabPath == "All" ? "No Stars Yet!" : "No Stars in '$currentTabPath'",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentTabPath == "All"
                        ? "Looks like you haven't starred anything across all categories."
                        : "There are no starred items in this category.",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: itemsToDisplay.length,
              padding: EdgeInsets.all(0),
              itemBuilder: (context, index) {
                final itemData = itemsToDisplay[index];
                final String itemId = itemData['id']!;
                final String originalPath = itemData['originalPath']!;

                return FutureBuilder( // Expecting String or null
                  future: DbSqlHelper.getById(originalPath, itemId), // **FIXED HERE: Using originalPath**
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading:  SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 12,
                            )),
                        title: Text("Loading details...", style: TextStyle(color: Colors.grey)),
                      );
                    } else if (snapshot.hasError) {
                      print("Error fetching details for $itemId from $originalPath: ${snapshot.error}");
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.error, color: Colors.red),
                        title: Text(
                          "Error loading data: ${snapshot.error.toString().split(':')[0]}",
                          style: const TextStyle(color: Colors.red),
                        ),
                        subtitle: Text("ID: $itemId (Path: $originalPath)"),
                      );
                    } else if (snapshot.hasData && snapshot.data != null) {
                      // Successfully fetched data
                      final auctionItem = snapshot.data!;
                      var data = auctionItem['data'] as Map<dynamic, dynamic>;

                      var uiButtons = auctionItem['uiButtons'];
                      List<dynamic>? buttons;

                      var actionDoneList = auctionItem['actionsDone'];

                      bool ringStatus = false;

                      try {
                        var ringStatusString =
                        auctionItem['device_notification'].toString();
                        ringStatus =
                            ringStatusString.contains("ringAlarm: true");
                      } catch (e) {}

                      String readStatus = auctionItem['read'];

                      if (uiButtons is List && uiButtons.isNotEmpty) {
                        buttons = uiButtons;
                      }

                      final date = extractDate(auctionItem['datetime_id']);
                      final nextDate = index < snapshot.data!.length - 1
                          ? extractDate(snapshot.data!['datetime_id'])
                          : null;

                      final showHeader = date != nextDate;

                      print(auctionItem['notes']);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: currentTabPath == "All" ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextScroll(
                            "$originalPath~$itemId",
                            velocity: Velocity(pixelsPerSecond: Offset(20, 10)),
                            mode: TextScrollMode.bouncing,
                            pauseBetween: Duration(seconds: 3),
                            style: TextStyle(color: Color(0xff717171),fontSize: 8.sp,fontWeight: FontWeight.bold),),
                        ) : null, // Show path only in "All" tab
                        subtitle:Column(
                          children: [
                            if (showHeader)
                              Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 6),
                                    child: text(
                                      text: date,
                                      color: Colors.black54,
                                      size: 9,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            AbsorbPointer(child: DocumentPreviewCard(data: auctionItem,path:originalPath,)),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => LiveDetailsScreen(
                                    mainCollection: originalPath.split("~")[0],
                                    subCollection: originalPath.split("~")[1],
                                    subSubCollection: originalPath.split("~")[2],
                                    showHighlightsButton: originalPath.split("~")[1].contains("live"),
                                    img:originalPath.split("~")[2]=="Live-DC" ? "assets/images/home_screen_images/livelogos/dropcatch.png"
                                        : originalPath.split("~")[2]=="Live-DD" ? "assets/images/home_screen_images/livelogos/dynadot.png"
                                        : originalPath.split("~")[2]=="Live-SAV" ? "assets/images/home_screen_images/livelogos/sav.png"
                                        : originalPath.split("~")[2]=="Live-GD" ? "assets/images/home_screen_images/livelogos/godaddy.png"
                                        : originalPath.split("~")[2]=="Live-NC" ? "assets/images/home_screen_images/livelogos/namecheap.png"
                                        : originalPath.split("~")[2]=="Live-NS" ? "assets/images/home_screen_images/livelogos/namesilo.png":
                                    "assets/images/home_screen_images/appbar_images/notification.png",
                                    scrollToDatetimeId: itemId,
                                  )));
                          loadStars();
                        },
                      );
                    } else {
                      // Data is null or empty
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.info_outline, color: Colors.grey),
                        title: Text(
                          "No details found for ID: $itemId",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        subtitle: currentTabPath == "All" ? Text("Path: $originalPath") : null,
                      );
                    }
                  },
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildStarToggleButton({
    Key? key,
    required bool isStarred,
    required VoidCallback onStarredClicked,
    required VoidCallback onNotStarredClicked,
    double iconSize = 24.0,
    Color? filledColor,
    Color? outlinedColor,
  }) {
    return StatefulBuilder(
      key: key, // Pass the key to StatefulBuilder
      builder: (BuildContext context, StateSetter setState) {
        // Internal state to manage the current appearance of the star.
        // We use a mutable list to hold the boolean, allowing us to update it
        // within the builder's closure. This is a common pattern with StatefulBuilder.
        final List<bool> _isCurrentlyStarred = [isStarred];

        // To handle external changes to 'isStarred' prop, we need to ensure
        // our internal state reflects it. This is a simplified equivalent of didUpdateWidget.
        // If the incoming 'isStarred' is different from our current internal state,
        // we update the internal state.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isCurrentlyStarred[0] != isStarred) {
            setState(() {
              _isCurrentlyStarred[0] = isStarred;
            });
          }
        });

        /// Handles the tap event on the star button.
        void _handleStarTap() {
          setState(() {
            // Toggle the internal state.
            _isCurrentlyStarred[0] = !_isCurrentlyStarred[0];
          });

          // Call the appropriate callback based on the new state.
          if (_isCurrentlyStarred[0]) {
            onStarredClicked();
          } else {
            onNotStarredClicked();
          }
        }

        return IconButton(
          icon: Icon(
            _isCurrentlyStarred[0]
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: iconSize,
            color: _isCurrentlyStarred[0]
                ? (filledColor ?? Colors.yellow[700])
                : (outlinedColor ?? Colors.grey),
          ),
          onPressed: _handleStarTap,
          tooltip: _isCurrentlyStarred[0]
              ? 'Unstar'
              : 'Star', // Accessibility tooltip
        );
      },
    );
  }
}