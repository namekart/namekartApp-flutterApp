import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../activity_helpers/DbAccountHelper.dart';

class QuickNotesScreen extends StatefulWidget {
  const QuickNotesScreen({super.key});
  static const String userId = 'default_user';
  static const String accountPath = 'account~user~details';

  @override
  State<QuickNotesScreen> createState() => _QuickNotesScreenState();
}

class _QuickNotesScreenState extends State<QuickNotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuicknotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Data Logic (Preserved from original code) ---
  Future<void> _loadQuicknotes() async {
    setState(() => _isLoading = true);
    try {
      final loadedData = await DbAccountHelper.getQuicknote(
          QuickNotesScreen.accountPath, QuickNotesScreen.userId);
      List<Map<String, dynamic>> convertedData = [];
      if (loadedData != null) {
        for (var categoryMap in loadedData) {
          categoryMap.forEach((key, value) {
            if (value is List) {
              for (var item in value) {
                if (key == 'notes') {
                  convertedData
                      .add({"type": "note", "content": item.toString()});
                } else if (key == 'todo' &&
                    item is Map<String, dynamic> &&
                    item.containsKey('content') &&
                    item.containsKey('isDone')) {
                  convertedData.add({
                    "type": "todo",
                    "content": item['content'],
                    "isDone": item['isDone']
                  });
                }
              }
            }
          });
        }
      }
      setState(() {
        _data = convertedData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load quicknotes: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load quicknotes: $e')),
        );
      }
    }
  }

  Future<void> _saveQuicknotes() async {
    List<String> notesContent = [];
    List<Map<String, dynamic>> todosContent = [];
    for (var item in _data) {
      if (item['type'] == 'note') {
        notesContent.add(item['content']);
      } else if (item['type'] == 'todo') {
        todosContent.add({"content": item['content'], "isDone": item['isDone']});
      }
    }
    final List<Map<String, dynamic>> formattedData = [];
    if (notesContent.isNotEmpty) formattedData.add({"notes": notesContent});
    if (todosContent.isNotEmpty) formattedData.add({"todo": todosContent});
    try {
      await DbAccountHelper.updateQuicknotes(
          QuickNotesScreen.accountPath, QuickNotesScreen.userId, formattedData);
    } catch (e) {
      debugPrint('Failed to save quicknotes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save quicknotes: $e')),
        );
      }
    }
  }

  void _addNewItem(
      {String? initialContent, int? editIndex, required String type}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditBottomSheet(
        initialContent: initialContent,
        itemType: type,
        onSave: (content) {
          setState(() {
            if (editIndex != null) {
              _data[editIndex]['content'] = content;
            } else {
              final newItem = type == 'note'
                  ? {"type": "note", "content": content}
                  : {"type": "todo", "content": content, "isDone": false};
              _data.insert(0, newItem);
            }
          });
          _saveQuicknotes();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() => _data.removeAt(index));
    _saveQuicknotes();
  }

  void _toggleTodoDone(int index, bool? value) {
    setState(() => _data[index]['isDone'] = value ?? false);
    _saveQuicknotes();
  }
  // --- End of Data Logic ---

  @override
  Widget build(BuildContext context) {
    final notes = _data.where((item) => item['type'] == 'note').toList();
    final todos = _data.where((item) => item['type'] == 'todo').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Quick Pad',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.black87,fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.blue.shade50,
          ),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          tabs: const [Tab(text: 'Notes'), Tab(text: 'To-Do List')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildNotesTab(notes),
          _buildTodosTab(todos),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewItem(
            type: _tabController.index == 0 ? 'note' : 'todo'),
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotesTab(List<Map<String, dynamic>> notes) {
    if (notes.isEmpty) {
      return const _EmptyStateView(
          icon: Icons.note_alt_outlined, message: "No notes yet.");
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final item = notes[index];
        final actualIndex = _data.indexOf(item);
        return _NoteCard(
          content: item['content'],
          onEdit: () =>
              _addNewItem(initialContent: item['content'], editIndex: actualIndex, type: 'note'),
          onDelete: () => _deleteItem(actualIndex),
        );
      },
    );
  }

  Widget _buildTodosTab(List<Map<String, dynamic>> todos) {
    if (todos.isEmpty) {
      return const _EmptyStateView(
          icon: Icons.check_box_outlined, message: "No to-dos yet.");
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final item = todos[index];
        final actualIndex = _data.indexOf(item);
        return _TodoCard(
          content: item['content'],
          isDone: item['isDone'],
          onChanged: (value) => _toggleTodoDone(actualIndex, value),
          onEdit: () => _addNewItem(
              initialContent: item['content'], editIndex: actualIndex, type: 'todo'),
          onDelete: () => _deleteItem(actualIndex),
        );
      },
    );
  }
}

// --- Redesigned UI Widgets ---

class _EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyStateView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(message, style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade500)),
          Text("Tap the '+' to add one!", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String content;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({required this.content, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description_outlined, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(content, style: GoogleFonts.poppins(fontSize: 15, height: 1.5)),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final String content;
  final bool isDone;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TodoCard({
    required this.content,
    required this.isDone,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDone ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDone ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Checkbox(
          value: isDone,
          onChanged: onChanged,
          shape: const CircleBorder(),
          activeColor: Colors.green,
        ),
        title: Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 15,
            decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
            color: isDone ? Colors.grey.shade500 : Colors.black87,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class AddEditBottomSheet extends StatefulWidget {
  final String? initialContent;
  final String itemType;
  final Function(String) onSave;

  const AddEditBottomSheet({
    super.key,
    this.initialContent,
    required this.itemType,
    required this.onSave,
  });

  @override
  State<AddEditBottomSheet> createState() => _AddEditBottomSheetState();
}

class _AddEditBottomSheetState extends State<AddEditBottomSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialContent != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing
                  ? 'Edit ${widget.itemType}'
                  : 'New ${widget.itemType}',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type something...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    widget.onSave(_controller.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.bold,color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}







