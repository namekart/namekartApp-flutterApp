import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Color palette remains the same
const List<Color> _chipColors = [
  Color(0xFF4285F4), // Google Blue
  Color(0xFF34A853), // Google Green
  Color(0xFFFBBC05), // Google Yellow
  Color(0xFFEA4335), // Google Red
  Color(0xFF9C27B0), // Purple
  Color(0xFF009688), // Teal
  Color(0xFFE91E63), // Pink
  Color(0xFF673AB7), // Deep Purple
];

// Public factory function remains the same
Widget createHashtagAndNotesInputWidget({
  List<String> initialHashtags = const [],
  List<Map<String, String>> initialNotes = const [],
  String? notesAuthorName,
  required ValueChanged<List<String>> onHashtagsChanged,
  required ValueChanged<List<Map<String, String>>> onNotesChanged,
}) {
  return _HashtagAndNotesInputWidget(
    initialHashtags: initialHashtags,
    initialNotes: initialNotes,
    notesAuthorName: notesAuthorName,
    onHashtagsChanged: onHashtagsChanged,
    onNotesChanged: onNotesChanged,
  );
}

class _HashtagAndNotesInputWidget extends StatefulWidget {
  final List<String> initialHashtags;
  final List<Map<String, String>> initialNotes;
  final String? notesAuthorName;
  final ValueChanged<List<String>> onHashtagsChanged;
  final ValueChanged<List<Map<String, String>>> onNotesChanged;

  const _HashtagAndNotesInputWidget({
    super.key,
    required this.initialHashtags,
    required this.initialNotes,
    this.notesAuthorName,
    required this.onHashtagsChanged,
    required this.onNotesChanged,
  });

  @override
  State<_HashtagAndNotesInputWidget> createState() =>
      _HashtagAndNotesInputWidgetState();
}

