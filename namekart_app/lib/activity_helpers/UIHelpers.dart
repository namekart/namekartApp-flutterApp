import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../change_notifiers/WebSocketService.dart';
import '../cutsom_widget/SuperAnimatedWidget/SuperAnimatedWidget.dart';
import '../database/HiveHelper.dart';
import 'GlobalVariables.dart';

class CircleTabIndicator extends Decoration {
  final Color color;
  final double radius;

  // Constructor to receive color and radius for the circle
  CircleTabIndicator({required this.color, required this.radius});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    // Return a custom BoxPainter to handle the painting
    return _CircleTabPainter(color, radius);
  }
}

class _CircleTabPainter extends BoxPainter {
  final Color color;
  final double radius;

  // Constructor to receive color and radius for painting
  _CircleTabPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    // Calculate the position for the circle at the bottom center of the tab
    final double xCenter = offset.dx + configuration.size!.width / 2;
    final double yCenter = offset.dy + configuration.size!.height - radius;

    // Draw the circle at the calculated position
    canvas.drawCircle(Offset(xCenter, yCenter), radius, paint);
  }
}

Widget text(
    {required String text,
    required double size,
    required Color color,
    required FontWeight fontWeight}) {
  return Text(text,
      style: GoogleFonts.workSans()
          .copyWith(fontWeight: fontWeight, color: color, fontSize: size));
}

List<dynamic> getTodaysDateTime() {
  DateTime now = DateTime.now();

  String dayOfWeek = DateFormat('EEEE').format(now);
  String formattedDate = DateFormat('dd-MM-yyyy').format(now);

  return [dayOfWeek, formattedDate,now];
}

String getFormattedDate(String dateString) {
  // Parse the input date string
  DateTime inputDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(dateString);

  // Get today's and yesterday's dates
  DateTime today = DateTime.now();
  DateTime yesterday = today.subtract(Duration(days: 1));

  // Check if the input date is today
  if (isSameDay(inputDate, today)) {
    return "Today";
  }

  // Check if the input date is yesterday
  if (isSameDay(inputDate, yesterday)) {
    return "Yesterday";
  }

  // If it's neither, return the formatted date
  return DateFormat("dd/MM/yyyy")
      .format(inputDate); // Returns date in "dd/MM/yyyy" format
}

/// Helper function to compare two dates by day
bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

Future<void> launchInBrowser(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(
    uri,
    mode: LaunchMode.inAppWebView, // Opens inside the app
    webViewConfiguration: const WebViewConfiguration(
      enableJavaScript: true,
    ),
  )) {
    throw Exception('Could not launch $url');
  }
}

