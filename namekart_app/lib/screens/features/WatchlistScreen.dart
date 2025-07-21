import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:namekart_app/activity_helpers/DbSqlHelper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../activity_helpers/GlobalFunctions.dart';
import '../../activity_helpers/GlobalVariables.dart';
import '../../activity_helpers/UIHelpers.dart';
import '../live_screens/live_details_screen.dart';
// Assuming your HiveHelper is in 'hive_helper.dart'

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  // Store the full list of all watchlist items
  List<Map<String, dynamic>> _allWatchlistItems = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _filteredWatchlistItems = [];

  @override
  void initState() {
    super.initState();
    _loadWatchlistData();
  }

  Future<void> _loadWatchlistData() async {
    final List<Map<String, dynamic>> watchlist = await DbSqlHelper.getWatchlist();

    // Extract unique categories (paths) from the 'path' key of each item
    final Set<String> uniqueCategories = {};
    watchlist.forEach((item) {
      if (item.containsKey('path')) {
        uniqueCategories.add(item['path'].toString());
      }
    });

    setState(() {
      _allWatchlistItems = watchlist;
      _categories = [
        'All',
        ...uniqueCategories.toList()..sort()
      ]; // Add 'All' and sort others
      _filterWatchlistItems(); // Initial filter
    });
  }

  void _filterWatchlistItems() {
    if (_selectedCategory == 'All') {
      _filteredWatchlistItems = List.from(_allWatchlistItems); // Show all items
    } else {
      _filteredWatchlistItems = _allWatchlistItems
          .where((item) => item['path'] == _selectedCategory)
          .toList();
    }
    setState(() {}); // Trigger rebuild
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Color(0xffF7F7F7),

      appBar: AppBar(
        elevation: 10,
        backgroundColor: Color(0xffF7F7F7),
        surfaceTintColor: Color(0xffF7F7F7),
        iconTheme: const IconThemeData(color: Color(0xff3F3F41), size: 15),
        actions: [
          SizedBox(width: 10,),
          Container(
            width: 2,
            height: 25.sp,
            color: Colors.black12,
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.list_alt_sharp)
          )
        ],
        title: text(text: "Watchlist", size: 10, color: Color(0xff717171), fontWeight: FontWeight.w400),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // Horizontal Category Filter Bar
          SizedBox(
            height: 58, // Fixed height for the chips
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: text(text: category,color: isSelected?Colors.black:Colors.white,fontWeight: FontWeight.w300,size: 8),
                    selected: isSelected,
                    selectedColor: Colors.white,
                    // Primary color for selected chip
                    disabledColor: Colors.black,
                    // Subtle color for unselected
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterWatchlistItems();
                        });
                      }
                    },
                    labelStyle: textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? Colors.black
                          : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.black
                            : Colors.white,
                        width: 1.0,
                      ),
                    ),
                    backgroundColor: Colors.black,
                    elevation: isSelected ? 4 : 0,
                    pressElevation: 8,
                  ),
                );
              },
            ),
          ),
          // Watchlist Items List
          Expanded(
              child: _filteredWatchlistItems.isEmpty
                  ? Center(
                      child: Text(
                        _allWatchlistItems.isEmpty && _selectedCategory == 'All'
                            ? 'Loading watchlist...'
                            : 'No items in this category yet.',
                        style: textTheme.titleMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ScrollablePositionedList.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      reverse: true,
                      // Display newest at the bottom
                      padding: EdgeInsets.all(12.w),
                      // Adjusted to screenutil
                      itemCount: _filteredWatchlistItems.length,
                      minCacheExtent: 2000,
                      itemBuilder: (context, index) {
                        final itemEntry = _filteredWatchlistItems[index];
                        // auctionItem is the full map under datetime_id
                        final auctionItem =
                            itemEntry['itemData'] as Map<dynamic, dynamic>;
                        // hiveDatabasePath is the "main~collections~subcollections" part
                        final hiveDatabasePath = itemEntry['path'] as String;

                        var data = auctionItem['data'] as Map<dynamic, dynamic>;
                        var actionDoneList = auctionItem['actionsDone'];

                        // Debug print (keep for understanding, remove in production if too verbose)
                        print("object ${auctionItem['actionsDone']}");

                        bool ringStatus = false;
                        try {
                          var deviceNotification =
                              auctionItem['device_notification'];
                          if (deviceNotification is List &&
                              deviceNotification.isNotEmpty) {
                            for (var item in deviceNotification) {
                              if (item is Map &&
                                  item.containsKey('ringAlarm')) {
                                var ringValue = item['ringAlarm'];
                                if (ringValue == true || ringValue == 'true') {
                                  ringStatus = true;
                                  break;
                                }
                              }
                            }
                          }
                        } catch (e) {
                          print('Error checking ringStatus: $e');
                        }

                        String readStatus = auctionItem['read']?.toString() ??
                            'yes'; // Default to 'yes' if not present



                        // Date header logic
                        final date =
                            extractDate(auctionItem['datetime_id'].toString());
                        final nextDate =
                            index < _filteredWatchlistItems.length - 1
                                ? extractDate(_filteredWatchlistItems[index + 1]
                                        ['itemData']['datetime_id']
                                    .toString())
                                : null;

                        final showHeader = date != nextDate;

                        // Access theme for colors/text styles
                        final textTheme = Theme.of(context).textTheme;
                        final colorScheme = Theme.of(context).colorScheme;

                        return Column(
                          children: [
                            SizedBox(height: 10.h), // Adjusted to screenutil
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (showHeader)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin:
                                            EdgeInsets.symmetric(vertical: 8.h),
                                        // Adjusted to screenutil
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.w, vertical: 6.h),
                                        // Adjusted to screenutil
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceVariant
                                              .withOpacity(0.5),
                                          // Subtle background for date
                                          borderRadius: BorderRadius.circular(
                                              10.w), // Adjusted to screenutil
                                        ),
                                        child: text(
                                          text: date,
                                          color: colorScheme.onSurfaceVariant,
                                          size: 9.sp, // Adjusted to screenutil
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                Bounceable(
                                  onTap: (){
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => LiveDetailsScreen(
                                      mainCollection: hiveDatabasePath.split("~")[0],
                                      subCollection: hiveDatabasePath.split("~")[1],
                                      subSubCollection: hiveDatabasePath.split("~")[2],
                                      showHighlightsButton: hiveDatabasePath.split("~")[1].contains("live"),
                                      img:hiveDatabasePath.split("~")[2]=="Live-DC" ? "assets/images/home_screen_images/livelogos/dropcatch.png"
                                            : hiveDatabasePath.split("~")[2]=="Live-DD" ? "assets/images/home_screen_images/livelogos/dynadot.png"
                                            : hiveDatabasePath.split("~")[2]=="Live-SAV" ? "assets/images/home_screen_images/livelogos/sav.png"
                                            : hiveDatabasePath.split("~")[2]=="Live-GD" ? "assets/images/home_screen_images/livelogos/godaddy.png"
                                            : hiveDatabasePath.split("~")[2]=="Live-NC" ? "assets/images/home_screen_images/livelogos/namecheap.png"
                                            : hiveDatabasePath.split("~")[2]=="Live-NS" ? "assets/images/home_screen_images/livelogos/namesilo.png":"",
                                      scrollToDatetimeId: auctionItem["datetime_id"],
                                    )));
                                  },
                                  child: Card(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      side: ringStatus
                                          ? const BorderSide(
                                              color: Colors.redAccent,
                                              width: 2,
                                            )
                                          : const BorderSide(
                                              color: Colors.transparent,
                                              width: 0),
                                      borderRadius: BorderRadius.circular(
                                          20.w), // Adjusted to screenutil
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(15.w),
                                      // Adjusted to screenutil
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                // Use Expanded to prevent overflow
                                                child: text(
                                                  text: data['h1'] ?? 'No Title',
                                                  size: 12
                                                      .sp, // Adjusted to screenutil
                                                  fontWeight: FontWeight.w400,
                                                  color: const Color(0xff3F3F41),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  if (readStatus == "no")
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 18.w),
                                                      // Adjusted to screenutil
                                                      child: Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          color:
                                                              Color(0xff4CAF50),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                                3),
                                                      ),
                                                    ),
                                                ],
                                              )
                                            ],
                                          ),
                                          SizedBox(height: 5.h),
                                          // h2, h3, ... as bubble-like items (Highlights section)

                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 5.h),
                                            child: Wrap(
                                              spacing: 8.w,
                                              runSpacing: 8.h,
                                              children: [
                                                ...[
                                                  data['h2'],
                                                  data['h3'],
                                                  data['h4'],
                                                  data['h5'],
                                                  data['h6'],
                                                  data['h7'],
                                                  data['h8'],
                                                  data['h9'],
                                                  data['h10'],
                                                ]
                                                    .where((value) =>
                                                        value != null &&
                                                        value
                                                            .toString()
                                                            .isNotEmpty)
                                                    .join(' | ')
                                                    .split('|')
                                                    .map(
                                                      (item) => Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                                vertical: 6.h,
                                                                horizontal: 10.w),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8.w),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .grey.shade300,
                                                              blurRadius: 0.5,
                                                            ),
                                                          ],
                                                        ),
                                                        child: text(
                                                            text: item.trim(),
                                                            size: 8.sp,
                                                            color: const Color(
                                                                0xff717171),
                                                            fontWeight:
                                                                FontWeight.w400),
                                                      ),
                                                    )
                                                    .toList(),
                                              ],
                                            ),
                                          ),

                                          SizedBox(height: 10.h),
                                          // Compact datetime
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              text(
                                                text: formatToIST(
                                                    auctionItem['datetime_id']
                                                        .toString()),
                                                size: 8.sp,
                                                color: const Color(0xff717171),
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    )),
        ],
      ),
    );
  }
}
