import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:http/http.dart' as http;
import 'package:namekart_app/cutsom_widget/CustomShimmer.dart';
import 'package:namekart_app/cutsom_widget/SuperAnimatedWidget.dart';
import 'package:shimmer/shimmer.dart';
import '../../activity_helpers/UIHelpers.dart';
import '../../cutsom_widget/AnimatedAvatarIcon.dart';
import '../../cutsom_widget/AutoAnimatedContainerWidget.dart';
import '../../storageClasses/Auctions.dart';
import 'BulkFetchListScreen.dart';

class BulkFetch extends StatefulWidget {
  @override
  State<BulkFetch> createState() => _BulkFetchState();
}

class _BulkFetchState extends State<BulkFetch> {
  List<DomainField> domainFields = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    domainFields.add(DomainField());

    Future.delayed(Duration(milliseconds: 600), () {
      Haptics.vibrate(HapticsType.success);
    });
  }

  void addNewField() {
    setState(() {
      domainFields.add(DomainField());
    });
    _listKey.currentState?.insertItem(domainFields.length - 1);

    Future.delayed(Duration(milliseconds: 600), () {
      Haptics.vibrate(HapticsType.success);
    });
  }

  void removeField(int index) {
    var removedItem = domainFields[index];
    setState(() {
      domainFields.removeAt(index);
    });
    _listKey.currentState?.removeItem(
      index,
          (context, animation) => _buildItem(removedItem, index, animation),
      duration: const Duration(milliseconds: 300),
    );

    Haptics.vibrate(HapticsType.error);

  }

  Future<List<Auctions>> fetchAuctions(List<SearchQuery> queries) async {
    const url = 'http://10.0.2.2:8080/auctions/bulkfetch';
    final body = jsonEncode(queries.map((q) => q.toJson()).toList());

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Auctions.fromJson(item)).toList();
    } else {
      throw Exception(response.body.toString());
    }
  }

  Widget _buildItem(DomainField domainField, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: Colors.white, // Slight transparency for premium look
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform Dropdown
              Padding(
                padding: const EdgeInsets.only(left: 5,bottom: 15,top: 5),
                child: text(
                    text: "Select The Platform",
                    size: 12,
                    color: Color(0xff3F3F41),
                    fontWeight: FontWeight.w400),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xffFFFFFF),
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () {
                    _showCustomDropdown(domainField, index);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/home_screen_images/livelogos/${domainField.selectedPlatform.toLowerCase()}.png',
                          width: 15,
                          height: 15,
                        ),
                        const SizedBox(width: 5),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            domainField.selectedPlatform,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff717171),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Domain Name Input
              TextField(
                onChanged: (text) {
                  domainFields[index].domainName = text;
                },
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
                style: const TextStyle(color: Colors.black, fontSize: 10),
              ),
              const SizedBox(height: 5),
              // Add/Remove Button
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8,right: 8),
                      child: Text(
                        'Add More Domains',
                        style: GoogleFonts.poppins(
                            color: Color(0xffB71C1C),
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      index == domainFields.length - 1 ? Icons.add_circle : Icons.remove_circle,
                      color: index == domainFields.length - 1 ? Color(0xffB71C1C) : Color(0xffB71C1C),
                      size: 20,
                    ),
                    onPressed: () {
                      if (index == domainFields.length - 1) {
                        addNewField();
                      } else {
                        removeField(index);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomDropdown(DomainField domainField, int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Platform',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // List of Platform options
                ...['DropCatch', 'Dynadot', 'GoDaddy', 'Namecheap', 'NameSilo']
                    .map(
                      (platform) => InkWell(
                    onTap: () {
                      setState(() {
                        domainField.selectedPlatform = platform;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/home_screen_images/livelogos/${platform.toLowerCase()}.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            platform,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void submitData() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<SearchQuery> queries = domainFields.map((field) {
        return SearchQuery(
          platform: field.selectedPlatform,
          domain: field.domainName,
        );
      }).toList();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
        ),
      );

      List<Auctions> auctions = await fetchAuctions(queries);

      Navigator.of(context).pop();

      setState(() {
        isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BulkFetchListScreen(auctions: auctions),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Failed to fetch auctions: $e',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: Colors.red[700],
      ));
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
            text: "Bulk Fetch",
            fontWeight: FontWeight.w300,
            size: 12.sp,
            color: Color(0xff3F3F41)),
        titleSpacing: 0,
        toolbarHeight: 50,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 15,right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading Section

            // Animated List of Domain Fields
            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: domainFields.length,
                itemBuilder: (context, index, animation) {
                  return _buildItem(domainFields[index], index, animation);
                },
              ),
            ),
            // Submit Button
            Center(
              child:Shimmer.fromColors(
                baseColor: Colors.white,
                highlightColor: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurpleAccent, Colors.indigoAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Get Data',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DomainField {
  String selectedPlatform;
  String domainName;

  DomainField({this.selectedPlatform = 'GoDaddy', this.domainName = ''});
}

class SearchQuery {
  final String platform;
  final String domain;

  SearchQuery({required this.platform, required this.domain});

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'domain': domain,
    };
  }
}
