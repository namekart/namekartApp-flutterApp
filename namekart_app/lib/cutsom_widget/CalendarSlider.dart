import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarSlider extends StatefulWidget {
  final DateTime initialDate;
  final DateTime finalDate;
  final DateTime? defaultSelectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarSlider({
    Key? key,
    required this.initialDate,
    required this.finalDate,
    this.defaultSelectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<CalendarSlider> createState() => _CalendarSliderState();
}

class _CalendarSliderState extends State<CalendarSlider> {
  late DateTime _selectedDate;
  late ScrollController _monthController;
  late ScrollController _dateController;

  @override
  void initState() {
    super.initState();
    _selectedDate = _validateDefaultSelectedDate();
    _monthController = ScrollController();
    _dateController = ScrollController();

    // Scroll to the selected date after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedMonth();
      _scrollToSelectedDate();
    });
  }

  // Validate the defaultSelectedDate to ensure it falls within initialDate and finalDate
  DateTime _validateDefaultSelectedDate() {
    if (widget.defaultSelectedDate != null) {
      final defaultDate = widget.defaultSelectedDate!;
      if (defaultDate.isAfter(widget.initialDate.subtract(Duration(days: 1))) &&
          defaultDate.isBefore(widget.finalDate.add(Duration(days: 1)))) {
        return defaultDate;
      }
    }
    return widget.initialDate;
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  List<DateTime> _getMonths() {
    List<DateTime> months = [];
    DateTime current = DateTime(widget.initialDate.year, widget.initialDate.month);
    while (current.isBefore(widget.finalDate) || current.isAtSameMomentAs(widget.finalDate)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1);
    }
    return months;
  }

  List<DateTime> _getDatesInMonth(DateTime month) {
    List<DateTime> dates = [];
    DateTime firstDay = DateTime(month.year, month.month);
    DateTime lastDay = DateTime(month.year, month.month + 1, 0);
    if (month.month == widget.finalDate.month && month.year == widget.finalDate.year) {
      lastDay = widget.finalDate;
    }
    for (int i = 0; i <= lastDay.day - firstDay.day; i++) {
      dates.add(DateTime(month.year, month.month, firstDay.day + i));
    }
    return dates;
  }

  // Scroll to the selected month
  void _scrollToSelectedMonth() {
    final months = _getMonths();
    final selectedMonthIndex = months.indexWhere(
          (month) =>
      month.year == _selectedDate.year && month.month == _selectedDate.month,
    );

    if (selectedMonthIndex != -1) {
      // Use a more accurate item width (adjust based on actual measurement)
      const itemWidth = 120.0; // Increased to account for padding and content
      final offset = selectedMonthIndex * itemWidth;

      // Ensure the ListView is laid out before scrolling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_monthController.hasClients) {
          _monthController.animateTo(
            offset,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  // Scroll to the selected date
  void _scrollToSelectedDate() {
    final dates = _getDatesInMonth(_selectedDate);
    final selectedDateIndex = dates.indexWhere(
          (date) => date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year,
    );
    if (selectedDateIndex != -1) {
      const itemWidth = 70.0; // Approximate width of each date item (adjust as needed)
      final offset = selectedDateIndex * itemWidth;
      _dateController.animateTo(
        offset,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = _getMonths();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: SizedBox(
            height: 54,
            child: ListView.builder(
              controller: _monthController,
              scrollDirection: Axis.horizontal,
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                final isSelected = month.year == _selectedDate.year && month.month == _selectedDate.month;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(month.year, month.month, 1);
                        widget.onDateSelected(_selectedDate);
                        _scrollToSelectedMonth();
                        _scrollToSelectedDate();
                        Haptics.vibrate(HapticsType.success);
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 250),
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                          colors: [Color(0xFF6E00FF), Color(0xFFE100FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : null,
                        color: isSelected ? null : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          DateFormat('MMM yyyy').format(month),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Date Slider
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 12),
          child: SizedBox(
            height: 80,
            child: ListView.builder(
              controller: _dateController,
              scrollDirection: Axis.horizontal,
              itemCount: _getDatesInMonth(_selectedDate).length,
              itemBuilder: (context, index) {
                final date = _getDatesInMonth(_selectedDate)[index];
                final isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month &&
                    date.year == _selectedDate.year;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                        widget.onDateSelected(_selectedDate);
                        _scrollToSelectedDate();

                        Haptics.vibrate(HapticsType.success);
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 250),
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                          colors: [Color(0xFF6E00FF), Color(0xFFE100FF)],
                        )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.25),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('dd').format(date),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('EEE').format(date),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}