import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart'; // Assuming Hive is used elsewhere
import 'package:namekart_app/screens/home_screen/tabs/profile_tab/options_tab/options_buttons/PersonalGroup/PersonalGroupTutorial.dart';
import 'dart:convert';
import '../../../../../../../activity_helpers/DbSqlHelper.dart';
import '../../../../../../../activity_helpers/DbAccountHelper.dart';
import '../../../../../../../activity_helpers/UIHelpers.dart';
import 'PersonalGroupDetails.dart';

// --- Shared Models/Enums (Ensuring consistency with DbSqlHelper and PersonalGroupDetails) ---

// lib/screens/home_screen/tabs/profile_tab/options_tab/options_buttons/PersonalGroup/personal_group_models.dart
enum FilterCondition {
  contains, endsWith, startsWith, equalsCaseSensitive, equalsCaseInsensitive,
  greaterThan, lessThan, regexMatches, isEmpty, isNotEmpty, isNumber, isNotNumber,
}

enum NumericComparisonOperator {
  greaterThan, lessThan, equals, greaterThanOrEqual, lessThanOrEqual,
}

class QueryCondition {
  final String jsonPath;
  final FilterCondition condition;
  final String value;
  final String? categoryName;
  final bool isEmbeddedNumericSearch;
  final NumericComparisonOperator? embeddedNumericOperator;
  final double? embeddedNumericValue;

  QueryCondition({
    required this.jsonPath,
    required this.condition,
    this.value = '',
    this.categoryName,
    this.isEmbeddedNumericSearch = false,
    this.embeddedNumericOperator,
    this.embeddedNumericValue,
  });

  Map<String, dynamic> toJson() => {
    'jsonPath': jsonPath, 'condition': condition.name, 'value': value,
    'categoryName': categoryName, 'isEmbeddedNumericSearch': isEmbeddedNumericSearch,
    'embeddedNumericOperator': embeddedNumericOperator?.name,
    'embeddedNumericValue': embeddedNumericValue,
  };

  factory QueryCondition.fromJson(Map<String, dynamic> json) {
    return QueryCondition(
      jsonPath: json['jsonPath'] ?? '',
      condition: FilterCondition.values.firstWhere((e) => e.name == json['condition'], orElse: () => FilterCondition.contains),
      value: json['value'] ?? '',
      categoryName: json['categoryName'],
      isEmbeddedNumericSearch: json['isEmbeddedNumericSearch'] ?? false,
      embeddedNumericOperator: json['embeddedNumericOperator'] != null
          ? NumericComparisonOperator.values.firstWhere((e) => e.name == json['embeddedNumericOperator'], orElse: () => NumericComparisonOperator.equals)
          : null,
      embeddedNumericValue: (json['embeddedNumericValue'] as num?)?.toDouble(),
    );
  }
}

class GroupFilter {
  final String name;
  final QueryCondition queryCondition;

  GroupFilter({required this.name, required this.queryCondition});

  Map<String, dynamic> toJson() => {'name': name, 'queryCondition': queryCondition.toJson()};

  factory GroupFilter.fromJson(Map<String, dynamic> json) {
    return GroupFilter(
      name: json['name'] ?? 'Unnamed Group',
      queryCondition: QueryCondition.fromJson(json['queryCondition'] ?? {}),
    );
  }
}

// --- Main Screen ---

