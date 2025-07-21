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
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Store notification settings states
  Map<String, bool> bubbleSettings = {
    "DropCatch": false,
    "Dynadot": false,
    "Godaddy": false,
    "Namecheap": false,
    "Namesilo": false,
  };

  Map<String, bool> listSettings = {
    "DropCatch": false,
    "Dynadot": false,
    "Godaddy": true,
    "Namecheap": true,
    "Namesilo": false,
  };

  Map<String, bool> serverSettings = {
    "BidActivity": false,
    "BotActivity": false,
    "CloseoutsActivity": false,
    "DailyLiveReports": true,
    "LiveStatesSummary": false,
    "LostTracker": false,
    "TargetReports": false,
    "UserActivity": false,
    "WinTracker": false,
  };

  List<String> databaseDates = [
    "2025-03-04",
    "2025-03-04",
    "2025-03-04",
    "2025-03-04"
  ];
  final valueListenable = ValueNotifier<String?>(null);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        backgroundColor: Color(0xffF7F7F7),
        iconTheme: const IconThemeData(color: Color(0xff3F3F41), size: 15),
        actions: [
          Container(
            width: 2,
            height: 25.sp,
            color: Colors.black12,
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.settings,size: 15.sp,
            ),
          )
        ],
        title: Row(
          children: [
            text(
                text: "Settings",
                fontWeight: FontWeight.w300,
                size: 12.sp,
                color: Color(0xff3F3F41)),
          ],
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            text(text: "Device Notification",
                            fontWeight: FontWeight.w300,
                            size: 12.sp,
                            color: Color(0xffA8A7A7)),
                            SizedBox(height: 15),
                            text(text: "Bubbles",
                                fontWeight: FontWeight.w300,
                                size: 10.sp,
                                color: Color(0xff3F3F41)),
                            SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: bubbleSettings.entries.map((entry) {
                                  return notificationSettingsButton(
                                    entry.key,
                                    "assets/images/home_screen_images/livelogos/${entry
                                        .key.toLowerCase()}.png",
                                    entry.value,
                                    20,
                                    20,
                                        () {
                                      setState(() {
                                        bubbleSettings[entry.key] =
                                        !entry.value;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text("List",
                                style: GoogleFonts.poppins(
                                    color: const Color(0xff464646),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8)),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: listSettings.entries.map((entry) {
                                  return notificationSettingsButton(
                                    entry.key,
                                    "assets/images/home_screen_images/livelogos/${entry
                                        .key.toLowerCase()}.png",
                                    entry.value,
                                    20,
                                    20,
                                        () {
                                      setState(() {
                                        listSettings[entry.key] = !entry.value;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text("Server Notifications",
                                style: GoogleFonts.poppins(
                                    color: Color(0xff464646),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8)),
                            SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4, childAspectRatio: 0.9),
                              itemCount: serverSettings.length,
                              itemBuilder: (context, index) {
                                String key =
                                serverSettings.keys.elementAt(index);
                                return notificationSettingsButton(
                                  key,
                                  "assets/images/notifications_images/${key
                                      .toLowerCase()}.png",
                                  serverSettings[key]!,
                                  30,
                                  30,
                                      () {
                                    setState(() {
                                      serverSettings[key] =
                                      !serverSettings[key]!;
                                    });
                                  },
                                );
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: _saveSettings,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text("Save Settings",
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10)),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20,),

            Text("Cloud Database",
                style: GoogleFonts.poppins(
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                    fontSize: 10)),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                decoration: BoxDecoration(
                  color: Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text("Get full cloud database",
                            style: GoogleFonts.poppins(
                                color: Color(0xffB71C1C),
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius:
                          BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text("Sync Now",
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),


            SizedBox(height: 10,),

            Text("Storage",
                style: GoogleFonts.poppins(
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                    fontSize: 10)),

            Padding(
              padding: const EdgeInsets.only(top: 18, left: 18, right: 18),
              child: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                decoration: BoxDecoration(
                  color: Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text("Total storage used",
                            style: GoogleFonts.poppins(
                                color: Color(0xffB71C1C),
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius
                                .circular(20)),
                            border: Border.all(color: Colors.black12, width: 1)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text("1.3 MB",
                              style: GoogleFonts.poppins(
                                  color: Colors.black45,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Container(
                  width: 325.sp,
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 0),
                          child: Text("Delete data till",
                              style: GoogleFonts.poppins(
                                  color: Color(0xffB71C1C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                        ),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              hint: Text(
                                'Select Item',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme
                                      .of(context)
                                      .hintColor,
                                ),
                              ),
                              items: databaseDates
                                  .map((String item) =>
                                  DropdownItem<String>(
                                    value: item,
                                    height: 40,
                                    child: SingleChildScrollView(
                                      child: Text(
                                        item,
                                        style: GoogleFonts.poppins(
                                            fontSize: 8,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                  ))
                                  .toList(),
                              valueListenable: valueListenable,
                              onChanged: (String? value) {
                                valueListenable.value = value;
                              },
                              buttonStyleData: ButtonStyleData(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                height: 40,
                                width: 120.sp,

                              ),
                            ),),
                        ),

                        Expanded(child: Container()),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xffFF0000),
                            borderRadius:
                            BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text("Delete",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 30, right: 18, bottom: 18),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xff595959),),
                  SizedBox(width: 8,),
                  Text("This will clean upto 1MB of data from device",
                      style: GoogleFonts.poppins(
                          color: Color(0xff595959),
                          fontWeight: FontWeight.bold,
                          fontSize: 8)),
                ],
              ),
            ),

            SizedBox(height: 20,),



          ],
        )
        ,
      )
      ,
    );
  }

  Widget notificationSettingsButton(String title, String img, bool isMute,
      double imageWidth, double imageHeight, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(img, height: imageHeight, width: imageWidth),
                const SizedBox(height: 10),
                TextScroll(
                  mode: TextScrollMode.bouncing,
                  velocity: const Velocity(pixelsPerSecond: Offset(4, 0)),
                  title,
                  style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 6),
                ),
              ],
            ),
          ),
          if (isMute)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7E7E7),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: const Icon(
                    Icons.notifications_off, size: 18, color: Colors.red),
              ),
            )
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    await FCMHelper().unsubscribeFromTopic('godaddy');
    // Create a map with all settings
    Map<String, Map<String, bool>> allSettings = {
      "Bubbles": bubbleSettings,
      "List": listSettings,
      "Server Notifications": serverSettings,
    };

    // Print settings (you can modify this to save to database or send to API)
    print("Current Notification Settings:");
    allSettings.forEach((category, settings) {
      print("\n$category:");
      settings.forEach((title, isMute) {
        print("$title: ${isMute ? 'Muted' : 'Unmuted'}");
      });
    });

    // Show a snackbar to confirm save
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );

    // You can return or process the settings here as needed
    // For example, you could return allSettings to another screen or save to local storage
  }
}

// Helper extension for string formatting
extension StringExtension on String {
  String camelCaseToLowerUnderscore() {
    return splitMapJoin(
      RegExp(r'(?<=[a-z])[A-Z]'),
      onMatch: (m) => '_${m.group(0)}',
      onNonMatch: (n) => n,
    ).toLowerCase();
  }
}