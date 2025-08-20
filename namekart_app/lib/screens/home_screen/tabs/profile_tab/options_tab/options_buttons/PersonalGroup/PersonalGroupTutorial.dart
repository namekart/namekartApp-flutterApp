import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

import '../../../../../../../activity_helpers/UIHelpers.dart';
import 'PersonalGroup.dart';


class PersonalGroupTutorial extends StatefulWidget {
  const PersonalGroupTutorial({super.key});

  @override
  State<PersonalGroupTutorial> createState() => _PersonalGroupTutorialState();
}

class _PersonalGroupTutorialState extends State<PersonalGroupTutorial> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Animations for different aspects, now defined with specific intervals
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _typingValueAnimation; // For typing effect in text fields
  late Animation<Color?> _borderColorAnimation; // For pulsing border
  late Animation<double> _borderWidthAnimation; // For pulsing border width

  // Removed _contentSlideAnimation as we're switching to fade

  Timer? _stepTimer;
  int _currentStep = 0;

  // Simulated values to be updated during the animation
  String _simulatedGroupName = '';
  String _simulatedCategoryName = '';
  FilterCondition? _simulatedCondition;
  String _simulatedValue = '';

  // Target values for the tutorial
  final String _targetGroupName = "High Value Notifications";
  final String _targetCategoryName = "Domain";
  final FilterCondition _targetCondition = FilterCondition.endsWith;
  final String _targetValue = ".com";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000), // Duration for each step
    );

    // Text (title/description) animations
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Typing animation for text fields
    _typingValueAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.9, curve: Curves.linear),
      ),
    );

    // Border color animation
    _borderColorAnimation = ColorTween(
      begin: Colors.blueGrey,
      end: Colors.deepPurpleAccent,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    // Border width animation for pulsing effect
    _borderWidthAnimation = Tween<double>(begin: 1.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _animationController.addListener(() {
      setState(() {
        if (_currentStep == 0) { // Group Name typing
          _simulatedGroupName = _targetGroupName.substring(0, (_targetGroupName.length * _typingValueAnimation.value).toInt());
          _simulatedCategoryName = '';
          _simulatedCondition = null;
          _simulatedValue = '';
        } else if (_currentStep == 1) { // Category Name typing
          _simulatedGroupName = _targetGroupName;
          _simulatedCategoryName = _targetCategoryName.substring(0, (_targetCategoryName.length * _typingValueAnimation.value).toInt());
          _simulatedCondition = null;
          _simulatedValue = '';
        } else if (_currentStep == 2) { // Condition selection
          _simulatedGroupName = _targetGroupName;
          _simulatedCategoryName = _targetCategoryName;
          _simulatedCondition = _animationController.value > 0.7 ? _targetCondition : null;
          _simulatedValue = '';
        } else if (_currentStep == 3) { // Value typing
          _simulatedGroupName = _targetGroupName;
          _simulatedCategoryName = _targetCategoryName;
          _simulatedCondition = _targetCondition;
          _simulatedValue = _targetValue.substring(0, (_targetValue.length * _typingValueAnimation.value).toInt());
        } else if (_currentStep == 4) { // Final greeting - all complete
          _simulatedGroupName = _targetGroupName;
          _simulatedCategoryName = _targetCategoryName;
          _simulatedCondition = _targetCondition;
          _simulatedValue = _targetValue;
        }
      });
    });

    _startTutorialLoop();
  }

  void _startTutorialLoop() {
    _stepTimer?.cancel();
    _currentStep = 0;
    _runStep();
  }

  void _runStep() {
    if (!mounted) return;

    // No need to set _contentSlideAnimation here for fade transition
    _animationController.reset();
    _animationController.forward().whenComplete(() {
      if (!mounted) return;

      _stepTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        setState(() {
          _currentStep++;
          if (_currentStep >= _tutorialContent.length) {
            _startTutorialLoop();
          } else {
            _runStep();
          }
        });
      });
    });
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

  @override
  void dispose() {
    _stepTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  InputDecoration _getAnimatedInputDecoration(String labelText, String hintText, String currentTargetField) {
    bool isTarget = (_currentStep == 0 && currentTargetField == 'group_name') ||
        (_currentStep == 1 && currentTargetField == 'category_name') ||
        (_currentStep == 3 && currentTargetField == 'value');
    if (currentTargetField == 'condition' && _currentStep == 2) {
      isTarget = true;
    }

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: isTarget ? (_borderColorAnimation.value ?? Colors.deepPurpleAccent) : Colors.deepPurple,
          width: isTarget ? _borderWidthAnimation.value : 2.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: isTarget ? (_borderColorAnimation.value ?? Colors.deepPurpleAccent) : Colors.blueGrey,
          width: isTarget ? _borderWidthAnimation.value : 1.0,
        ),
      ),
      labelStyle: TextStyle(fontSize: 10.sp, color: Colors.blueGrey[700]),
      hintStyle: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Widget _buildTutorialField(int stepIndex) {
    Widget fieldWidget;
    String fieldLabel;

    switch (stepIndex) {
      case 0: // Group Name
        fieldLabel = "1. Group Name";
        fieldWidget = TextField(
          controller: TextEditingController(
              text: _currentStep == 0 ? _simulatedGroupName : _targetGroupName
          ),
          readOnly: true,
          decoration: _getAnimatedInputDecoration(
            "e.g., 'High Age Domains'",
            "e.g., 'High Age Domains'",
            'group_name',
          ),
          style: TextStyle(fontSize: 10.sp, color: Colors.black87),
          maxLines: 1,
        );
        break;
      case 1: // Category Name
        fieldLabel = "2. Category Name";
        fieldWidget = TextField(
          controller: TextEditingController(
              text: _currentStep == 1 ? _simulatedCategoryName : _targetCategoryName
          ),
          readOnly: true,
          decoration: _getAnimatedInputDecoration(
            "e.g., 'Domain'",
            "Enter recognized category",
            'category_name',
          ),
          style: TextStyle(fontSize: 10.sp, color: Colors.black87),
          maxLines: 1,
        );
        break;
      case 2: // Condition Dropdown
        fieldLabel = "3. Condition";
        fieldWidget = Container(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: _currentStep == 2
                  ? (_borderColorAnimation.value ?? Colors.deepPurpleAccent)
                  : Colors.blueAccent,
              width: _currentStep == 2 ? _borderWidthAnimation.value : 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<FilterCondition>(
              isExpanded: true,
              value: _simulatedCondition,
              hint: text(
                text: _simulatedCondition == null ? "Select a condition" : _getConditionDisplayText(_simulatedCondition!),
                size: 9.sp,
                color: _simulatedCondition == null ? Colors.grey : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              items: FilterCondition.values.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: text(
                    text: _getConditionDisplayText(condition),
                    size: 9.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              onChanged: null,
            ),
          ),
        );
        break;
      case 3: // Value Input Field
        fieldLabel = "4. Value";
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            TextField(
              controller: TextEditingController(
                  text: _currentStep == 3 ? _simulatedValue : _targetValue
              ),
              readOnly: true,
              decoration: _getAnimatedInputDecoration(
                _simulatedCondition == FilterCondition.greaterThan || _simulatedCondition == FilterCondition.lessThan
                    ? "e.g., 10"
                    : "e.g., .com",
                _simulatedCondition == FilterCondition.greaterThan || _simulatedCondition == FilterCondition.lessThan
                    ? "e.g., 10"
                    : "e.g., .com",
                'value',
              ),
              style: TextStyle(fontSize: 10.sp, color: Colors.black87),
              maxLines: 1,
            ),
          ],
        );
        break;
      default:
        return const SizedBox.shrink(); // Should not happen for valid steps
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        text(
          text: fieldLabel,
          size: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
        SizedBox(height: 4.h),
        fieldWidget,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dynamic Tutorial Text above form fields
        FadeTransition(
          opacity: _textFadeAnimation,
          child: SlideTransition(
            position: _textSlideAnimation,
            child: Column(
              children: [
                text(
                  text: _tutorialContent[_currentStep]['title']!,
                  size: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                SizedBox(height: 8.h),
                text(
                  text: _tutorialContent[_currentStep]['description']!,
                  size: 10.sp,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),

        // --- AnimatedSwitcher for fade transition between fields ---
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 700), // Duration for the fade transition
          transitionBuilder: (Widget child, Animation<double> animation) {
            // Apply a FadeTransition to the child
            return FadeTransition(
              opacity: animation, // Use the provided animation for opacity
              child: child,
            );
          },
          child: (_currentStep < _tutorialContent.length - 1)
              ? _buildTutorialField(_currentStep) // Show field if not on final 'Filter Created' step
              : Container(
            key: const ValueKey('final_step_container'), // Important for AnimatedSwitcher
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: text(
              text: "All fields demonstrated!",
              size: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          key: ValueKey(_currentStep), // Crucial: change key to trigger rebuild and animation
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  // --- REVISED TUTORIAL CONTENT ---
  final List<Map<String, String>> _tutorialContent = [
    {
      'title': '1. Name Your Group',
      'description': 'Start by giving your filter group a clear and unique name, like "High Value Notifications".',
    },
    {
      'title': '2. Choose a Category',
      'description': 'Select the data category you want to filter, such as Domain, Age, or Est...',
    },
    {
      'title': '3. Set a Condition',
      'description': 'Define the filter logic — this step is key. For example, use a text condition to find domains ending in ".com", or a number condition to filter users under age 8.',
    },
    {
      'title': '4. Enter a Value',
      'description': 'Provide the exact value for your condition — like ".com" to match relevant domains or "8" for age filters.',
    },
    {
      'title': '5. Filter Created!',
      'description': 'Nice work! Your filter group is ready. Tap the "+" button to create more filters anytime.',
    },
  ];

}