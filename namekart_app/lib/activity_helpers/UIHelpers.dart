import 'dart:convert';
import 'dart:core';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:intl/intl.dart';
import 'package:namekart_app/screens/live_screens/live_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../change_notifiers/WebSocketService.dart';
import '../custom_widget/SuperAnimatedWidget.dart';
import '../main.dart';
import 'DbSqlHelper.dart';
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
      style: GoogleFonts.poppins()
          .copyWith(fontWeight: fontWeight, color: color, fontSize: size));
}

List<dynamic> getTodaysDateTime() {
  DateTime now = DateTime.now();

  String dayOfWeek = DateFormat('EEEE').format(now);
  String formattedDate = DateFormat('dd-MM-yyyy').format(now);

  return [dayOfWeek, formattedDate, now];
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

void haptic() async {
  await Haptics.vibrate(HapticsType.success);
}

Future<void> dynamicDialog(
    BuildContext context,
    buttonData,
    String hivedatabasepath,
    String documentId,
    int bubbleButtonIndex,
    String bubbleButtonName,
    String buttonType,
    String buttonDomainName,
    VoidCallback onDialogComplete) async {
  final showDialogNotifier = Provider.of<
      ShowDialogNotifier>(context, listen: false);

  var buttonOnClickData = buttonData['onclick'];

  if (buttonOnClickData.values.toString().contains("\\\"url\\\"") ||
      buttonOnClickData.keys.toString().contains("url")) {
    if (buttonOnClickData.keys.toString().contains("url")) {
      launchInBrowser(buttonOnClickData.values.toList()[0].values.toList()[0]);
    } else {
      final outer = buttonOnClickData;
      final messageString = jsonDecode(outer['text']['h1'])['message'];

      // Step 2: Decode the inner escaped JSON
      final inner = json.decode(messageString);

      // Step 3: Extract the "url" map
      final urlMap = inner['onclick']['url'] as Map<String, dynamic>;

      // Step 4: Convert to list
      final urlList = urlMap;

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                  contentPadding: const EdgeInsets.all(0),
                  backgroundColor: Color(0xffF5F5F5),
                  content: Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white
                      ),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppBar(
                              title: text(
                                  text: buttonData['button_text'],
                                  size: 10,
                                  color: Color(0xff717171),
                                  fontWeight: FontWeight.w400
                              ),
                              backgroundColor: Colors.white,
                              iconTheme:
                              IconThemeData(size: 20, color: Color(0xff717171)),
                              titleSpacing: 0,
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20))),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, right: 20, bottom: 20),
                              child: Wrap(
                                spacing: 20, // horizontal space between items
                                runSpacing: 8, // vertical space between rows
                                children: List.generate(
                                    urlList.keys.length, (urlButtonIndex) {
                                  final key = urlList.keys
                                      .toList()[urlButtonIndex];
                                  return Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Bounceable(
                                      onTap: () {
                                        final url = urlList[key];
                                        launchInBrowser(url);
                                      },
                                      child: SizedBox(
                                        width: 35,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment
                                              .center,
                                          children: [
                                            ColorFiltered(
                                                colorFilter: ColorFilter.mode(
                                                    Color(
                                                        0xff717171),
                                                    BlendMode
                                                        .srcIn),
                                                child: getIconForButton(
                                                    key, 17)),
                                            const SizedBox(height: 10),
                                            text(
                                              text: key,
                                              size: 8,
                                              color: Color(0xff717171),
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            )
                          ])));
            });
          });

      onDialogComplete();
    }
  } else if (buttonOnClickData.keys.toString().contains("text")) {
    var buttonOnClickDataList = buttonOnClickData['text'];
    var buttonOnClickDataListKeys = buttonOnClickDataList.keys.toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              backgroundColor: Colors.white,
              content: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white
                ), child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBar(
                      toolbarHeight: 50,
                      title: text(
                          text: buttonData['button_text'],
                          size: 8,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                      iconTheme:
                      IconThemeData(size: 15, color: Colors.black),
                      titleSpacing: 0,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20))),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, bottom: 40),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: SizedBox(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount:
                                    buttonOnClickDataListKeys.length,
                                    itemBuilder: (context,
                                        buttonOnClickDataListindex) {
                                      var message = jsonDecode(
                                          buttonOnClickDataList[
                                          buttonOnClickDataListKeys[
                                          buttonOnClickDataListindex]])[
                                      'message'];
                                      return text(
                                          text: message,
                                          size: 8,
                                          fontWeight: FontWeight.w300,
                                          color: Color(0xff717171));
                                    }),
                              ),
                            ),
                          ]),
                    )
                  ]),
              ));
        });
      },
    );

    onDialogComplete();
  } else
  if (buttonOnClickData.toString().contains("send-to-server-get-dialog") ||
      buttonOnClickData.toString().contains("send-to-server-get-snackbar") ||
      buttonOnClickData.toString().contains("send-to-server-get-new-bubble")) {
    WebSocketService websocketService = new WebSocketService();

    print(buttonOnClickData);

    String calledDocumentPath = "$hivedatabasepath~$documentId";
    Map<String, String> a={};
    print(buttonOnClickData.toString().contains("send-to-server-get-dialog")||buttonOnClickData.toString().contains("send-to-server-get-snackbar")&&!GlobalProviders.loadedDynamicDialogAgain);
    if (buttonOnClickData.toString().contains("send-to-server-get-dialog")||buttonOnClickData.toString().contains("send-to-server-get-snackbar")&&!GlobalProviders.loadedDynamicDialogAgain) {
      try {
        a = {
          "send-to-server-get-dialog": buttonOnClickData['send-to-server-get-dialog'],
          "calledDocumentPath": calledDocumentPath,
          "calledDocumentPathFields": "uiButtons[$bubbleButtonIndex].$bubbleButtonName.onclick",
          "type": buttonType.toLowerCase(),
          "domain": buttonDomainName,
          "chatid": calledDocumentPath.split("~")[1],
          "messageid": calledDocumentPath.split("~")[2],
          "userID": GlobalProviders.loginToken.username!,
        };
      }catch (e){
        a = {
          "send-to-server-get-snackbar": buttonOnClickData['send-to-server-get-snackbar'],
          "calledDocumentPath": calledDocumentPath,
          "calledDocumentPathFields": "uiButtons[$bubbleButtonIndex].$bubbleButtonName.onclick",
          "type": buttonType.toLowerCase(),
          "domain": buttonDomainName,
          "chatid": calledDocumentPath.split("~")[1],
          "messageid": calledDocumentPath.split("~")[2],
          "userID": GlobalProviders.loginToken.username!,
        };
      }
    } else if(!GlobalProviders.loadedDynamicDialogAgain){
      a = {
        "send-to-server-get-new-bubble": buttonOnClickData['send-to-server-get-new-bubble'],
        "calledDocumentPath": calledDocumentPath,
        "calledDocumentPathFields": "uiButtons[$bubbleButtonIndex].$bubbleButtonName.onclick",
        "type": buttonType.toLowerCase(),
        "domain": buttonDomainName,
        "chatid": calledDocumentPath.split("~")[1],
        "messageid": calledDocumentPath.split("~")[2],
        "userID": GlobalProviders.loginToken.username!,
      };
    }

    GlobalProviders.loadedDynamicDialogAgain = true;

    if(a.isNotEmpty) {
      //sending response to server imp
      websocketService.sendMessage(a);


      late VoidCallback listener;


      listener = () async {
        print("Notifier triggered");

        Future.delayed(Duration(milliseconds: 100), () {});
        var buttondata=await DbSqlHelper.getById(hivedatabasepath,documentId);

        print(buttondata!['uiButtons'][bubbleButtonIndex][bubbleButtonName]);
          dynamicDialog(
              context,
              buttondata!['uiButtons'][bubbleButtonIndex][bubbleButtonName],
              hivedatabasepath,
              documentId,
              bubbleButtonIndex,
              bubbleButtonName,
              buttonType,
              buttonDomainName,
              onDialogComplete
          );
          showDialogNotifier.removeListener(listener);

      };

      if (!bubbleButtonName.toString().toLowerCase().contains("bid")) {
        showDialogNotifier.addListener(listener);
      }
    }

  } else if (buttonOnClickData.toString().contains("openinputbox")) {
    TextEditingController _inputTextFieldController =
        new TextEditingController();
    showDialog(
        context: context,
        // Provide the context
        builder: (BuildContext context) {
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
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Color(0xffB71C1C),
                          iconTheme:
                              IconThemeData(size: 20, color: Colors.white),
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
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white),
                              child: TextField(
                                controller: _inputTextFieldController,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black45,
                                  fontSize: 10.sp,
                                  decoration: TextDecoration.none,
                                ),
                                obscureText: true,
                                decoration: InputDecoration(
                                    labelText: 'Enter Amount',
                                    border: InputBorder.none,
                                    labelStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black45,
                                      fontSize: 10.sp,
                                      decoration: TextDecoration.none,
                                    ),
                                    prefixIcon: Icon(Icons.keyboard),
                                    prefixIconColor: Color(0xffB71C1C)),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Bounceable(
                                  onTap: () {},
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xffE7E7E7),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Text("Done",
                                          style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10)),
                                    ),
                                  ),
                                ),
                              ]),
                        ),
                      ])));
        });

    onDialogComplete();

  }
  else if (buttonOnClickData.toString().contains("showSnackbar")) {
    showTopSnackBar(
      Overlay.of(context),
      displayDuration: Duration(milliseconds: 100),
      animationDuration: Duration(seconds: 1),
      CustomSnackBar.success(
        message:
            "\"$buttonDomainName $documentId\" ${buttonOnClickData['showSnackbar']['message']}",
      ),
    );
  }
}

