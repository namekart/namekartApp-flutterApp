import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'dart:math';
import 'package:intl/intl.dart'; // Import for date formatting

import 'package:namekart_app/activity_helpers/UIHelpers.dart'; // Adjust path as needed

// A list of distinct colors for the chips
const List<Color> _chipColors = [
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
  Colors.indigo,
  Colors.brown,
  Colors.cyan,
  Colors.deepOrange,
];

// This function returns the StatefulWidget that handles the hashtag and notes input
Widget createHashtagAndNotesInputWidget({
  List<String> initialHashtags = const [],
  List<Map<String, String>> initialNotes = const [],
  String? notesAuthorName, // Optional author name for the section
  required ValueChanged<List<String>> onHashtagsChanged,
  required ValueChanged<List<Map<String, String>>> onNotesChanged,
}) {
  return _HashtagAndNotesInputWidget(
    initialHashtags: initialHashtags,
    initialNotes: initialNotes,
    notesAuthorName: notesAuthorName, // Pass the new parameter
    onHashtagsChanged: onHashtagsChanged,
    onNotesChanged: onNotesChanged,
  );
}

class _HashtagAndNotesInputWidget extends StatefulWidget {
  final List<String> initialHashtags;
  final List<Map<String, String>> initialNotes;
  final String? notesAuthorName; // Field for author name
  final ValueChanged<List<String>> onHashtagsChanged;
  final ValueChanged<List<Map<String, String>>> onNotesChanged;

  const _HashtagAndNotesInputWidget({
    super.key,
    required this.initialHashtags,
    required this.initialNotes,
    this.notesAuthorName, // Make it optional in constructor
    required this.onHashtagsChanged,
    required this.onNotesChanged,
  });

  @override
  State<_HashtagAndNotesInputWidget> createState() => _HashtagAndNotesInputWidgetState();
}

class _HashtagAndNotesInputWidgetState extends State<_HashtagAndNotesInputWidget> {
  late List<String> _hashtags;
  late List<Map<String, String>> _notes;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hashtags = List.from(widget.initialHashtags);
    _notes = List.from(widget.initialNotes);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHashtagsChanged(_hashtags);
      widget.onNotesChanged(_notes);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Color _getColorForHashtag(String tag) {
    if (tag.isEmpty) return _chipColors[0];
    final int hash = tag.hashCode;
    return _chipColors[hash.abs() % _chipColors.length];
  }

