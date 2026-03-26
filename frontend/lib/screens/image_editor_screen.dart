import 'package:flutter/material.dart';

class ImageEditorScreen extends StatelessWidget {
  const ImageEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Image Editor'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Save', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          // Image Canvas Area
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Icon(Icons.image, size: 80, color: Colors.white54),
              ),
            ),
          ),
          
          // Tools Area
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Editing Tools', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToolButton(Icons.crop, 'Crop'),
                        const SizedBox(width: 20),
                        _buildToolButton(Icons.format_shapes, 'Presets'),
                        const SizedBox(width: 20),
                        _buildToolButton(Icons.color_lens, 'Filters'),
                        const SizedBox(width: 20),
                        _buildToolButton(Icons.text_fields, 'Text'),
                        const SizedBox(width: 20),
                        _buildToolButton(Icons.layers_clear, 'Remove BG', isAI: true),
                        const SizedBox(width: 20),
                        _buildToolButton(Icons.auto_awesome, 'AI Enhance', isAI: true),
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

  Widget _buildToolButton(IconData icon, String label, {bool isAI = false}) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            if (isAI)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.deepPurpleAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.star, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