class _HashtagAndNotesInputWidgetState
    extends State<_HashtagAndNotesInputWidget> {
  late List<String> _hashtags;
  late List<Map<String, String>> _notes;
  final TextEditingController _textController = TextEditingController();

  // All state management and helper functions remain the same
  @override
  void initState() {
    super.initState();
    _hashtags = List.from(widget.initialHashtags);
    _notes = List.from(widget.initialNotes);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Color _getColorForHashtag(String tag) {
    return _chipColors[tag.hashCode.abs() % _chipColors.length];
  }

  Future<String?> _showModernDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    required IconData icon,
    String initialValue = '',
    bool isNote = false,
  }) {
    _textController.text = initialValue;
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(title,
              style:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          content: TextField(
            controller: _textController,
            autofocus: true,
            maxLines: isNote ? 5 : 1,
            minLines: 1,
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Save',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_textController.text),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onAddHashtag() async {
    final String? newTag = await _showModernDialog(
      context: context,
      title: 'Add Hashtag',
      hintText: 'e.g., important',
      icon: Icons.tag,
    );

    if (newTag != null && newTag.trim().isNotEmpty) {
      String cleanTag = newTag.trim().replaceAll(' ', '').replaceAll('#', '');
      if (cleanTag.isNotEmpty) {
        cleanTag = '#$cleanTag';
        if (!_hashtags.contains(cleanTag)) {
          setState(() => _hashtags.add(cleanTag));
          widget.onHashtagsChanged(_hashtags);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hashtag "$cleanTag" already exists.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _onAddEditNote(
      {Map<String, String>? initialNote, int? noteIndex}) async {
    final String? newNoteContent = await _showModernDialog(
      context: context,
      title: noteIndex == null ? 'Add Note' : 'Edit Note',
      hintText: 'Type your note here...',
      icon: Icons.notes_rounded,
      initialValue: initialNote?['content'] ?? '',
      isNote: true,
    );

    if (newNoteContent != null) {
      if (newNoteContent.trim().isNotEmpty) {
        setState(() {
          final updatedNote = {
            'content': newNoteContent.trim(),
            'timestamp': DateFormat('MMM d, yyyy HH:mm').format(DateTime.now()),
          };
          if (noteIndex == null) {
            _notes.add(updatedNote);
          } else {
            _notes[noteIndex] = updatedNote;
          }
        });
        widget.onNotesChanged(_notes);
      } else if (noteIndex != null) {
        setState(() => _notes.removeAt(noteIndex));
        widget.onNotesChanged(_notes);
      }
    }
  }

  Widget _buildHashtagChip(String tag) {
    final Color chipColor = _getColorForHashtag(tag);
    return Chip(
      label: Text(tag,
          style: GoogleFonts.poppins(
              color: chipColor, fontWeight: FontWeight.w600, fontSize: 11)),
      backgroundColor: chipColor.withOpacity(0.15),
      onDeleted: () {
        setState(() => _hashtags.remove(tag));
        widget.onHashtagsChanged(_hashtags);
      },
      deleteIcon: Icon(Icons.close_rounded, color: chipColor, size: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: StadiumBorder(side: BorderSide(color: chipColor.withOpacity(0.3))),
    );
  }

  // Generic "Add" chip used in both empty and populated states
  Widget _buildAddChip(
      {required String label,
        required IconData icon,
        required VoidCallback onTap}) {
    return Bounceable(
      onTap: onTap,
      child: Chip(
        label: Text(label,
            style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 11)),
        avatar:
        Icon(icon, color: Colors.grey.shade700, size: 16),
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.grey.shade400, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, String> noteMap, int index) {
    final String displayAuthor = widget.notesAuthorName ?? 'User';
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  noteMap['content'] ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.black87, height: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _onAddEditNote(initialNote: noteMap, noteIndex: index);
                  } else if (value == 'delete') {
                    setState(() => _notes.removeAt(index));
                    widget.onNotesChanged(_notes);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade800),
                      const SizedBox(width: 8),
                      Text('Edit', style: GoogleFonts.poppins()),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text('Delete', style: GoogleFonts.poppins(color: Colors.red.shade700)),
                    ]),
                  ),
                ],
                icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'By $displayAuthor • ${noteMap['timestamp'] ?? ''}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the compact layout shown when no hashtags or notes exist.
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          _buildAddChip(
            label: 'Add Hashtag',
            icon: Icons.add_circle_outline_rounded,
            onTap: _onAddHashtag,
          ),
          _buildAddChip(
            label: 'Add Note',
            icon: Icons.add_circle_outline_rounded,
            onTap: _onAddEditNote,
          ),
        ],
      ),
    );
  }

  /// Builds the full layout with separate sections for hashtags and notes.
  Widget _buildPopulatedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HASHTAGS SECTION ---
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Hashtags',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ..._hashtags.map((tag) => _buildHashtagChip(tag)),
            _buildAddChip(
                label: 'Add Hashtag',
                icon: Icons.add_circle_outline_rounded,
                onTap: _onAddHashtag),
          ],
        ),
        const SizedBox(height: 24),

        // --- NOTES SECTION ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Notes',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
            ),
            if (_notes.isNotEmpty) // Only show button here if notes exist
              TextButton.icon(
                onPressed: _onAddEditNote,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Note'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade800,
                  textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_notes.isEmpty)
        // This part now only shows if hashtags exist but notes don't.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: _buildAddChip(
                label: 'Add a Note',
                icon: Icons.add_circle_outline_rounded,
                onTap: _onAddEditNote,
              ),
            ),
          )
        else
          ListView.builder(
            itemCount: _notes.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return _buildNoteCard(_notes[index], index);
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is the core logic change.
    // We determine if the widget is in a completely empty state.
    final bool isCompletelyEmpty = _hashtags.isEmpty && _notes.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      // AnimatedSwitcher provides a smooth transition between the two layouts.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: child,
            ),
          );
        },
        // We use a key to tell the switcher which widget is being displayed.
        child: isCompletelyEmpty
            ? Align(
          key: const ValueKey('empty'),
          alignment: Alignment.topLeft,
          child: _buildEmptyState(),
        )
            : Align(
          key: const ValueKey('populated'),
          alignment: Alignment.topLeft,
          child: _buildPopulatedState(),
        ),
      ),
    );
  }
}