import 'package:flutter/material.dart';

class MediaSearchBar extends StatelessWidget {
  const MediaSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search Images / Videos from Internet',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: const Icon(Icons.mic),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Powered by Unsplash • Pexels • Pixabay', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
