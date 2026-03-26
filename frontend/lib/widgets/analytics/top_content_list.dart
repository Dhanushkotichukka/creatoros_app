import 'package:flutter/material.dart';
import '../../screens/video_detail_screen.dart';

class TopContentList extends StatelessWidget {
  final List<dynamic> topContent;
  
  const TopContentList({super.key, required this.topContent});

  @override
  Widget build(BuildContext context) {
    if (topContent.isEmpty) {
      return const Center(child: Text('No top content available', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: topContent.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final content = topContent[index] as Map<String, dynamic>;
        return _buildContentCard(context, content);
      },
    );
  }

  Widget _buildContentCard(BuildContext context, Map<String, dynamic> content) {
    bool isYT = content['platform'] == 'YouTube';
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => VideoDetailScreen(videoId: content['id'] ?? '1')
        ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                content['thumbnail'] ?? 'https://via.placeholder.com/150',
                width: 100,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 60, color: Colors.grey[800], child: const Icon(Icons.broken_image)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content['title'] ?? 'Untitled Content',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(isYT ? Icons.play_circle_fill : Icons.camera_alt, size: 14, color: isYT ? Colors.red : Colors.pink),
                      const SizedBox(width: 4),
                      Text(
                        '${content['views'] ?? '0'} Views',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          '${content['engagement'] ?? '6%'} ER',
                          style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      )
                    ],
                  )
                ],
              )
            )
          ]
        ),
      ),
    );
  }
}
