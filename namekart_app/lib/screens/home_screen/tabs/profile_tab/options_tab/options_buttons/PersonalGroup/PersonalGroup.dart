import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import '../../../../../../../activity_helpers/DbSqlHelper.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../../../../../../activity_helpers/DbAccountHelper.dart';
import '../../../../../../../activity_helpers/UIHelpers.dart';
import 'PersonalGroupDetails.dart';

// --- Shared Models/Enums ---
// IMPORTANT: Keep these models consistent across PersonalGroup.dart and DbSqlHelper.dart
enum FilterCondition {
  contains,
  endsWith,
  startsWith,
  equalsCaseSensitive,
  equalsCaseInsensitive,
  greaterThan,
  lessThan,
  regexMatches,
  isEmpty, // Checks for NULL or empty string
  isNotEmpty, // Checks for NOT NULL and NOT empty string
  isNumber, // Checks if value can be cast to a number (INTEGER/REAL)
  isNotNumber, // Checks if value cannot be cast to a number
  // directMatch is handled by `jsonPath: DbSqlHelper.anyFieldKeywordSearchKey` and `condition: contains`
}

class QueryCondition {
  final String jsonPath;
  final FilterCondition condition;
  final String value; // Value is always stored as a string, parsed as needed
  final String? categoryName; // Storing the original semantic category name for broad search context

  QueryCondition({
    required this.jsonPath,
    required this.condition,
    this.value = '',
    this.categoryName,
  });

  Map<String, dynamic> toJson() => {
    'jsonPath': jsonPath,
    'condition': condition.name,
    'value': value,
    'categoryName': categoryName,
  };

  factory QueryCondition.fromJson(Map<String, dynamic> json) {
    return QueryCondition(
      jsonPath: json['jsonPath'] ?? '',
      condition: FilterCondition.values.firstWhere(
            (e) => e.name == json['condition'],
        orElse: () => FilterCondition.contains, // Default if not found
      ),
      value: json['value'] ?? '',
      categoryName: json['categoryName'],
    );
  }
}

class GroupFilter {
  final String name;
  final QueryCondition queryCondition; // Stores the complete filter logic

