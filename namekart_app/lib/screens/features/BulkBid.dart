import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:http/http.dart' as http;
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:namekart_app/cutsom_widget/SuperAnimatedWidget.dart';

class BulkBid extends StatefulWidget {
  @override
  State<BulkBid> createState() => _BulkBidState();
}

class _BulkBidState extends State<BulkBid> with TickerProviderStateMixin {
  String? selectedValue;

  final List<Map<String, dynamic>> items = [
    {'name': 'DropCatch', 'icon': "dropcatch.png"},
    {'name': 'Dynadot', 'icon': "dynadot.png"},
    {'name': 'GoDaddy', 'icon': "godaddy.png"},
    {'name': 'Namecheap', 'icon': "namecheap.png"},
    {'name': 'NameSilo', 'icon': "namesilo.png"},
  ];

  List<Map<String, dynamic>> inputs = [];

  @override
  void initState() {
    super.initState();
    addNewFields();
    Future.delayed(Duration(milliseconds: 600), () {
      Haptics.vibrate(HapticsType.success);
    });
  }

  void addNewFields() {
    setState(() {
      inputs.add({
        'domain': TextEditingController(),
        'bid': TextEditingController(),
        'removing': false,
        'animationController': AnimationController(
          duration: Duration(milliseconds: 300),
          vsync: this,
        )..forward(),
      });
      Future.delayed(Duration(milliseconds: 600), () {
        Haptics.vibrate(HapticsType.success);
      });
    });
  }

  void removeFields(int index) {
    inputs[index]['animationController'].reverse().then((_) {
      setState(() {
        inputs[index]['domain']?.dispose();
        inputs[index]['bid']?.dispose();
        inputs[index]['animationController'].dispose();
        inputs.removeAt(index);
      });
    });
    Haptics.vibrate(HapticsType.error);
  }

  // Function to reset input fields
  void resetInputFields() {
    setState(() {
      inputs.clear();
      addNewFields();
    });
  }

  @override
  void dispose() {
    for (var input in inputs) {
      input['domain']?.dispose();
      input['bid']?.dispose();
      input['animationController']?.dispose();
    }
    super.dispose();
  }

  // HTTP POST function to send schedule bid data
  Future<void> sendScheduleBid() async {
    List<String> auctionData = [];
    for (var input in inputs) {
      String data =
          '''"${selectedValue},${input['domain']?.text},${input['bid']?.text}",''';
      auctionData.add(data);
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/auctions/bulkbid/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(auctionData),
      );

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text('Schedule Bid processed successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  resetInputFields();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Failed to schedule bid');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // HTTP POST function to send instant bid data
  Future<void> sendInstantBid() async {
    List<String> auctionData = [];
    for (var input in inputs) {
      String data =
          "${selectedValue},${input['domain']?.text},${input['bid']?.text}";
      auctionData.add(data);
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/auctions/bulkbid/instant'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(auctionData),
      );

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success',
                style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp)),
            content: Text('Instant Bid processed successfully.',
                style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.sp)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  resetInputFields();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Failed',
                style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp)),
            content: Text('Something Went Wrong Please Try Again.',
                style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.sp)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  resetInputFields();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Failed',
              style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp)),
          content: Text('Something Went Wrong Please Try Again.',
              style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.sp)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetInputFields();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF7F7F7),
      appBar: AppBar(
        backgroundColor: Color(0xffF7F7F7),
        iconTheme: const IconThemeData(color: Color(0xff3F3F41), size: 18),
        title: text(
            text: "Bulk Bid",
            fontWeight: FontWeight.w300,
            size: 12.sp,
            color: Color(0xff3F3F41)),
        titleSpacing: 0,
        toolbarHeight: 50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xffFFFFFF),
                border: Border.all(color: Colors.black12, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: text(
                        text: "Select The Platform",
                        size: 12,
                        color: Color(0xff3F3F41),
                        fontWeight: FontWeight.w400),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xffFFFFFF),
                        border: Border.all(color: Colors.black12, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        dropdownColor: Color(0xFFF3F3F3),
                        value: selectedValue,
                        hint: Padding(
                          padding: EdgeInsets.only(left: 18.0),
                          child: Text(
                            'Select an option',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Color(0xff717171),
                                fontWeight: FontWeight.w300),
                          ),
                        ),
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black54,
                            size: 30,
                          ),
                        ),
                        iconSize: 40,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: items.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['name'],
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/images/home_screen_images/livelogos/${item['icon']}",
                                    width: 20,
                                    height: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    item['name'],
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedValue = value;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Animated input fields with dark theme
                  SingleChildScrollView(
                    child: Column(
                      children: List.generate(inputs.length, (index) {
                        return SizeTransition(
                          sizeFactor: CurvedAnimation(
                            parent: inputs[index]['animationController'],
                            curve: Curves.easeInOut,
                          ),
                          child: SuperAnimatedWidget(
                            effects: [AnimationEffect.slide, AnimationEffect.scale],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Domain field
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: TextField(
                                        controller: inputs[index]['domain'],
                                        decoration: InputDecoration(
                                          labelText: 'Enter Domain Name',
                                          labelStyle: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w300,
                                            color: Color(0xff717171),
                                            fontSize: 9,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.only(left: 10),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.black12, width: 1),
                                          ),
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Bid field
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: TextField(
                                        controller: inputs[index]['bid'],
                                        decoration: InputDecoration(
                                          labelText: 'Bid Price',
                                          labelStyle: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w300,
                                            color: Color(0xff717171),
                                            fontSize: 9,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.only(left: 10),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.black12, width: 1),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Remove button
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: Colors.black26),
                                    onPressed: () => removeFields(index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 10,),
                  GestureDetector(
                    onTap: addNewFields,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.add, color: Color(0xffFF6B6B), size: 15),
                        SizedBox(width: 5),
                        text(
                          text: 'Add Domain',
                          color: Color(0xffFF6B6B),
                          fontWeight: FontWeight.bold,
                          size: 10,
                        ),
                        SizedBox(width: 15),

                      ],
                    ),
                  ),

                  SizedBox(height: 15),
                  // Refined Action Buttons
                ],
              ),
            ),
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    sendScheduleBid(); // Call the API for scheduled bid
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffE63946),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.5),
                  ),
                  child: text(
                    text: 'Schedule Bid',
                    color: Colors.white, size: 10,fontWeight: FontWeight.w300,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    sendInstantBid(); // Call the API for instant bid
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffE63946),
                    padding:
                    EdgeInsets.symmetric(horizontal: 40, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.5),
                  ),
                  child: text(
                    text: 'Instant Bid',
                    color: Colors.white, size: 10,fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