Future<void> showConfirmationDialog(
    {required BuildContext context,
    required VoidCallback onConfirm,
    required String title,
    required String content,
    required String snackBarMessage}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // Prevents closing by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10),
        ),
        content: Text(
          content,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.normal, color: Colors.black, fontSize: 10),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 10),
            ),
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
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 10),
            ),
          ),
        ],
      );
    },
  );
}

void showTopSnackbar(String message, bool isSuccess) {
  return showTopSnackBar(
    navigatorKey.currentState!.overlay!,
    displayDuration: Duration(seconds: 1),
    animationDuration: Duration(seconds: 1),
    isSuccess
        ? CustomSnackBar.success(message: message)
        : CustomSnackBar.error(message: message),
  );
}

void showCustomDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            backgroundColor: Colors.white,
            content: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBar(
                    toolbarHeight: 50,
                    title: text(
                        text: title,
                        size: 8,
                        color: Colors.black,
                        fontWeight: FontWeight.w400),
                    iconTheme:
                    IconThemeData(size: 15, color: Colors.black),
                    titleSpacing: 0,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20))),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 40,
                      top: 20,
                    ),
                    child: text(text:message,
                        size: 8,
                        fontWeight: FontWeight.w300,
                        color: Color(0xff717171),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


Widget ScaleBigScreenTransition( {required Widget child,required Widget targetScreen}){
  return OpenContainer(
    transitionDuration: const Duration(milliseconds:500),
    transitionType: ContainerTransitionType.fadeThrough,
    closedElevation: 0.0,
    closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // Adjust if your icon has a specific shape
    closedBuilder: (BuildContext context, VoidCallback openContainer) {
      return child;
    },
    openBuilder: (BuildContext context, VoidCallback closeContainer) {
      return targetScreen; // The screen that opens
    },
  );
}