class PersonalGroup extends StatefulWidget {
  final String currentUserId;
  const PersonalGroup({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<PersonalGroup> createState() => _PersonalGroupState();
}

class _PersonalGroupState extends State<PersonalGroup> {
  List<GroupFilter> _savedGroups = [];
  bool _isLoading = true;
  final String _accountPath = 'account~user~details';

  @override
  void initState() {
    super.initState();
    _loadSavedGroups();
  }

  Future<void> _loadSavedGroups() async {
    setState(() => _isLoading = true);
    try {
      final groupsJson = await DbAccountHelper.getPersonalGroup(_accountPath, widget.currentUserId);
      setState(() {
        _savedGroups = groupsJson?.map((json) => GroupFilter.fromJson(json)).toList() ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading saved groups: $e");
      showTopSnackbar("Error loading saved groups.", true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGroup(String groupName) async {
    await DbAccountHelper.removePersonalGroup(_accountPath, widget.currentUserId, groupName);
    showTopSnackbar("Group '$groupName' deleted.", false);
    _loadSavedGroups(); // Refresh list
  }

  void _navigateToCreateScreen() async {
    final newGroup = await Navigator.push<GroupFilter>(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
    );

    if (newGroup != null && mounted) {
      await DbAccountHelper.addPersonalGroup(_accountPath, widget.currentUserId, newGroup.toJson());
      showTopSnackbar("Group '${newGroup.name}' created successfully!", false);
      _loadSavedGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87,size: 24),
        title: Text(
          "Personal Groups",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87,fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const AlertDialog(
                content: SizedBox(height: 250, child: PersonalGroupTutorial()),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : _savedGroups.isEmpty
          ? _EmptyState(onCreate: _navigateToCreateScreen)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedGroups.length,
        itemBuilder: (context, index) {
          final group = _savedGroups[index];
          return _GroupFilterCard(
            group: group,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalGroupDetails(
                  groupFilter: group,
                  currentUserId: widget.currentUserId,
                ),
              ),
            ),
            onDelete: () => _deleteGroup(group.name),
          );
        },
      ),
      floatingActionButton: _savedGroups.isNotEmpty?FloatingActionButton.extended(
        onPressed: _navigateToCreateScreen,
        icon: const Icon(Icons.add),
        label: const Text("Create Group"),
        backgroundColor: Colors.blue.shade700,
      ):SizedBox.shrink(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/images/home_screen_images/options_tab/nogroupcreatedyet.png", width: 300),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text("Create Your First Group"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }
}

class _GroupFilterCard extends StatelessWidget {
  final GroupFilter group;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GroupFilterCard({
    required this.group,
    required this.onTap,
    required this.onDelete,
  });

  String get _conditionDisplayText {
    final qc = group.queryCondition;
    if (qc.isEmbeddedNumericSearch) {
      final op = _getNumericOperatorDisplayText(qc.embeddedNumericOperator!);
      return "$op ${qc.embeddedNumericValue?.toStringAsFixed(2) ?? 'N/A'}";
    }
    final conditionText = _getConditionDisplayText(qc.condition);
    final valueText = [FilterCondition.isEmpty, FilterCondition.isNotEmpty, FilterCondition.isNumber, FilterCondition.isNotNumber].contains(qc.condition)
        ? '' : "'${qc.value}'";
    return "$conditionText $valueText".trim();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue.shade700, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Category: '${group.queryCondition.categoryName ?? 'Any'}'",
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    Text(
                      "Condition: $_conditionDisplayText",
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: onDelete,
                tooltip: "Delete Group",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods copied for display logic
  String _getConditionDisplayText(FilterCondition condition) {
    switch (condition) {
      case FilterCondition.contains: return "Contains";
      case FilterCondition.endsWith: return "Ends With";
      case FilterCondition.startsWith: return "Starts With";
      case FilterCondition.equalsCaseSensitive: return "Equals";
      case FilterCondition.equalsCaseInsensitive: return "Equals (i)";
      case FilterCondition.greaterThan: return ">";
      case FilterCondition.lessThan: return "<";
      case FilterCondition.regexMatches: return "Matches RegEx";
      case FilterCondition.isEmpty: return "Is Empty";
      case FilterCondition.isNotEmpty: return "Is Not Empty";
      case FilterCondition.isNumber: return "Is Number";
      case FilterCondition.isNotNumber: return "Is Not Number";
    }
  }

  String _getNumericOperatorDisplayText(NumericComparisonOperator operator) {
    switch (operator) {
      case NumericComparisonOperator.greaterThan: return ">";
      case NumericComparisonOperator.lessThan: return "<";
      case NumericComparisonOperator.equals: return "=";
      case NumericComparisonOperator.greaterThanOrEqual: return ">=";
      case NumericComparisonOperator.lessThanOrEqual: return "<=";
    }
  }
}


// --- Create/Edit Screen (Wizard Style) ---

enum _FilterType { text, number }

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  int _currentStep = 0;
  final _groupNameController = TextEditingController();
  final _categoryNameController = TextEditingController();
  final _valueController = TextEditingController();
  _FilterType _selectedFilterType = _FilterType.text;
  FilterCondition? _selectedCondition;

  // --- Logic Helpers (migrated from original dialog) ---
  static const Map<String, String> _semanticCategoryToJsonPath = {
    'domain': r'$.data.h1', 'age': r'$.data.h2', 'est': r'$.data.h2', 'gdv': r'$.data.h2',
    'bid': r'$.data.h3', 'cb': r'$.data.h3', 'ob': r'$.data.h3', 'rn': r'$.data.h3',
    'ends in': r'$.data.h4', 'read': r'$.read', 'datetime': r'$.datetime_id',
    'title': r'$.device_notification[0].title', 'message': r'$.device_notification[0].message',
    'topic': r'$.device_notification[0].topic', 'ringalarm': r'$.device_notification[0].ringAlarm',
    'button': r'$.uiButtons[*].button_text', 'watch button': r'$.uiButtons[*].button_text',
    'stats button': r'$.uiButtons[*].button_text', 'search button': r'$.uiButtons[*].button_text',
    'leads button': r'$.uiButtons[*].button_text', 'refresh button': r'$.uiButtons[*].button_text',
    'links button': r'$.uiButtons[*].button_text', 'customs button': r'$.uiButtons[*].button_text',
    'all fields': DbSqlHelper.anyFieldKeywordSearchKey, 'any': DbSqlHelper.anyFieldKeywordSearchKey,
    'keyword': DbSqlHelper.anyFieldKeywordSearchKey,
  };
  static const List<String> _embeddedNumericCategories = ['age', 'est', 'gdv', 'cb', 'ob', 'rn'];

  bool _conditionRequiresValue(FilterCondition? condition) {
    return ![FilterCondition.isEmpty, FilterCondition.isNotEmpty, FilterCondition.isNumber, FilterCondition.isNotNumber, null].contains(condition);
  }

  bool _isEmbeddedNumericSearch() {
    final category = _categoryNameController.text.toLowerCase().trim();
    return _selectedFilterType == _FilterType.number &&
        _embeddedNumericCategories.contains(category) &&
        [FilterCondition.greaterThan, FilterCondition.lessThan, FilterCondition.equalsCaseInsensitive].contains(_selectedCondition);
  }

  void _createAndPopGroup() {
    if (!mounted) return;
    // --- Validation logic ---
    if (_groupNameController.text.isEmpty) { showTopSnackbar("Please enter a Group Name.", true); return; }
    if (_categoryNameController.text.isEmpty) { showTopSnackbar("Please enter a Category Name.", true); return; }
    if (_selectedCondition == null) { showTopSnackbar("Please select a condition.", true); return; }
    if (_conditionRequiresValue(_selectedCondition) && _valueController.text.isEmpty) { showTopSnackbar("Please enter a value.", true); return; }
    if (_selectedFilterType == _FilterType.number && _conditionRequiresValue(_selectedCondition) && double.tryParse(_valueController.text) == null) { showTopSnackbar("Value must be a valid number.", true); return; }

    // --- Build QueryCondition ---
    final categoryInput = _categoryNameController.text.toLowerCase().trim();
    String? jsonPath = _semanticCategoryToJsonPath[categoryInput];
    bool isEmbedded = _isEmbeddedNumericSearch();

    QueryCondition queryCondition;
    if (isEmbedded) {
      NumericComparisonOperator op;
      switch (_selectedCondition) {
        case FilterCondition.greaterThan: op = NumericComparisonOperator.greaterThan; break;
        case FilterCondition.lessThan: op = NumericComparisonOperator.lessThan; break;
        default: op = NumericComparisonOperator.equals; break;
      }
      queryCondition = QueryCondition(
        jsonPath: jsonPath ?? '', value: _valueController.text.trim(),
        condition: _selectedCondition!, categoryName: categoryInput,
        isEmbeddedNumericSearch: true, embeddedNumericOperator: op,
        embeddedNumericValue: double.tryParse(_valueController.text.trim()),
      );
    } else {
      if (jsonPath == null) {
        jsonPath = DbSqlHelper.anyFieldKeywordSearchKey;
        showTopSnackbar("Category '${_categoryNameController.text}' not recognized. Using a broad text search.", false);
      }
      queryCondition = QueryCondition(
        jsonPath: jsonPath, condition: _selectedCondition!,
        value: _valueController.text.trim(), categoryName: categoryInput,
      );
    }
    final newGroup = GroupFilter(name: _groupNameController.text.trim(), queryCondition: queryCondition);
    Navigator.pop(context, newGroup);
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Name'),
        content: Column(
          children: [
            Text('Give your group a unique name so you can easily identify it later.', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(labelText: 'Group Name', border: OutlineInputBorder()),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Target'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify which data category to filter and whether to treat it as text or a number.', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryNameController,
              decoration: const InputDecoration(labelText: 'Category Name', hintText: "e.g., domain, age, any", border: OutlineInputBorder()),
              onChanged: (v) => setState(() { _selectedCondition = null; _valueController.clear(); }),
            ),
            const SizedBox(height: 16),
            Text('Filter Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            Row(
              children: [
                Expanded(child: RadioListTile<_FilterType>(title: const Text('Text'), value: _FilterType.text, groupValue: _selectedFilterType, onChanged: (v) => setState(() { _selectedFilterType = v!; _selectedCondition = null; _valueController.clear(); }))),
                Expanded(child: RadioListTile<_FilterType>(title: const Text('Number'), value: _FilterType.number, groupValue: _selectedFilterType, onChanged: (v) => setState(() { _selectedFilterType = v!; _selectedCondition = null; _valueController.clear(); }))),
              ],
            )
          ],
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Condition'),
        content: Column(
          children: [
            Text('Finally, set the condition and value to complete your filter.', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<FilterCondition>(
              value: _selectedCondition,
              decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder()),
              items: (_selectedFilterType == _FilterType.text
                  ? [FilterCondition.contains, FilterCondition.startsWith, FilterCondition.endsWith, FilterCondition.equalsCaseInsensitive, FilterCondition.regexMatches, FilterCondition.isEmpty, FilterCondition.isNotEmpty]
                  : [FilterCondition.greaterThan, FilterCondition.lessThan, FilterCondition.equalsCaseInsensitive, FilterCondition.isNumber, FilterCondition.isNotNumber]
              ).map((c) => DropdownMenuItem(value: c, child: Text(_getConditionDisplayText(c)))).toList(),
              onChanged: (v) => setState(() => _selectedCondition = v),
            ),
            if (_conditionRequiresValue(_selectedCondition))
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextField(
                  controller: _valueController,
                  keyboardType: _selectedFilterType == _FilterType.number ? TextInputType.number : TextInputType.text,
                  decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                ),
              )
          ],
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Group")),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < _getSteps().length - 1) {
            setState(() => _currentStep += 1);
          } else {
            _createAndPopGroup();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        onStepTapped: (step) => setState(() => _currentStep = step),
        steps: _getSteps(),
      ),
    );
  }

  // Helper for display text, needed by the form
  String _getConditionDisplayText(FilterCondition condition) {
    switch (condition) {
      case FilterCondition.contains: return "Contains";
      case FilterCondition.endsWith: return "Ends With";
      case FilterCondition.startsWith: return "Starts With";
      case FilterCondition.equalsCaseSensitive: return "Equals (Case-Sensitive)";
      case FilterCondition.equalsCaseInsensitive: return "Equals";
      case FilterCondition.greaterThan: return "Greater Than (>)";
      case FilterCondition.lessThan: return "Less Than (<)";
      case FilterCondition.regexMatches: return "Matches RegEx";
      case FilterCondition.isEmpty: return "Is Empty";
      case FilterCondition.isNotEmpty: return "Is Not Empty";
      case FilterCondition.isNumber: return "Is a Number";
      case FilterCondition.isNotNumber: return "Is Not a Number";
    }
  }
}