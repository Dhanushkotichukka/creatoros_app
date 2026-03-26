import 'package:flutter/material.dart';
import '../../screens/video_editor_screen.dart';
import '../../screens/image_editor_screen.dart';

class QuickButtons extends StatelessWidget {
  const QuickButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSquareButton(context, Icons.video_call, 'Video Edit', Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VideoEditorScreen()));
        }),
        _buildSquareButton(context, Icons.image, 'Image Edit', Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageEditorScreen()));
        }),
        _buildSquareButton(context, Icons.upload_file, 'Upload', Colors.green, () {}),
        _buildSquareButton(context, Icons.camera_alt, 'Camera', Colors.red, () {}),
      ],
    );
  }

  Widget _buildSquareButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
      ),
    );
  }
}