  Future<void> _showAddHashtagDialog() async {
    _textController.clear();

    final String? newTag = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: text(text: 'Enter Hashtag', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w400),
          content: TextField(
            controller: _textController,
            autofocus: true,
            style: const TextStyle(color: Color(0xff717171), fontSize: 10, fontWeight: FontWeight.w300),
            decoration: InputDecoration(
              hintText: 'e.g., #important',
              prefixIcon: const Icon(Icons.tag, color: Color(0xff717171), size: 12),
            ),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              child: text(text: 'Cancel', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w400),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: text(text: 'Add', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w400),
              onPressed: () {
                Navigator.of(dialogContext).pop(_textController.text);
              },
            ),
          ],
        );
      },
    );

    if (newTag != null && newTag.trim().isNotEmpty) {
      String cleanTag = newTag.trim();
      if (!cleanTag.startsWith('#')) {
        cleanTag = '#$cleanTag';
      }
      if (!_hashtags.contains(cleanTag)) {
        setState(() {
          _hashtags.add(cleanTag);
        });
        widget.onHashtagsChanged(_hashtags);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hashtag "$cleanTag" already exists!')),
        );
      }
    }
  }

  Future<void> _showAddEditNoteDialog({Map<String, String>? initialNoteMap, int? noteIndex}) async {
    _textController.text = initialNoteMap?['content'] ?? '';

    final String? newNoteContent = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: text(text: noteIndex == null ? 'Add New Note' : 'Edit Note', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w400),
          content: TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 5,
            minLines: 1,
            style: const TextStyle(color: Color(0xff717171), fontSize: 10, fontWeight: FontWeight.w300),
            decoration: InputDecoration(
              hintText: 'Type your note here...',
              prefixIcon: const Icon(Icons.note, color: Color(0xff717171), size: 12),
            ),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              child: text(text: 'Cancel', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w400),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: text(text: noteIndex == null ? 'Add' : 'Save', color: const Color(0xff717171), size: 10, fontWeight: FontWeight.w400),
              onPressed: () {
                Navigator.of(dialogContext).pop(_textController.text);
              },
            ),
          ],
        );
      },
    );

    if (newNoteContent != null && newNoteContent.trim().isNotEmpty) {
      setState(() {
        final String formattedTimestamp = DateFormat('MMM d, yyyy HH:mm').format(DateTime.now());
        // No longer assigning author to noteMap
        // final String author = widget.notesAuthorName ?? 'User';

        final Map<String, String> updatedNoteMap = {
          'content': newNoteContent.trim(),
          'timestamp': formattedTimestamp,
        };

        if (noteIndex == null) {
          _notes.add(updatedNoteMap);
        } else {
          // Preserve existing timestamp if you wish, or update to now.
          _notes[noteIndex] = updatedNoteMap;
        }
      });
      widget.onNotesChanged(_notes);
    } else if (newNoteContent != null && newNoteContent.trim().isEmpty && noteIndex != null) {
      setState(() {
        _notes.removeAt(noteIndex);
      });
      widget.onNotesChanged(_notes);
    }
  }

  Widget _buildHashtagChip(String tag) {
    final Color chipColor = _getColorForHashtag(tag);
    return Bounceable(
      onTap: () {
        setState(() {
          _hashtags.remove(tag);
        });
        widget.onHashtagsChanged(_hashtags);
      },
      child: Container(
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipColor, width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              text(text: tag, size: 8, color: const Color(0xff717171), fontWeight: FontWeight.w300),
              const SizedBox(width: 5),
              Icon(Icons.close, size: 12, color: chipColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, String> noteMap, int index) {
    final String noteContent = noteMap['content'] ?? '';
    final String timestamp = noteMap['timestamp'] ?? '';
    final String displayAuthor = widget.notesAuthorName ?? 'User'; // Use author from widget

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: text(
                    text: noteContent,
                    size: 9,
                    color: const Color(0xff717171),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Bounceable(
                      onTap: () => _showAddEditNoteDialog(initialNoteMap: noteMap, noteIndex: index),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(Icons.edit, size: 16, color: Color(0xff717171)),
                      ),
                    ),
                    Bounceable(
                      onTap: () {
                        setState(() {
                          _notes.removeAt(index);
                        });
                        widget.onNotesChanged(_notes);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(Icons.close, size: 16, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Only show author/timestamp if at least one is present
            if (displayAuthor.isNotEmpty || timestamp.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: text(
                    // Format: "By [Author Name], [Timestamp]"
                    // or just "By [Author Name]" if no timestamp, etc.
                    text: (displayAuthor.isNotEmpty ? 'By $displayAuthor' : '') +
                        (timestamp.isNotEmpty ? (displayAuthor.isNotEmpty ? ', ' : '') + timestamp : ''),
                    size: 7,
                    color: const Color(0xff717171).withOpacity(0.7),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Helper to build a generic "Add" button for hashtags or notes ---
  Widget _buildAddButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return Bounceable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade400, width: 1.0),
          color: Colors.grey.shade100,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Color(0xff717171)),
              SizedBox(width: 5),
              text(text: label, size: 8, color: Color(0xff717171), fontWeight: FontWeight.w300),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmptyState = _hashtags.isEmpty && _notes.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEmptyState)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.start,
              children: [
                _buildAddButton(
                  label: 'Enter Hashtag',
                  icon: Icons.add,
                  onTap: _showAddHashtagDialog,
                ),
                _buildAddButton(
                  label: 'Add Note',
                  icon: Icons.add,
                  onTap: _showAddEditNoteDialog,
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Hashtags Section ---
                if (_hashtags.isNotEmpty)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ..._hashtags.map((tag) => _buildHashtagChip(tag)).toList(),
                      _buildAddButton(
                        label: 'Enter Hashtag',
                        icon: Icons.add,
                        onTap: _showAddHashtagDialog,
                      ),
                    ],
                  )
                else
                  _buildAddButton(
                    label: 'Enter Hashtag',
                    icon: Icons.add,
                    onTap: _showAddHashtagDialog,
                  ),

                const SizedBox(height: 16),

                // --- Notes Section ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Display 'Notes:' title only
                    text(text: 'Notes:', size: 10, color: const Color(0xff717171), fontWeight: FontWeight.w500),
                    _buildAddButton(
                      label: 'Add Note',
                      icon: Icons.add,
                      onTap: _showAddEditNoteDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Display notes
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _notes.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final Map<String, String> noteMap = entry.value;
                    return _buildNoteCard(noteMap, index);
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}