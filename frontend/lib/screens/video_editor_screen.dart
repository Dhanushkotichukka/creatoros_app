import 'package:flutter/material.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  double _trimStart = 0.0;
  double _trimEnd = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Editor'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Export', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          // Video Player Area
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Icon(Icons.play_circle_outline, size: 80, color: Colors.white54),
              ),
            ),
          ),
          
          // Tools Area
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline / Trimmer UI
                  const Text('Timeline & Trim', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('0:00', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Expanded(
                        child: RangeSlider(
                          values: RangeValues(_trimStart, _trimEnd),
                          onChanged: (RangeValues values) {
                            setState(() {
                              _trimStart = values.start;
                              _trimEnd = values.end;
                            });
                          },
                          activeColor: Colors.deepPurpleAccent,
                          inactiveColor: Colors.grey[800],
                        ),
                      ),
                      const Text('1:00', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Tool Buttons
                  const Text('Tools', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToolButton(Icons.aspect_ratio, 'Aspect Ratio'),
                        const SizedBox(width: 15),
                        _buildToolButton(Icons.subtitles, 'Auto-Captions'),
                        const SizedBox(width: 15),
                        _buildToolButton(Icons.music_note, 'Audio'),
                        const SizedBox(width: 15),
                        _buildToolButton(Icons.auto_fix_high, 'AI Enhance'),
                        const SizedBox(width: 15),
                        _buildToolButton(Icons.color_lens, 'Filters'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
