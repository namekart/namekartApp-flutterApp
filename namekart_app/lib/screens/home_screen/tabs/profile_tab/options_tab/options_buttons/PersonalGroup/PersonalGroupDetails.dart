import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/screens/home_screen/tabs/profile_tab/options_tab/options_buttons/PersonalGroup/PersonalGroupTutorial.dart';
import 'dart:convert';
import '../../../../../../../activity_helpers/DbSqlHelper.dart';
import '../../../../../../../activity_helpers/DbAccountHelper.dart';
import '../../../../../../../activity_helpers/UIHelpers.dart';
import '../../../../../../live_screens/live_details_screen.dart';
import 'PersonalGroup.dart';
import 'PersonalGroupDetails.dart';


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

  // ADD THESE TWO METHODS HERE:
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
        return "Greater Than (Number/Text)";
      case FilterCondition.lessThan:
        return "Less Than (Number/Text)";
      case FilterCondition.regexMatches:
        return "RegEx Matches";
      case FilterCondition.isEmpty:
        return "Is Empty (Null or '')";
      case FilterCondition.isNotEmpty:
        return "Is Not Empty (Not Null and not '')";
      case FilterCondition.isNumber:
        return "Is Number (e.g., Age, GDV, Bids)";
      case FilterCondition.isNotNumber:
        return "Is Not Number (e.g., Domain, Status Text)";
    }
  }

  String _getNumericOperatorDisplayText(NumericComparisonOperator operator) {
    switch (operator) {
      case NumericComparisonOperator.greaterThan:
        return ">";
      case NumericComparisonOperator.lessThan:
        return "<";
      case NumericComparisonOperator.equals:
        return "=";
      case NumericComparisonOperator.greaterThanOrEqual:
        return ">=";
      case NumericComparisonOperator.lessThanOrEqual:
        return "<=";
    }
  }

  Future<void> _applyFilter(GroupFilter groupFilter) async {
    setState(() {
      _isLoading = true;
      _filteredNotifications = [];
    });

    try {
      List<Map<dynamic, dynamic>> results;

      if (groupFilter.queryCondition.isEmbeddedNumericSearch == true &&
          groupFilter.queryCondition.categoryName != null &&
          groupFilter.queryCondition.embeddedNumericOperator != null &&
          groupFilter.queryCondition.embeddedNumericValue != null) {
        // Call the new dedicated function for embedded numeric search
        results = await DbSqlHelper.getFilteredNotificationsByEmbeddedNumericValue(
          categoryName: groupFilter.queryCondition.categoryName!,
          operator: groupFilter.queryCondition.embeddedNumericOperator!,
          numericValue: groupFilter.queryCondition.embeddedNumericValue!,
          orderBy: 'json_extract(json_data, "\$.datetime_id") DESC',
        );
      } else {
        // Call the original function for all other types of filters
        results = await DbSqlHelper.getFilteredNotifications(
          condition: groupFilter.queryCondition,
          orderBy: 'json_extract(json_data, "\$.datetime_id") DESC',
        );
      }

      setState(() {
        _filteredNotifications = results;
      });
    } catch (e) {
      print("Error applying filter for group '${groupFilter.name}': $e");
      showTopSnackbar(
        "Error applying filter: $e",
        false, // Example custom color
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final group = widget.groupFilter;
    final qc = group.queryCondition;

    String displayFilterDescription;
    if (qc.isEmbeddedNumericSearch == true &&
        qc.categoryName != null &&
        qc.embeddedNumericOperator != null &&
        qc.embeddedNumericValue != null) {
      displayFilterDescription =
      "Searching for '${qc.categoryName}' ${_getNumericOperatorDisplayText(qc.embeddedNumericOperator!)} ${qc.embeddedNumericValue} in hX fields.";
    } else if (qc.jsonPath == DbSqlHelper.anyFieldKeywordSearchKey) {
      displayFilterDescription = "Broad Text Search for '${qc.value}'";
    } else {
      displayFilterDescription =
      "Filtering by '${qc.jsonPath}' with condition '${_getConditionDisplayText(qc.condition)}' and value '${qc.value}'";
    }

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xffF7F7F7),
        surfaceTintColor: const Color(0xffF7F7F7),
        titleSpacing: 0,
        title: Text(
          "Group Details: ${group.name}",
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: const Color(0xff717171),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Text(
              "Filter: $displayFilterDescription",
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Text(
              "Filtered Notifications (${_filteredNotifications.length})",
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredNotifications.isEmpty
              ? Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              "No notifications match this group filter.",
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              : Expanded(
            child: ListView.builder(
              itemCount: _filteredNotifications.length,
              itemBuilder: (context, index) {
                final notificationData = _filteredNotifications[index];
                final bool ringStatus = notificationData['read'] == 0;

                return GestureDetector(
                  onTap: () {
                    String category = notificationData['path'].toString().split("~")[0];
                    String subCategoryName = notificationData['path'].toString().split("~")[2];
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
                            ? const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        )
                            : const BorderSide(
                          color: Colors.transparent,
                          width: 0,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.only(top: 0),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notificationData['data']?['h1'] ?? 'No Title',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                if (ringStatus)
                                  Padding(
                                    padding: EdgeInsets.only(right: 18.w),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xff4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(3.w),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            if (notificationData.containsKey('data') && notificationData['data'] is Map)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.h),
                                child: Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: (notificationData['data'] as Map)
                                      .entries
                                      .where((entry) => entry.key != 'h1' && entry.value != null)
                                      .map(
                                        (entry) => Container(
                                      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 3,
                                            blurStyle: BlurStyle.outer,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        entry.value.toString().length > 50 ? '${entry.value.toString().substring(0, 50)}...' : entry.value.toString(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 8.sp,
                                          color: const Color(0xff717171),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                      .toList(),
                                ),
                              ),
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Time: ${notificationData['datetime_id'] ?? notificationData['datetime'] ?? 'N/A'}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.sp,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10.w),
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