import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/responsive.dart';

// Simple local note model for the Hub screen
class _Note {
  final String id;
  String title;
  String content;
  String category;
  bool isPinned;
  final DateTime createdAt;
  Color color;

  _Note({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'General',
    this.isPinned = false,
    required this.createdAt,
    required this.color,
  });
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Script', 'Ideas', 'Sponsored', 'General'];

  final List<_Note> _notes = [
    _Note(
      id: '1',
      title: 'Script Draft: Vlogging Tips',
      content: 'Remember to talk about the Rule of Thirds. Open with a strong hook — try "Did you know most viewers leave in the first 3 seconds?"',
      category: 'Script',
      isPinned: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      color: const Color(0xFF4A148C),
    ),
    _Note(
      id: '2',
      title: 'Video Ideas',
      content: '1. A day in the life\n2. Setup Reveal\n3. Q&A with subscribers',
      category: 'Ideas',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      color: const Color(0xFF1A237E),
    ),
    _Note(
      id: '3',
      title: 'Sponsored Read',
      content: 'Make sure to mention the 20% off code at the intro. Keep it under 45 seconds.',
      category: 'Sponsored',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      color: const Color(0xFF263238),
    ),
  ];

  final _noteColors = const [
    Color(0xFF4A148C),
    Color(0xFF1A237E),
    Color(0xFF263238),
    Color(0xFF1B5E20),
    Color(0xFF880E4F),
    Color(0xFF4E342E),
  ];

  void _openNoteEditor({_Note? note}) {
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    String selectedCat = note?.category ?? 'General';
    Color selectedColor = note?.color ?? _noteColors.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(note == null ? 'New Note' : 'Edit Note',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              note?.isPinned == true ? Icons.push_pin : Icons.push_pin_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () {
                              if (note != null) {
                                setModal(() => note.isPinned = !note.isPinned);
                              }
                            },
                          ),
                          TextButton(
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty) return;
                              setState(() {
                                if (note == null) {
                                  _notes.add(_Note(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    title: titleCtrl.text.trim(),
                                    content: contentCtrl.text.trim(),
                                    category: selectedCat,
                                    color: selectedColor,
                                    createdAt: DateTime.now(),
                                  ));
                                } else {
                                  note.title = titleCtrl.text.trim();
                                  note.content = contentCtrl.text.trim();
                                  note.category = selectedCat;
                                  note.color = selectedColor;
                                }
                              });
                              Navigator.pop(ctx);
                            },
                            child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleCtrl,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Title...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                          ),
                        ),
                        const Divider(),
                        TextField(
                          controller: contentCtrl,
                          maxLines: null,
                          minLines: 8,
                          style: const TextStyle(fontSize: 15, height: 1.6),
                          decoration: InputDecoration(
                            hintText: 'Write your note...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _categories.where((c) => c != 'All').map((cat) => ChoiceChip(
                            label: Text(cat, style: const TextStyle(fontSize: 12)),
                            selected: selectedCat == cat,
                            onSelected: (v) { if (v) setModal(() => selectedCat = cat); },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text('Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children: _noteColors.map((color) => GestureDetector(
                            onTap: () => setModal(() => selectedColor = color),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: selectedColor == color
                                    ? Border.all(color: Colors.white, width: 2.5)
                                    : null,
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteNote(String id) {
    setState(() => _notes.removeWhere((n) => n.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var filtered = _selectedCategory == 'All'
        ? List<_Note>.from(_notes)
        : _notes.where((n) => n.category == _selectedCategory).toList();

    // Sort pinned first then by date
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Idea Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openNoteEditor(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Chips
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (v) { if (v) setState(() => _selectedCategory = cat); },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_outlined, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.15)),
                        const SizedBox(height: 16),
                        Text('No notes yet', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openNoteEditor(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Note'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = Responsive.noteGridColumns(width);
                      final aspectRatio = Responsive.noteAspectRatio(width);

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final note = filtered[i];
                          return GestureDetector(
                            onTap: () => _openNoteEditor(note: note),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: note.color,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title,
                                          style: TextStyle(
                                            fontSize: columns >= 5 ? 11 : 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (note.isPinned)
                                        const Icon(Icons.push_pin, size: 12, color: Colors.white70),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      note.content,
                                      style: TextStyle(
                                        fontSize: columns >= 5 ? 10 : 11,
                                        color: Colors.white70,
                                        height: 1.4,
                                      ),
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            note.category,
                                            style: const TextStyle(fontSize: 9, color: Colors.white70),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _deleteNote(note.id),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 14,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteEditor(),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
