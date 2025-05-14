import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

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
            title: Text('Success',style: GoogleFonts.poppins(color: Colors.black54,fontWeight: FontWeight.bold,fontSize: 14.sp)),
            content: Text('Instant Bid processed successfully.',style: GoogleFonts.poppins(color: Colors.black54,fontWeight: FontWeight.bold,fontSize: 10.sp)),
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
            title: Text('Failed',style: GoogleFonts.poppins(color: Colors.black54,fontWeight: FontWeight.bold,fontSize: 14.sp)),
            content: Text('Something Went Wrong Please Try Again.',style: GoogleFonts.poppins(color: Colors.black54,fontWeight: FontWeight.bold,fontSize: 10.sp)),
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
          title: Text('Failed',style: GoogleFonts.poppins(color: Colors.black54,fontWeight: FontWeight.bold,fontSize: 14.sp)),
          content: Text('Something Went Wrong Please Try Again.',style: GoogleFonts.poppins(color: Colors.black54,fontWeight: FontWeight.bold,fontSize: 10.sp)),
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
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
        actions: [
          Container(
            width: 2,
            height: 25.sp,
            color: Colors.black12,
          ),
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: Image.asset(
              "assets/images/home_screen_images/features/bulkbid.png",
              width: 20.sp,
              height: 20.sp,
            ),
          )
        ],
        actionsIconTheme: IconThemeData(color: Colors.white, size: 20),
        title: Text("Bulk Bid",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Colors.white)),
        titleSpacing: 0,
        toolbarHeight: 50,
        flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF03A7FF), Color(0xFFAE002C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Dropdown
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Color(0xFFF3F3F3),
              ),
              child: DropdownButton<String>(
                dropdownColor: Color(0xFFF3F3F3),
                value: selectedValue,
                hint: Padding(
                  padding: EdgeInsets.only(left: 18.0),
                  child: Text(
                    'Select an option',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                        color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                ),
                icon: Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: Icon(Icons.arrow_drop_down, color: Colors.black54,size: 30,),
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
            SizedBox(height: 20),
            // Animated input fields with dark theme
            Expanded(
              child: ListView.builder(
                clipBehavior: Clip.none,
                itemCount: inputs.length,
                itemBuilder: (context, index) {
                  return SizeTransition(
                    sizeFactor: CurvedAnimation(
                      parent: inputs[index]['animationController'],
                      curve: Curves.easeInOut,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 20,),
                        GestureDetector(
                          onTap:(){
                            if (index == inputs.length - 1) {
                              addNewFields();
                            } else {
                              removeFields(index);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(25),topRight: Radius.circular(25),bottomLeft: Radius.circular(0),bottomRight:Radius.circular(0)),
                              color: Color(0xFFF3F3F3),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text(
                                        'Add More Domains',
                                        style: GoogleFonts.poppins(
                                            color: Color(0xffB71C1C),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 15.0),
                                    child: Icon(
                                      index == inputs.length - 1
                                          ? Icons.add_circle
                                          : Icons.delete,
                                      color: Colors.black54,
                                      size: 20,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),


                        Container(
                          height: 160.sp,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(0),topRight: Radius.circular(0),bottomLeft: Radius.circular(25),bottomRight:Radius.circular(25)),
                            color: Color(0xFFF3F3F3),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5,bottom: 5,left: 10,right: 10),
                            child: Column(
                              children: [
                                // Domain TextField with sleek dark design
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  child: Container(
                                    height: 40.sp,
                                    child: TextField(
                                      controller: inputs[index]['domain'],
                                      decoration: InputDecoration(
                                        labelText: 'Domain Name',
                                        labelStyle: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 10),
                                        filled: true,
                                        fillColor: Color(0xffB71C1C),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                                // Bid TextField with soft design
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Opacity(
                                        opacity: 0.5,
                                        child: Image.asset(
                                          "assets/images/auctionsimages/bulkbid.png",
                                          width: 70,
                                          height: 70,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: Container(
                                          height: 40.sp,
                                          child: TextField(
                                            controller: inputs[index]['bid'],
                                            decoration: InputDecoration(
                                              labelText: 'Bid Price',
                                              labelStyle: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black54,
                                              fontSize: 12),
                                              filled: true,
                                              fillColor: Color(0xffe2e2e2),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black54),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            // Refined Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    sendScheduleBid(); // Call the API for scheduled bid
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[850],
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.5),
                  ),
                  child: Text(
                    'Schedule Bid',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    sendInstantBid(); // Call the API for instant bid
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.5),
                  ),
                  child: Text(
                    'Instant Bid',
                    style: TextStyle(color: Colors.white, fontSize: 12),
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
