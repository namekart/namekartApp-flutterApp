import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../database/HiveHelper.dart';

class PaginatedScrollList extends StatefulWidget {
  final String hivePath;
  const PaginatedScrollList({super.key, required this.hivePath});

  @override
  State<PaginatedScrollList> createState() => _PaginatedScrollListState();
}

class _PaginatedScrollListState extends State<PaginatedScrollList> {
  List<Map<dynamic, dynamic>> items = [];
  final ScrollController _scrollController = ScrollController();

  String? _oldestDatetimeId;
  String? _newestDatetimeId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialItems();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.forward &&
          _scrollController.position.pixels < 100 &&
          !_isLoading) {
        _loadPreviousItems();
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.reverse &&
          _scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading) {
        _loadNextItems();
      }
    });
  }

  Future<void> _loadInitialItems() async {
    _isLoading = true;
    final allData = HiveHelper.read(widget.hivePath);
    if (allData is! Map) return;

    final sortedItems = allData.values
        .whereType<Map>()
        .toList()
      ..sort((a, b) =>
          DateTime.parse(b['datetime_id']).compareTo(DateTime.parse(a['datetime_id'])));

    final initial = sortedItems.take(10).toList();
    if (initial.isNotEmpty) {
      _oldestDatetimeId = initial.last['datetime_id'];
      _newestDatetimeId = initial.first['datetime_id'];
    }

    setState(() {
      items = initial;
      _isLoading = false;
    });
  }

  Future<void> _loadPreviousItems() async {
    _isLoading = true;
    final allData = HiveHelper.read(widget.hivePath);
    if (allData is! Map) return;

    final sortedItems = allData.values
        .whereType<Map>()
        .where((item) =>
        DateTime.parse(item['datetime_id']).isBefore(DateTime.parse(_oldestDatetimeId!)))
        .toList()
      ..sort((a, b) =>
          DateTime.parse(b['datetime_id']).compareTo(DateTime.parse(a['datetime_id'])));

    final older = sortedItems.take(10).toList();
    if (older.isNotEmpty) {
      _oldestDatetimeId = older.last['datetime_id'];
      setState(() {
        items.insertAll(0, older);
        items = items.take(15).toList(); // keep max 15
      });
    }

    _isLoading = false;
  }

  Future<void> _loadNextItems() async {
    _isLoading = true;
    final allData = HiveHelper.read(widget.hivePath);
    if (allData is! Map) return;

    final sortedItems = allData.values
        .whereType<Map>()
        .where((item) =>
        DateTime.parse(item['datetime_id']).isAfter(DateTime.parse(_newestDatetimeId!)))
        .toList()
      ..sort((a, b) =>
          DateTime.parse(b['datetime_id']).compareTo(DateTime.parse(a['datetime_id'])));

    final newer = sortedItems.take(10).toList();
    if (newer.isNotEmpty) {
      _newestDatetimeId = newer.first['datetime_id'];
      setState(() {
        items.addAll(newer);
        if (items.length > 15) {
          items = items.sublist(items.length - 15);
        }
      });
    }

    _isLoading = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return ListTile(
          title: Text(item['title'] ?? 'No Title'),
          subtitle: Text(item['datetime_id']),
        );
      },
    );
  }
}
