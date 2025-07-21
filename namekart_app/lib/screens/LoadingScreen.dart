// lib/screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // If you want to use screenutil for sizing
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/screens/home_screen/HomeScreen.dart'; // Import your HomeScreen
import 'package:namekart_app/screens/login_screens/LoginScreen.dart'; // Import your LoginScreen
import 'package:firebase_auth/firebase_auth.dart'; // For checking auth state

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    // 1. Initialize Firebase (already done in main, but good to ensure if this were the first point)
    // await Firebase.initializeApp(); // Only if not already in main

    // 2. Initialize Hive and open boxes
    // This is the crucial part that might take time for large databases.
    // The try-catch block for deleting box from disk and re-opening it is already in your main.dart,
    // which is good for handling corruption, but means the first load might be slower.
    try {
      // Assuming Hive.initFlutter() is already done in main.dart
      // If not, you'd put: await Hive.initFlutter(appDir.path); here
      await Hive.openBox('storage'); // Your existing main storage box
      // If you're going to refactor to multiple boxes, you'd call HiveHelper.init() here:
      // await HiveHelper.init(); // This would open all the relevant boxes
    } catch (e) {
      // Handle cases where the box might be corrupted/locked
      print("Error opening Hive box: $e. Attempting to delete and re-open.");
      await Hive.deleteBoxFromDisk('storage');
      await Hive.openBox('storage');
    }

    // You might also want to do other async initialization here,
    // e.g., pre-loading some initial data, setting up complex services.

    // 3. Check authentication status
    // Determine where to navigate after initialization
    User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return; // Check if the widget is still in the tree

    if (user != null) {
      // User is logged in, navigate to Home Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // User is not logged in, navigate to Login Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or your app's background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/login_screen_images/loginpagenamekartlogo.png",
              width: 200.sp, // Use ScreenUtil for responsive sizing
            ),
            SizedBox(height: 30.h),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple), // Or your theme color
            ),
            SizedBox(height: 20.h),
            Text(
              "Loading data...",
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}