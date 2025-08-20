import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/fcm/FcmHelper.dart';
import 'package:text_scroll/text_scroll.dart';

import '../../../../../activity_helpers/GlobalFunctions.dart';
import '../../../../../activity_helpers/UIHelpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State for managing local storage info
  double _totalStorageMB = 250.0;
  double _usedStorageMB = 45.7;

  // Method to handle clearing the cache
  void _clearCache() {
    // In a real app, you would delete files from the cache directory here.
    // For this demo, we'll just reset the state.
    setState(() {
      _usedStorageMB = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache has been cleared.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Method to show a confirmation dialog before clearing data
  Future<void> _showClearDataDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: text(text: 'Clear Cache?', fontWeight: FontWeight.bold, size: 18,color: Colors.black),
          content: text(
              text: 'This will remove temporary data. Are you sure you want to continue?',
              size: 14,
              color: Colors.grey.shade700,fontWeight: FontWeight.bold),
          actions: [
            TextButton(
              child: text(text: 'Cancel', color: Colors.grey.shade800,fontWeight: FontWeight.bold,size: 12.sp),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: text(text: 'Clear', color: Colors.red,size: 12.sp,fontWeight: FontWeight.bold),
              onPressed: () {
                Navigator.of(context).pop();
                _clearCache();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA), // A gentle off-white background
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87),
        title: text(
          text: "Settings",
          fontWeight: FontWeight.w600,
          size: 18,
          color: Colors.black87,
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Storage Management Section ---
          _buildSectionHeader("Storage"),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The storage ring chart
                      SizedBox.expand(
                        child: CustomPaint(
                          painter: _StorageRingPainter(
                            progressPercent: _usedStorageMB / _totalStorageMB,
                            backgroundColor: Colors.grey.shade200,
                            progressColor: Colors.blue,
                          ),
                        ),
                      ),
                      // The text inside the chart
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          text(
                            text: "${_usedStorageMB.toStringAsFixed(1)} MB",
                            size: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                          text(
                            text: "Used",
                            size: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                  title: text(
                      text: "Clear Cache",
                      size: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                  subtitle: text(
                      text: "Frees up space by deleting temporary data",
                      size: 12,
                      color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold),
                  onTap: _showClearDataDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // --- Appearance Section (Theme) ---
          _buildSectionHeader("Appearance"),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 15),
                text(
                  text: "Theme Options",
                  size: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 5),
                text(
                  text: "Coming Soon!",
                  size: 14,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to create section headers consistently
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: text(
        text: title,
        size: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}

/// A custom painter to draw the circular storage progress ring.
class _StorageRingPainter extends CustomPainter {
  final double progressPercent;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _StorageRingPainter({
    required this.progressPercent,
    required this.backgroundColor,
    required this.progressColor,
    this.strokeWidth = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the background ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Paint for the progress ring
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    // Draw the background ring
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw the progress arc
    final progressAngle = 2 * pi * progressPercent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from the top
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint whenever the widget rebuilds
  }
}






