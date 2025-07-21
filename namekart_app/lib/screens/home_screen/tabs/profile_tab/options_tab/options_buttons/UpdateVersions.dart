import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
class UpdateVersion extends StatefulWidget{
  @override
  State<UpdateVersion> createState() => _UpdateVersionState();
}

class _UpdateVersionState extends State<UpdateVersion> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: Color(0xffF7F7F7),
        appBar: AppBar(
          backgroundColor: Color(0xffF7F7F7),
          surfaceTintColor: Color(0xffF7F7F7),
          titleSpacing: 0,
          title: text(
              text: "Update Info",
              size: 12.sp,
              color: Color(0xff717171),
              fontWeight: FontWeight.bold),
        ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15,right: 15),
              child: Bounceable(onTap: (){}, child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset("assets/images/home_screen_images/carousel_options/whatnewupdate/appstorelogo.png",width: 30,height: 30,),
                        SizedBox(width: 10,),
                        Image.asset("assets/images/home_screen_images/carousel_options/whatnewupdate/googleplaylogo.png",width: 30,height: 30,),
                        SizedBox(width: 10,),
                        text(text: "Beta Version 1", size: 12  , color: Colors.black, fontWeight: FontWeight.w300)
                      ],
                    ),
        
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Implemented Spring Boot server for robust backend services."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Configured Spring Boot backend to support dynamic creation and management of channels, enabling flexible content organization."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Enhanced Spring Boot backend to handle dynamic payloads and trigger notifications based on payload content, enabling smarter real-time updates."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Configured Spring Boot to handle and respond to multiple simultaneous messages from the app, improving backend responsiveness and concurrency support."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Integrated Hive for local data storage, Firestore for general cloud data, and MongoDB for specialized cloud-specific information to ensure a robust multi-tier data architecture."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Added automatic memory management: resets large stored data sets to prevent out-of-memory issues and ensure smooth app performance."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Added Microsoft account login for secure authentication."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Enabled automatic cloud sync immediately upon login to ensure all user data and bubbles are up to date."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Optimized storage by retaining only the latest 2 days of data, automatically removing older entries to reduce memory usage."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Added WebSocket synchronization with auto-reconnect; displays a snackbar notification if the connection drops and reconnects seamlessly."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Introduced a universal live screen for all channels, featuring separate sections for live content and highlights. Includes an infinite scroll list that loads 10 additional items from the cloud when local data is unavailable. Added a quick-view notification bar with a counter and a down button for instant access to new updates. Integrated a calendar view that displays data by date, with a bottom sheet for date selection and an advanced search option for precise queries."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Configured the live screen to handle dynamic payloads, enabling real-time updates and adaptive content rendering based on incoming data."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Implemented saving of bubble button clicks in both local and cloud storage to minimize server load and ensure faster, more responsive operations."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Added a comprehensive search screen that allows users to search across all app data for a unified, streamlined discovery experience."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Added multiple productivity tools including a bidding list, watch list, bulk bid, and bulk fetch to streamline user workflows and enhance app functionality."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Introduced a channel tab to display live bubble information, added a dedicated search screen for quickly locating specific bubbles, and included a notification indicator for real-time updates."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Added an options tab featuring quick-access tools such as personal groups, quick notes, analytics dashboard, domain insights, hashtags, 'spotted something wrong' feedback, 'have a feature in mind' suggestions, and upgrade information for enhanced user support and interaction."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Added a profile screen to display user details, Firestore data, notification settings, and a logout option for streamlined account management."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/check.png","Added a Firestore screen page to display comprehensive details of all cloud-stored data, providing clear visibility into user-related cloud content."),

                  ],
                ),
              )),
            ),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Bounceable(onTap: (){}, child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset("assets/images/home_screen_images/options_tab/update_version_screen/coding.png",width: 30,height: 30,),
                        SizedBox(width: 10,),
                        text(text: "Currently In Development", size: 12  , color: Colors.black, fontWeight: FontWeight.w300)
                      ],
                    ),

                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/hourglass.png","A starred screen where users can mark (star) bubbles from the live screen and easily view all their starred bubbles in one place."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/hourglass.png","Introduced a personal group feature that lets users create custom groups of bubbles based on criteria such as age ranges and domain filters (e.g., bubbles with '.com' domains aged 5–10), enabling tailored organization and quick access."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/hourglass.png","Quick Notes feature where users can create personal notes and directly add bubbles or app elements, streamlining organization and speeding up common workflows."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/hourglass.png","Analytics screen to display key app statistics and usage insights, helping users easily track and understand important metrics."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/hourglass.png","Hashtag functionality allowing users to tag bubbles on the live screen and view all tagged items in a dedicated hashtags screen for easy organization and discovery."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/hourglass.png","Chat feature, enabling users to communicate directly within the app without needing external platforms like WhatsApp or Telegram, saving time and streamlining interactions."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/hourglass.png","Introduced bubble notes, allowing users to add personalized notes to individual bubbles for easier understanding and context tracking."),
                    checkWidget("assets/images/home_screen_images/options_tab/update_version_screen/hourglass.png","Theme customization, allowing users to choose from multiple themes including dark mode, light mode, and additional color options to personalize their app experience."),

                    SizedBox(height: 20,),
                  ],
                ),
              )),
            ),

          ],
        ),
      )
    );
  }

  Column checkWidget(String img,String title){
    return Column(
      children: [
        SizedBox(height: 20,),
        Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Row(
            children: [
              Image.asset(img,width: 20,height: 20,),
              SizedBox(width: 10,),
              Flexible(child: text(text: title, size: 10  , color: Colors.black, fontWeight: FontWeight.w300))
            ],
          ),
        ),
      ],
    );
  }
}