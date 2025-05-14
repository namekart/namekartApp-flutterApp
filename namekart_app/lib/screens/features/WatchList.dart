import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';

import '../../change_notifiers/WebSocketService.dart';

class WatchList extends StatefulWidget {
  @override
  State<WatchList> createState() => _WatchListState();
}


class _WatchListState extends State<WatchList> {
  StreamSubscription? _subscriptionForButtons;

  var watchList=[];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _subscriptionForButtons?.cancel();
    final webSocketService =
    Provider.of<WebSocketService>(
        context,
        listen: false);

    webSocketService.sendMessage({
      "query": "getWatchList"
    });


    _subscriptionForButtons = WebSocketService.onUserMessage.listen((response) async {
      if(mounted){
      setState(() {
      final searchLinks = jsonDecode(response);
        watchList = searchLinks["data"];
      });
    }
    });
  }

    @override
    Widget build(BuildContext context) {
      // TODO: implement build
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
                "assets/images/home_screen_images/features/watchlist.png",
                width: 20.sp,
                height: 20.sp,
              ),
            )
          ],
          actionsIconTheme: IconThemeData(color: Colors.white, size: 20),
          title: Row(
            children: [
              Text("WatchList",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: Colors.white)),
            ],
          ),
          titleSpacing: 0,
          toolbarHeight: 50,
          flexibleSpace: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF03A7FF), Color(0xFFAE002C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight))),
        ),
        body: ListView.builder(
            itemCount: watchList.length,
            itemBuilder: (context,index){
              return Padding(
                padding: const EdgeInsets.all(15),
                child: Container(
                  decoration: BoxDecoration(
                      color: Color(0xffF5F5F5),
                      borderRadius: BorderRadius.all(Radius.circular(20)),boxShadow: [BoxShadow(color: Colors.black12,blurRadius: 10)]),
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(watchList[index]["domain"],style: GoogleFonts.poppins(fontSize: 14,fontWeight: FontWeight.bold,color: Color(0xffB71C1C)),),
                          Text(watchList[index]["timeleft"],style: GoogleFonts.poppins(fontSize: 10,fontWeight: FontWeight.bold,color: Color(0xff50000000)),)
                        ],
                      ),
                      SizedBox(height: 10,),
                      TextScroll(
                        selectable: true,
                        mode: TextScrollMode.bouncing,
                        velocity: Velocity(pixelsPerSecond: Offset(10, 0)),
                        "Age : ${watchList[index]["age"]} | "+
                          "Est : ${watchList[index]["est"]} | "+
                          "Gdv : ${watchList[index]["gdv"]} | "+
                          "Extns : ${watchList[index]["extns"]} | "+
                          "Lsv : ${watchList[index]["lsv"]} | "+
                          "Cpc : ${watchList[index]["cpc"]} | "+
                          "Eub : ${watchList[index]["eub"]} | "+
                          "Aby : ${watchList[index]["aby"]}",style: GoogleFonts.poppins(fontSize: 10,fontWeight: FontWeight.bold,color: Color(0xff50000000)),),
                      SizedBox(height: 10,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Bidders : ${watchList[index]["age"]}",style: GoogleFonts.poppins(fontSize: 10,fontWeight: FontWeight.bold,color: Color(0xff50000000)),),

                            Container(width: 100,height: 40,padding: EdgeInsets.all(5),decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20)),color: Colors.white),child:
                            Row(
                              children: [
                                SizedBox(width: 10,),
                                Expanded(child: TextField(textAlign: TextAlign.center,)),
                                SizedBox(width: 10,),
                                Text("Bid",style: GoogleFonts.poppins(fontSize: 10,fontWeight: FontWeight.bold,color: Color(0xff50000000)),),
                                SizedBox(width: 10,),
                              ],

                            ),)
                          ]
                      ),

                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset("assets/images/home_screen_images/livelogos/godaddy.png",width: 30,height: 30,),
                          Text(watchList[index]["endtime"],style: GoogleFonts.poppins(fontSize: 10,fontWeight: FontWeight.bold,color: Color(0xff50000000)),)

                        ],
                      )
                    ],
                  ),
                ),
              );
            })
      );
    }
  }

