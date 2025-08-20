import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Required for max() function

import '../../../../../activity_helpers/DbSqlHelper.dart'; // Adjust path as necessary
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _currentWeekStart = DateTime.now();
  Map<String, Map<String, int>> _dailyNotificationCountsPerPath = {};
  Set<String> _uniquePaths = {};
  Map<String, Color> _pathColors = {};
  bool _isLoading = true;
  int _colorIndex = 0;

  final List<Color> _availableColors = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red,
    Colors.teal, Colors.pink, Colors.amber, Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getStartOfWeek(DateTime.now());
    _fetchAndProcessNotifications();
  }

  // --- All data and week navigation logic is preserved ---
  DateTime _getStartOfWeek(DateTime date) => DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  DateTime _getEndOfWeek(DateTime date) => _getStartOfWeek(date).add(const Duration(days: 6));

  Color _getPathColor(String path) {
    if (!_pathColors.containsKey(path)) {
      _pathColors[path] = _availableColors[_colorIndex % _availableColors.length];
      _colorIndex++;
    }
    return _pathColors[path]!;
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
      _isLoading = true;
    });
    _fetchAndProcessNotifications();
  }

  void _goToNextWeek() {
    if (_getStartOfWeek(_currentWeekStart.add(const Duration(days: 7))).isAfter(_getStartOfWeek(DateTime.now()))) return;
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
      _isLoading = true;
    });
    _fetchAndProcessNotifications();
  }

  Future<void> _fetchAndProcessNotifications() async {
    // Reset state for new week
    setState(() {
      _isLoading = true;
      _dailyNotificationCountsPerPath = {};
      _uniquePaths = {};
      _pathColors.clear();
      _colorIndex = 0;
    });

    try {
      final rawData = await DbSqlHelper.doQueryOnDatabase('DUMMY QUERY');
      final tempDailyCounts = <String, Map<String, int>>{};
      final tempUniquePaths = <String>{};
      final weekStart = _getStartOfWeek(_currentWeekStart);
      final weekEnd = weekStart.add(const Duration(days: 7));

      for (final row in rawData) {
        final decodedJson = DbSqlHelper.safeJsonDecode(row['json_data'] as String? ?? '{}');
        if (decodedJson != null && decodedJson.containsKey('datetime_id')) {
          final notificationDate = DateTime.tryParse(decodedJson['datetime_id'].toString());
          if (notificationDate != null && notificationDate.isAfter(weekStart.subtract(const Duration(microseconds: 1))) && notificationDate.isBefore(weekEnd)) {
            final dayKey = DateFormat('yyyy-MM-dd').format(notificationDate);
            final fullPath = 'notifications~${row['channel'] ?? '?' }~${row['subcollection'] ?? '?'}';
            tempUniquePaths.add(fullPath);
            tempDailyCounts.putIfAbsent(dayKey, () => {}).update(fullPath, (v) => v + 1, ifAbsent: () => 1);
          }
        }
      }
      for (final path in tempUniquePaths) { _getPathColor(path); } // Pre-assign colors
      setState(() {
        _dailyNotificationCountsPerPath = tempDailyCounts;
        _uniquePaths = tempUniquePaths;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching notification data: $e");
      setState(() => _isLoading = false);
    }
  }
  // --- End of logic section ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa), // A gentle off-white background
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87,fontSize: 16)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            _buildChartCard(),
            const SizedBox(height: 24),
            _buildLegendCard(),

            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Currently In Development', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold,color: Colors.black)),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final bool canGoNext = !_getStartOfWeek(_currentWeekStart.add(const Duration(days: 7))).isAfter(_getStartOfWeek(DateTime.now()));
    final int maxNotifications = _getTotalMaxNotifications();
    final double chartMaxY = (maxNotifications == 0 ? 5 : (maxNotifications + 4) ~/ 5 * 5 + 5).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Card Header with Navigation ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: _goToPreviousWeek,
              ),
              Column(
                children: [

                  Text('Daily Activity', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM dd').format(_currentWeekStart)} - ${DateFormat('MMM dd, yyyy').format(_getEndOfWeek(_currentWeekStart))}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 18, color: canGoNext ? Colors.black87 : Colors.grey.shade300),
                onPressed: canGoNext ? _goToNextWeek : null,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // --- Bar Chart ---
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                barGroups: _buildBarGroups(),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _getBottomTitles, reservedSize: 38)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _getLeftTitles, reservedSize: 38, interval: max(1, chartMaxY / 5))),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: max(1, chartMaxY / 5),
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][group.x.toInt()];
                      return BarTooltipItem(
                        '$day\n${rod.toY.toInt()} notifications',
                        GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    final int weeklyTotal = _getTotalNotificationsForWeek();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paths Breakdown', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_uniquePaths.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No notifications for this week.', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
              ),
            )
          else
            ..._uniquePaths.map((path) => _LegendRow(
              color: _getPathColor(path),
              path: path.replaceAll('notifications~', ''),
              count: _getTotalNotificationsForPath(path),
              percentage: weeklyTotal > 0 ? _getTotalNotificationsForPath(path) / weeklyTotal : 0,
            )),
        ],
      ),
    );
  }

  // --- Chart and Legend Helper Methods ---
  int _getTotalMaxNotifications() => _dailyNotificationCountsPerPath.values
      .map((dayCounts) => dayCounts.values.fold(0, (sum, count) => sum + count))
      .fold(0, max);

  int _getTotalNotificationsForPath(String path) => _dailyNotificationCountsPerPath.values
      .map((dayCounts) => dayCounts[path] ?? 0)
      .fold(0, (sum, count) => sum + count);

  int _getTotalNotificationsForWeek() => _dailyNotificationCountsPerPath.values
      .expand((dayCounts) => dayCounts.values)
      .fold(0, (sum, count) => sum + count);

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(7, (i) {
      final dayKey = DateFormat('yyyy-MM-dd').format(_currentWeekStart.add(Duration(days: i)));
      final dailyTotal = _dailyNotificationCountsPerPath[dayKey]?.values.fold(0, (sum, count) => sum + count) ?? 0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: dailyTotal.toDouble(),
            color: Colors.blueAccent,
            width: 22,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    final text = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][value.toInt()];
    return SideTitleWidget(
      meta: meta,
      space: 8.0,
      child: Text(text, style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    if (value == meta.max) return Container(); // Hide top value
    return SideTitleWidget(
      meta: meta,
      space: 4.0,
      child: Text(value.toInt().toString(), style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
    );
  }
}

// --- Custom Widget for a row in the Legend/Breakdown card ---
class _LegendRow extends StatelessWidget {
  final Color color;
  final String path;
  final int count;
  final double percentage;

  const _LegendRow({
    required this.color,
    required this.path,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(path, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Text(count.toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: color.withOpacity(0.15),
                color: color,
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}