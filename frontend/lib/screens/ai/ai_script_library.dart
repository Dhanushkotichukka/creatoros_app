import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class AIScriptLibrary extends StatefulWidget {
  const AIScriptLibrary({super.key});

  @override
  State<AIScriptLibrary> createState() => _AIScriptLibraryState();
}

class _AIScriptLibraryState extends State<AIScriptLibrary> {
  bool _isLoading = true;
  List<dynamic> _scripts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchScripts();
  }

  Future<void> _fetchScripts() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://creatoros-backend-rb5b.onrender.com/api/ai/scripts'),
        headers: ApiService.getAuthHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _scripts = data['scripts'] ?? [];
          _error = null;
        });
      } else {
        setState(() => _error = 'Failed to load scripts.');
      }
    } catch (e) {
      setState(() => _error = 'Network error loading scripts.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteScript(String id) async {
    try {
       final response = await http.delete(
         Uri.parse('https://creatoros-backend-rb5b.onrender.com/api/ai/scripts/$id'),
         headers: ApiService.authHeaders,
       );
       if (response.statusCode == 200) {
         _fetchScripts();
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Script deleted.')));
       }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete script.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));

    if (_scripts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 64, color: c.border),
            const SizedBox(height: 16),
            Text('No scripts saved yet.', style: TextStyle(color: c.textSecondary, fontSize: 18)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _scripts.length,
      itemBuilder: (context, index) {
        final script = _scripts[index];
        final title = script['topicTitle'] ?? 'Untitled';
        final rating = script['aiRating']?.toString() ?? '0.0';
        
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.description, color: c.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: c.textPrimary, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteScript(script['id'])),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hook: ${script['hook']}', style: TextStyle(color: c.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('AI Rating: $rating', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                                // Full view logic (can be added later to route back into workshop)
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Full Viewer Coming Soon')));
                            },
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View'),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
