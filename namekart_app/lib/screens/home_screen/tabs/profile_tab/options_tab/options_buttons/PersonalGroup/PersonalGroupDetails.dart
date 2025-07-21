import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'dart:convert'; // Import for JSON encoding
import 'package:google_fonts/google_fonts.dart'; // Import for Google Fonts

import '../../../../../../../activity_helpers/DbSqlHelper.dart';
import '../../../../../../live_screens/live_details_screen.dart';
import 'PersonalGroup.dart';

// Assuming CustomSnackBar is defined elsewhere or from the package
// If not, you might need to adjust showTopSnackbar call or define CustomSnackBar.
// For example:
// class CustomSnackBar extends StatelessWidget {
//   final String message;
//   final Color backgroundColor;
//
//   const CustomSnackBar.info({Key? key, required this.message, this.backgroundColor = Colors.blue}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: backgroundColor,
//       margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.w)),
//       child: Padding(
//         padding: EdgeInsets.all(12.w),
//         child: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
//       ),
//     );
//   }
// }

class PersonalGroupDetails extends StatefulWidget {
  final GroupFilter groupFilter;
  final String currentUserId;

  const PersonalGroupDetails({
    Key? key,
    required this.groupFilter,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<PersonalGroupDetails> createState() => _PersonalGroupDetailsState();
}

class _PersonalGroupDetailsState extends State<PersonalGroupDetails> {
  List<Map<dynamic, dynamic>> _filteredNotifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _applyFilter(widget.groupFilter);
  }

  Future<void> _applyFilter(GroupFilter groupFilter) async {
    setState(() {
      _isLoading = true;
      _filteredNotifications = [];
    });

    try {
      final results = await DbSqlHelper.getFilteredNotifications(
        condition: groupFilter.queryCondition,
        orderBy: 'json_extract(json_data, "\$.datetime_id") DESC',
      );

      setState(() {
        _filteredNotifications = results;
      });
    } catch (e) {
      print("Error applying filter for group '${groupFilter.name}': $e");
      // Updated showTopSnackbar for consistency
      showTopSnackbar("Error applying filter: $e",
          false, // Example custom color
        );

    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getConditionDisplayText(FilterCondition condition) {
    switch (condition) {
      case FilterCondition.contains:
        return "Contains (Text)";
      case FilterCondition.endsWith:
        return "Ends With (Text)";
      case FilterCondition.startsWith:
        return "Starts With (Text)";
      case FilterCondition.equalsCaseSensitive:
        return "Equals (Case-Sensitive Text)";
      case FilterCondition.equalsCaseInsensitive:
        return "Equals (Case-Insensitive Text)";
      case FilterCondition.greaterThan:
        return "Greater Than (Number)";
      case FilterCondition.lessThan:
        return "Less Than (Number)";
      case FilterCondition.regexMatches:
        return "RegEx Matches";
      case FilterCondition.isEmpty:
        return "Is Empty";
      case FilterCondition.isNotEmpty:
        return "Is Not Empty";
      case FilterCondition.isNumber:
        return "Is Number";
      case FilterCondition.isNotNumber:
        return "Is Not Number";
      default:
        return "Unknown Condition";
    }
  }


  @override
  Widget build(BuildContext context) {
    final group = widget.groupFilter;

    bool conditionRequiresValue(FilterCondition? condition) {
      return ![
        FilterCondition.isEmpty,
        FilterCondition.isNotEmpty,
        FilterCondition.isNumber,
        FilterCondition.isNotNumber,
        null
      ].contains(condition);
    }

    String displayJsonPath;
    if (group.queryCondition.jsonPath == DbSqlHelper.anyFieldKeywordSearchKey) {
      displayJsonPath = "Any Text Field (Broad Search)";
    } else {
      displayJsonPath = group.queryCondition.jsonPath;
    }

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xffF7F7F7),
        surfaceTintColor: const Color(0xffF7F7F7),
        titleSpacing: 0,
        title: Text( // Using Text directly for GoogleFonts
            "Group Details: ${group.name}",
            style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: const Color(0xff717171),
                fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8.w),
            child: text( // Using Text directly for GoogleFonts
              text: "Filtered Notifications (${_filteredNotifications.length})",
                size: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
          ),
          // Filtered Notifications List
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredNotifications.isEmpty
              ? Padding(
            padding: EdgeInsets.all(16.w),
            child: Text( // Using Text directly for GoogleFonts
                "No notifications match this group filter.",
                style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
          )
              : Expanded(
            child: ListView.builder(
              itemCount: _filteredNotifications.length,
              itemBuilder: (context, index) {
                final notificationData = _filteredNotifications[index];
                // Simulate ringStatus based on 'read' status
                final bool ringStatus = notificationData['read'] == 0; // If unread, set to true

                return GestureDetector(
                  onTap: (){

                    String category = notificationData['path'].toString().split("~")[0];
                    String subCategoryName= notificationData['path'].toString().split("~")[2];
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return LiveDetailsScreen(
                            mainCollection: notificationData['path'].toString().split("~")[0],
                            subCollection: notificationData['path'].toString().split("~")[1],
                            subSubCollection: notificationData['path'].toString().split("~")[2],
                            showHighlightsButton: category.contains("live"),
                            img: (subCategoryName == "godaddy" ||
                                subCategoryName == "dropcatch" ||
                                subCategoryName == "dynadot" ||
                                subCategoryName == "namecheap" ||
                                subCategoryName == "namesilo")
                                ? "assets/images/home_screen_images/livelogos/$subCategoryName.png"
                                : "assets/images/home_screen_images/appbar_images/notification.png",
                            scrollToDatetimeId: notificationData['datetime_id'],

                          );
                        },
                      ),
                    );



                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: ringStatus
                            ? BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        )
                            : BorderSide(
                            color: Colors.transparent,
                            width: 0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.only(top: 0),
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                text( // Using Text directly for GoogleFonts
                                  text:notificationData['data']?['h1'] ?? 'No Title',
                                    size: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                ),
                                // Conditional unread indicator based on `readStatus` (ringStatus)
                                if (ringStatus) // If ringStatus is true (unread)
                                  Padding(
                                    padding: EdgeInsets.only(right: 18.w),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xff4CAF50), // Green dot for unread
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(3.w),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            // Data entries as bubble-like items (replicated from your example)
                            // This part iterates through the 'data' field of the notification
                            if (notificationData.containsKey('data') && notificationData['data'] is Map)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.h),
                                child: Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: (notificationData['data'] as Map).entries
                                      .where((entry) => entry.key != 'h1' && entry.value != null) // Exclude h1 and null values
                                      .map(
                                        (entry) => Container(
                                      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 3,
                                              blurStyle: BlurStyle.outer
                                          ),
                                        ],
                                      ),
                                      child: text( // Using Text directly for GoogleFonts
                                          text:entry.value.toString().length > 50 ? entry.value.toString().substring(0, 50) + '...' : entry.value.toString(),
                                          size: 8.sp,
                                          color: const Color(0xff717171),
                                          fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                      .toList(),
                                ),
                              ),
                            SizedBox(height: 10),
                            // Compact datetime
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                text( // Using Text directly for GoogleFonts
                                  text:"Time: ${notificationData['datetime_id'] ?? notificationData['datetime'] ?? 'N/A'}",
                                    size: 8.sp,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                ),
                                SizedBox(width: 10.w), // Spacer
                                // You can add the star/bookmark icon here if needed
                                // For example:
                                // Icon(
                                //   notificationData['starred'] == 1 ? Icons.star : Icons.star_border,
                                //   size: 16.sp,
                                //   color: notificationData['starred'] == 1 ? Colors.amber : Colors.grey,
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}