Future<void> dynamicDialog(BuildContext context, buttonData,String collectionName,String documentId,int bubbleButtonIndex,String bubbleButtonName) async {
  var buttonOnClickData = buttonData['onclick'];
  print(buttonOnClickData);


  if (buttonOnClickData.keys
      .toString()
      .contains("text")) {
    var buttonOnClickDataList =
    buttonOnClickData['text'];
    var buttonOnClickDataListKeys =
    buttonOnClickDataList.keys
        .toList();

    showDialog(context: context, builder: (BuildContext context) {
      return StatefulBuilder(
          builder: (context,
              setState) {
            return AlertDialog(
                contentPadding:
                const EdgeInsets
                    .all(0),
                backgroundColor:
                Color(
                    0xffF5F5F5),
                content: Container(
                    width: MediaQuery.of(
                        context)
                        .size
                        .width,
                    height: 270.sp,
                    child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          AppBar(
                            title:
                            Text(
                              buttonData[
                              'button_text'],
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            backgroundColor:
                            Color(0xffB71C1C),
                            iconTheme: IconThemeData(
                                size:
                                20,
                                color:
                                Colors.white),
                            titleSpacing:
                            0,
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                          ),
                          SingleChildScrollView(
                            child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: buttonOnClickDataListKeys.length,
                                          itemBuilder: (context, buttonOnClickDataListindex) {
                                            return Padding(
                                              padding: const EdgeInsets.all(5),
                                              child: Text(buttonOnClickDataList[buttonOnClickDataListKeys[buttonOnClickDataListindex]], style: (buttonOnClickDataList[buttonOnClickDataListindex] == "h1") ? GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xffB71C1C)) : GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black54)),
                                            );
                                          }),
                                    ),
                                  ),
                                ]),
                          )
                        ])));
          });
    },
    );
  }
  else if (buttonOnClickData
      .keys
      .toString()
      .contains('url')) {
    var urlList = buttonOnClickData['url'];

    if(urlList.length==1){
      launchInBrowser("https://"+urlList[urlList.keys.toList()[0]]);
    }else {
      showDialog(context: context, builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context,
                setState) {
              return AlertDialog(
                  contentPadding:
                  const EdgeInsets
                      .all(0),
                  backgroundColor:
                  Color(
                      0xffF5F5F5),
                  content: Container(
                      width: MediaQuery
                          .of(
                          context)
                          .size
                          .width,
                      height: 270.sp,
                      child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            AppBar(
                              title:
                              Text(
                                buttonData[
                                'button_text'],
                                style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              backgroundColor:
                              Color(0xffB71C1C),
                              iconTheme: IconThemeData(
                                  size:
                                  20,
                                  color:
                                  Colors.white),
                              titleSpacing:
                              0,
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20))),
                            ),
                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: GridView.builder(
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    // 3 columns
                                    crossAxisSpacing: 3,
                                    // Space between columns
                                    mainAxisSpacing: 1,
                                    // Space between rows
                                    childAspectRatio:
                                    1.5, // Adjusted to better fit content
                                  ),
                                  itemCount: urlList.length,
                                  shrinkWrap: true,
                                  physics:
                                  const NeverScrollableScrollPhysics(),
                                  // Disable scrolling if inside another scrollable widget
                                  itemBuilder: (context, urlButtonIndex) {
                                    // Use a Column or Wrap instead of a nested GridView
                                    return Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Bounceable(
                                        onTap: () {},
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            getIconForButton(urlList.keys.toList()[urlButtonIndex],30),
                                            const SizedBox(height: 10),
                                            Text(
                                              urlList.keys.toList()[urlButtonIndex],
                                              style: GoogleFonts.poppins(
                                                fontSize: 8,
                                                fontWeight:
                                                FontWeight.bold,
                                                color: Colors.black54,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                            )
                          ])));
            });
      });
    }
  }
  else if (buttonOnClickData.toString().contains("sendtoserver")){
    WebSocketService websocketService=new WebSocketService();

    String calledDocumentPath="live~$collectionName~auctions~$documentId";

    Map<String,String> a={
      "sendtoserver":buttonOnClickData['sendtoserver'],
      "calledDocumentPath":calledDocumentPath,
      "calledDocumentPathFields":"uiButtons[$bubbleButtonIndex].$bubbleButtonName.onclick",
      "type":"stats"
    };

    //sending response to server imp
    await websocketService.sendMessageGetResponse(a,"broadcast");

    dynamicDialog(context, HiveHelper.read(calledDocumentPath)['uiButtons'][bubbleButtonIndex][bubbleButtonName],collectionName,documentId,bubbleButtonIndex,bubbleButtonName);




  }
  else if(buttonOnClickData.toString().contains("openinputbox")){
    TextEditingController _inputTextFieldController=new TextEditingController();
    showDialog(
        context: context,
        // Provide the context
        builder:(BuildContext context) {
          return AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              backgroundColor: Color(0xffF5F5F5),
              content: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 200.sp,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBar(
                          title: Text(
                            "Enter Input",
                            style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Color(0xffB71C1C),
                          iconTheme: IconThemeData(
                              size: 20, color: Colors.white),
                          titleSpacing: 0,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20))),
                        ),
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              height: 50.sp,
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  color: Colors.white),
                              child: TextField(
                                controller: _inputTextFieldController,
                                style: GoogleFonts.poppins(
                                  fontWeight:
                                  FontWeight.bold,
                                  color: Colors.black45,
                                  fontSize: 8.sp,
                                  decoration:
                                  TextDecoration.none,
                                ),
                                obscureText: true,
                                decoration: InputDecoration(
                                    labelText: 'Enter Amount',
                                    border:
                                    InputBorder.none,
                                    labelStyle:
                                    GoogleFonts.poppins(
                                      fontWeight:
                                      FontWeight.bold,
                                      color: Colors.black45,
                                      fontSize: 8.sp,
                                      decoration:
                                      TextDecoration
                                          .none,
                                    ),
                                    prefixIcon:
                                    Icon(Icons.keyboard),
                                    prefixIconColor:
                                    Color(0xffB71C1C)),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children:[
                                Bounceable(
                                  onTap: (){},
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xffE7E7E7),
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all( 15),
                                      child: Text("Done",
                                          style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 8)),
                                    ),
                                  ),
                                ),]
                          ),
                        ),

                      ]
                  )
              )
          );
        }
    );
  }
}



Future<void> showConfirmationDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
  required String title,
  required String content,
  required String snackBarMessage
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // Prevents closing by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title,style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 10
        ),),
        content: Text(content,style: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            color: Colors.black,
            fontSize: 10
        ),),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog
            child: Text('Cancel',style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 10),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              onConfirm();

              showTopSnackBar(
                Overlay.of(context),
                displayDuration: Duration(milliseconds: 100),
                animationDuration: Duration(seconds: 1),
                CustomSnackBar.success(
                  message: snackBarMessage,
                ),
              );


// Call the confirmation handler
            },
            child: Text('Delete',style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 10),),
          ),
        ],
      );
    },
  );
}
