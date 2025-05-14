import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/cutsom_widget/CustomShimmer.dart';
import 'package:namekart_app/database/HiveHelper.dart';
import 'package:shimmer/shimmer.dart';

import '../features/BiddingList.dart';
import '../features/BulkBid.dart';
import '../features/BulkFetch.dart';
import '../features/WatchList.dart';
import '../live_screens/live_details_screen.dart';

class Search extends StatefulWidget {
  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {

  TextEditingController textEditingController = TextEditingController();

  List<String> filteredAvailableData = [];
  List<List<String>> filteredAuctionTools = [];


  List<String> allAvailableData = [];
  List<List<String>> auctionsTools=[
    ["Watch List","watchlist"],
    ["Bidding List","biddinglist"],
    ["Bulk Bid","bulkbid"],
    ["Bulk Fetch","bulkfetch"],
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    textEditingController.addListener(_onTextChanged);

    allAvailableData = HiveHelper.getCategoryPathsOnly();

    filteredAvailableData = List.from(allAvailableData);
    filteredAuctionTools = List.from(auctionsTools);


    // print(HiveHelper.read(allAvailableData[0])[HiveHelper.getKeys(allAvailableData[0])[3]]);
  }

  List<List<String>> searchedItem = [];

  void _onTextChanged() {
    String query = textEditingController.text.trim().toLowerCase();

    setState(() {
      // Filter allAvailableData
      filteredAvailableData = allAvailableData.where((item) {
        return item.toLowerCase().contains(query);
      }).toList();

      // Filter auction tools by name
      filteredAuctionTools = auctionsTools.where((item) {
        return item[0].toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30.sp),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Color(0xFFB71C1C)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15,bottom: 1),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Icon(Icons.arrow_back_rounded,
                                      color: Colors.white,size: 18,)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: textEditingController,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "Search Here",
                                  hintStyle: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.sp),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.asset(
                                "assets/images/home_screen_images/searchwhite.png",
                                width: 15.0,
                                height: 15.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if(filteredAvailableData.isNotEmpty)
                  buildSimpleCategoryUI(filteredAvailableData),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      "Auctions Tools",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: filteredAuctionTools.map<Widget>((item) {
                        return Bounceable(
                          onTap: (){
                            switch(item[1]){
                              case "watchlist":
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => WatchList()));
                                break;
                              case "biddinglist":
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => BiddingList()));
                                break;
                              case "bulkbid":
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => BulkBid()));
                                break;
                              case "bulkfetch":
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => BulkFetch()));
                                break;

                            }
                          },
                          child: Shimmer.fromColors(
                              baseColor: Colors.black,
                              highlightColor: Colors.white,
                              child: _buildActionItem(
                                  item[0], item[1], 20,8)),
                        );

                      }
                    ).toList()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(String label, String iconPath,double iconSize,double fontSize) {
    return Column(
      children: [
        const SizedBox(height: 2),
        getIconForButton(iconPath, iconSize),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.workSans(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: fontSize.sp),
        ),
      ],
    );
  }

  Widget buildSimpleCategoryUI(List<String> input) {
    // Parse input and categorize
    Map<String, Map<String, Set<String>>> categoryMap = {};

    // Organize the input data
    for (var item in input) {
      List<String> parts = item.split('~');
      String category = parts[0];
      String subCategory = parts[1];
      String subItem = parts[2];

      categoryMap.putIfAbsent(category, () => {});
      categoryMap[category]!.putIfAbsent(subCategory, () => {});
      categoryMap[category]![subCategory]!.add(subItem);
    }

    // Build the UI
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: categoryMap.length,
      itemBuilder: (context, index) {
        final category = categoryMap.keys.elementAt(index);
        final subCategories = categoryMap[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title for the category
            if (index > 0)
              SizedBox(
                height: 30,
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 20),
              child: Text(
                category.capitalize(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            // Iterate through sub-categories
            ...subCategories.entries.map<Widget>((entry) {
              String subCategoryName = entry.key;
              List<String> items = entry.value.toList();

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,child:Row(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Title for the sub-category
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                  width: 100,
                                  child: _buildActionItem(
                                      subCategoryName.capitalize(),
                                      subCategoryName,
                                      20,8)),
                            ),
                            Icon(
                              Icons.arrow_right_alt_sharp,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            // Buttons for each item in this sub-category

                            Row(children: items.map<Widget>((item) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),

                                  child: ElevatedButton(

                                    onPressed: () {
                                      Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) {
                                        return
                                          LiveDetailsScreen(
                                            mainCollection:category,
                                            subCollection:subCategoryName,
                                            subSubCollection:item,
                                            showHighlightsButton: true,
                                            img: (subCategoryName=="godaddy"||subCategoryName=="dropcatch"||subCategoryName=="dynadot"||subCategoryName=="namecheap"||subCategoryName=="namesilo")?
                                            "assets/images/home_screen_images/livelogos/$subCategoryName.png":"assets/images/home_screen_images/appbar_images/notification.png",
                                          );}));
                                    },
                                    child: Text(item,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 6
                                    ),),
                                    style: ButtonStyle(
                                      padding: WidgetStatePropertyAll(EdgeInsets.all(0)),
                                        backgroundColor:
                                            WidgetStatePropertyAll(Colors.green),
                                        textStyle: WidgetStateProperty.all(
                                            GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        foregroundColor:
                                            WidgetStatePropertyAll(Colors.white)),
                                  ),
                                ),
                              );
                            }).toList()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
