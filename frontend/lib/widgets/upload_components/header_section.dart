import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/multi_post/platform_type.dart';
import '../../providers/post_provider.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final connectedPlatforms = provider.connectedPlatforms;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MultiPost-HUB',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.share, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Create once publish every where',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (connectedPlatforms.isNotEmpty)
                  Row(
                    children: connectedPlatforms.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blueGrey.shade800,
                          child: Icon(
                            _getIconForPlatform(p),
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  IconData _getIconForPlatform(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return Icons.play_arrow;
      case PlatformType.instagram:
        return Icons.camera_alt;
      case PlatformType.facebook:
        return Icons.facebook;
      case PlatformType.linkedin:
        return Icons.work;
    }
  }
}