  GroupFilter({
    required this.name,
    required this.queryCondition,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'queryCondition': queryCondition.toJson(),
  };

  factory GroupFilter.fromJson(Map<String, dynamic> json) {
    return GroupFilter(
      name: json['name'] ?? 'Unnamed Group',
      queryCondition: QueryCondition.fromJson(json['queryCondition'] ?? {}),
    );
  }
}
// --- End Shared Models/Enums ---


class PersonalGroup extends StatefulWidget {
  final String currentUserId;
  const PersonalGroup({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<PersonalGroup> createState() => _PersonalGroupState();
}

class _PersonalGroupState extends State<PersonalGroup> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController(); // For semantic category input
  final TextEditingController _valueController = TextEditingController();
  FilterCondition? _selectedCondition; // Holds the currently selected condition in the dialog

  List<GroupFilter> _savedGroups = [];

  final String _accountPath = 'account~user~details';

  @override
  void initState() {
    super.initState();
    _loadSavedGroups();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _categoryNameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  // --- Database Interaction Methods ---
  Future<void> _loadSavedGroups() async {
    try {
      final List<Map<String, dynamic>>? groupsJson = await DbAccountHelper.getPersonalGroup(
        _accountPath,
        widget.currentUserId,
      );

      if (groupsJson != null && groupsJson.isNotEmpty) {
        setState(() {
          _savedGroups = groupsJson.map((json) => GroupFilter.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _savedGroups = [];
        });
      }
    } catch (e) {
      print("Error loading saved groups for user ${widget.currentUserId}: $e");
      showTopSnackbar( "Error loading saved groups.", true);
      setState(() {
        _savedGroups = [];
      });
    }
  }

  Future<void> _addOrUpdateGroup(GroupFilter group) async {
    try {
      await DbAccountHelper.addPersonalGroup(
        _accountPath,
        widget.currentUserId,
        group.toJson(),
      );
      await _loadSavedGroups();
      showTopSnackbar( "Group '${group.name}' created successfully!", false);
    } catch (e) {
      print("Error saving group for user ${widget.currentUserId}: $e");
      showTopSnackbar( "Error saving group: $e", true);
    }
  }

  Future<void> _deleteGroup(String groupName) async {
    try {
      await DbAccountHelper.removePersonalGroup(
        _accountPath,
        widget.currentUserId,
        groupName,
      );
      await _loadSavedGroups();
      showTopSnackbar( "Group '$groupName' deleted.", false);
    } catch (e) {
      print("Error deleting group for user ${widget.currentUserId}: $e");
      showTopSnackbar( "Error deleting group: $e", true);
    }
  }

  // Helper to map semantic category names to JSON paths.
  // This map should contain all the user-friendly names and their corresponding
  // JSON paths. For categories that don't map to a single field, use a special
  // key (like DbSqlHelper.anyFieldKeywordSearchKey) which will trigger a broad search.
  static const Map<String, String> _semanticCategoryToJsonPath = {
    'domain': '\$.data.h1', // Specific field for domain
    'age': '\$.data.h2', // Could be in h2 or h5 in your example, picking h2
    'est': '\$.data.h2', // Picking h2
    'gdv': '\$.data.h2', // Picking h2
    'bid': '\$.data.h3', // Specific field for bid
    'cb': '\$.data.h3',
    'ob': '\$.data.h3',
    'rn': '\$.data.h3',
    'ends in': '\$.data.h4', // Specific field
    'read': '\$.read', // Top-level field
    'datetime': '\$.datetime_id', // Top-level field
    'title': '\$.device_notification[0].title', // Assuming first item in array
    'message': '\$.device_notification[0].message',
    'topic': '\$.device_notification[0].topic',
    'ringalarm': '\$.device_notification[0].ringAlarm',
    'button': '\$.uiButtons[*].button_text', // Use wildcard for array elements in buttons
    'watch button': '\$.uiButtons[*].button_text', // Specific button text
    'stats button': '\$.uiButtons[*].button_text',
    'search button': '\$.uiButtons[*].button_text',
    'leads button': '\$.uiButtons[*].button_text',
    'refresh button': '\$.uiButtons[*].button_text',
    'links button': '\$.uiButtons[*].button_text',
    'customs button': '\$.uiButtons[*].button_text',
    // Broad search fallback: if category is not found in the map, use this special key.
    // This will trigger the broad search logic in DbSqlHelper.getFilteredNotifications.
    'all fields': DbSqlHelper.anyFieldKeywordSearchKey,
    'any': DbSqlHelper.anyFieldKeywordSearchKey,
    'keyword': DbSqlHelper.anyFieldKeywordSearchKey,
  };


  // Helper to get display text for conditions
  String _getConditionDisplayText(FilterCondition condition) {
    switch (condition) {
      case FilterCondition.contains: return "Contains (Text)";
      case FilterCondition.endsWith: return "Ends With (Text)";
      case FilterCondition.startsWith: return "Starts With (Text)";
      case FilterCondition.equalsCaseSensitive: return "Equals (Case-Sensitive Text)";
      case FilterCondition.equalsCaseInsensitive: return "Equals (Case-Insensitive Text)";
      case FilterCondition.greaterThan: return "Greater Than (Number)";
      case FilterCondition.lessThan: return "Less Than (Number)";
      case FilterCondition.regexMatches: return "RegEx Matches";
      case FilterCondition.isEmpty: return "Is Empty (Null or '')";
      case FilterCondition.isNotEmpty: return "Is Not Empty (Not Null and not '')";
      case FilterCondition.isNumber: return "Is Number (e.g., Age, GDV, Bids)";
      case FilterCondition.isNotNumber: return "Is Not Number (e.g., Domain, Status Text)";
      default: return "Unknown Condition";
    }
  }

  // Determines if the selected condition requires a value input
  bool _conditionRequiresValue(FilterCondition? condition) {
    return ![
      FilterCondition.isEmpty,
      FilterCondition.isNotEmpty,
      FilterCondition.isNumber,
      FilterCondition.isNotNumber,
      null // If no condition is selected yet
    ].contains(condition);
  }

  // Determines the keyboard type for the value input
  TextInputType _getValueKeyboardType(FilterCondition? condition) {
    if (condition == FilterCondition.greaterThan || condition == FilterCondition.lessThan) {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  // --- UI Methods ---
  void _showCreateGroupDialog() {
    _groupNameController.clear();
    _categoryNameController.clear();
    _valueController.clear();
    _selectedCondition = null; // Reset selected condition

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text(
                "Create New Group Filter",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                  minHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "1. Group Name",
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _groupNameController,
                        decoration: InputDecoration(
                          labelText: "e.g., 'High Age Domains'",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Colors.deepPurple, width: 2.0),
                          ),
                          labelStyle: TextStyle(fontSize: 10.sp, color: Colors.blueGrey[700]),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                        style: TextStyle(fontSize: 10.sp, color: Colors.black87),
                      ),
                      SizedBox(height: 16.h),

                      Text(
                        "2. Category Name (e.g., Domain, Age, Read Status)",
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _categoryNameController,
                        decoration: InputDecoration(
                          labelText: "e.g., 'Domain', 'Age', 'Read', 'Button', 'All Fields'",
                          hintText: "Enter a recognized category name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Colors.deepPurple, width: 2.0),
                          ),
                          labelStyle: TextStyle(fontSize: 10.sp, color: Colors.blueGrey[700]),
                          hintStyle: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                        style: TextStyle(fontSize: 10.sp, color: Colors.black87),
                      ),
                      SizedBox(height: 16.h),

                      Text(
                        "3. Condition",
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueAccent),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<FilterCondition>(
                            isExpanded: true,
                            value: _selectedCondition,
                            hint: Text(
                              "Select a condition",
                              style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                            ),
                            items: FilterCondition.values.map((condition) {
                              return DropdownMenuItem(
                                value: condition,
                                child: Text(_getConditionDisplayText(condition),
                                    style: TextStyle(fontSize: 10.sp, color: Colors.black87)),
                              );
                            }).toList(),
                            onChanged: (FilterCondition? newValue) {
                              setStateSB(() {
                                _selectedCondition = newValue;
                                // Clear value if condition no longer requires it
                                if (!_conditionRequiresValue(newValue)) {
                                  _valueController.clear();
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Value input field, conditionally displayed
                      if (_conditionRequiresValue(_selectedCondition))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "4. Value",
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: _valueController,
                              keyboardType: _getValueKeyboardType(_selectedCondition),
                              decoration: InputDecoration(
                                labelText: "Enter value for comparison",
                                hintText: _selectedCondition == FilterCondition.greaterThan || _selectedCondition == FilterCondition.lessThan
                                    ? "e.g., 10, 25.5"
                                    : "e.g., .com, yes, example",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2.0),
                                ),
                                labelStyle: TextStyle(fontSize: 10.sp, color: Colors.blueGrey[700]),
                                hintStyle: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                                contentPadding: const EdgeInsets.all(10),
                              ),
                              style: TextStyle(fontSize: 10.sp, color: Colors.black87),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                  ),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_groupNameController.text.isEmpty || _categoryNameController.text.isEmpty || _selectedCondition == null) {
                      showTopSnackbar( "Please fill all required fields.", true);
                      return;
                    }

                    if (_conditionRequiresValue(_selectedCondition) && _valueController.text.isEmpty) {
                      showTopSnackbar( "Please enter a value for the selected condition.", true);
                      return;
                    }

                    // Validate numeric input if required
                    if (_selectedCondition == FilterCondition.greaterThan || _selectedCondition == FilterCondition.lessThan) {
                      if (double.tryParse(_valueController.text) == null) {
                        showTopSnackbar( "Value for numeric comparison must be a valid number.", true);
                        return;
                      }
                    }

                    // Map semantic category name to JSON path
                    String categoryInput = _categoryNameController.text.toLowerCase().trim();
                    String? jsonPath = _semanticCategoryToJsonPath[categoryInput];

                    if (jsonPath == null) {
                      // If the category name doesn't map, fallback to broad search
                      jsonPath = DbSqlHelper.anyFieldKeywordSearchKey;
                      showTopSnackbar( "Category '${_categoryNameController.text}' not explicitly recognized. Performing a broad search.", false);
                      // Consider if you want to prevent creation if not a recognized category
                      // if (jsonPath == null) {
                      //   showTopSnackbar(context, "Category '${_categoryNameController.text}' not recognized. Please use a recognized category like 'Domain', 'Age', 'Read', or 'All Fields'.", true);
                      //   return;
                      // }
                    }


                    final QueryCondition newQueryCondition = QueryCondition(
                      jsonPath: jsonPath, // Use the mapped JSON path (or broad search key)
                      condition: _selectedCondition!,
                      value: _valueController.text.trim(),
                      categoryName: categoryInput, // Store the original category name for broad search context
                    );

                    final newGroup = GroupFilter(
                      name: _groupNameController.text.trim(),
                      queryCondition: newQueryCondition,
                    );

                    await _addOrUpdateGroup(newGroup);
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  ),
                  child: const Text("Create Group"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xffF7F7F7),
        surfaceTintColor: const Color(0xffF7F7F7),
        titleSpacing: 0,
        title: text(
            text: "Personal Groups",
            size: 12.sp,
            color: const Color(0xff717171),
            fontWeight: FontWeight.bold),
      ),
      body: Column(
        children: [
          Expanded(
            child: _savedGroups.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Image.asset("assets/images/home_screen_images/options_tab/nogroupcreatedyet.png"),
              )
            )
                : ListView.builder(
              itemCount: _savedGroups.length,
              itemBuilder: (context, index) {
                final group = _savedGroups[index];

                // Determine display category name for UI
                String displayCategoryName;
                if (group.queryCondition.jsonPath == DbSqlHelper.anyFieldKeywordSearchKey) {
                  displayCategoryName = "'${group.queryCondition.categoryName ?? 'Any Field'}'";
                } else {
                  // Attempt to reverse map for better display, or just show the JSON path
                  final reverseMapped = _semanticCategoryToJsonPath.entries
                      .firstWhere(
                          (entry) => entry.value == group.queryCondition.jsonPath,
                      orElse: () => MapEntry('', group.queryCondition.jsonPath) // Fallback to raw path
                  );
                  displayCategoryName = reverseMapped.key.isNotEmpty ? reverseMapped.key : reverseMapped.value;
                }

                // Determine whether value is required for display logic
                bool showValue = _conditionRequiresValue(group.queryCondition.condition);


                return Bounceable(
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PersonalGroupDetails(
                          groupFilter: group,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(
                            text: group.name,
                            size: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                          SizedBox(height: 4.h),
                          text(
                              text: "Category: $displayCategoryName",
                              size: 9.sp,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold
                          ),
                          text(
                              text: "Condition: ${_getConditionDisplayText(group.queryCondition.condition)}",
                              size: 9.sp,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold
                          ),
                          if (showValue)
                            text(
                                text: "Value: '${group.queryCondition.value}'",
                                size: 9.sp,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold
                            ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red, size: 24.w),
                                onPressed: () {
                                  _deleteGroup(group.name);
                                },
                                tooltip: "Delete Group",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}