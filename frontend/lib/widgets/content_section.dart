import 'package:flutter/material.dart';

class ContentSection extends StatelessWidget {
  final String platform;
  final Map<String, dynamic>? contentData;
  const ContentSection({super.key, required this.platform, this.contentData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Latest $platform Content', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: contentData != null && contentData!['thumbnail'] != null
                      ? DecorationImage(
                          image: NetworkImage(contentData!['thumbnail']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: contentData == null || contentData!['thumbnail'] == null
                    ? const Center(child: Icon(Icons.play_circle_outline, size: 50))
                    : const Center(child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contentData != null ? contentData!['title'] : 'Top 5 AI tools for Creators in 2025', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(contentData != null ? '${contentData!['views']} Views • Just now' : '120K Views • 2 days ago', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Row(
                          children: [
                            const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(contentData != null ? '24K' : '12K', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 12),
                            const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(contentData != null ? '106' : '350', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
