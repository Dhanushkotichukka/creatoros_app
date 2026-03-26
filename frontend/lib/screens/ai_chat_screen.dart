import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Hello! I am your CreatorOS Assistant. Need help writing a hook, brainstorming video ideas, or organizing your tasks?'}
  ];
  bool _isLoading = false;

  void _sendMessage() async {
    if (_msgController.text.isEmpty) return;
    
    final prompt = _msgController.text;
    setState(() {
      _messages.add({'role': 'user', 'text': prompt});
      _msgController.clear();
      _isLoading = true;
    });

    try {
      // Re-using the generateScript API for a general chat for demonstration
      final response = await ApiService.generateScript(prompt);
      setState(() {
        _messages.add({'role': 'ai', 'text': response});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Failed to reach AI. Ensure backend is running.'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Creator Chat'),
        backgroundColor: Colors.deepPurple.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isAi = _messages[index]['role'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isAi ? Colors.grey[800] : Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomLeft: isAi ? const Radius.circular(0) : null,
                        bottomRight: !isAi ? const Radius.circular(0) : null,
                      )
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(_messages[index]['text']!),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Ask me to write a YouTube hook...',
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: const CircleAvatar(
                      backgroundColor: Colors.deepPurpleAccent,
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
