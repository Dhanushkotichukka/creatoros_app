import 'package:flutter/material.dart';
import '../../screens/video_detail_screen.dart';

class VideoTabs extends StatelessWidget {
  final List<dynamic> videos;

  const VideoTabs({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            isScrollable: true,
            indicatorColor: Colors.deepPurpleAccent,
            labelColor: Colors.deepPurpleAccent,
            unselectedLabelColor: Colors.grey,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Latest'),
              Tab(text: 'Popular'),
              Tab(text: 'Old'),
              Tab(text: 'Scheduled'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400, // Fixed bounded height container for strict tabular views inside an open-ended scroll container
            child: TabBarView(
              children: [
                _buildVideoList(videos),
                _buildVideoList(videos.reversed.toList()), // Simulated Data Order Change
                const Center(child: Text('No Old Videos loaded.', style: TextStyle(color: Colors.grey))),
                const Center(child: Text('No Scheduled Videos pending.', style: TextStyle(color: Colors.grey))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList(List<dynamic> videoList) {
    if (videoList.isEmpty) return const Center(child: Text('No videos found', style: TextStyle(color: Colors.grey)));

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: videoList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final video = videoList[index];
        return InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => VideoDetailScreen(videoId: video['id'] ?? '1')
            ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    video['thumbnail'] ?? 'https://via.placeholder.com/150',
                    width: 120,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 120, height: 70, color: Colors.grey[800], child: const Icon(Icons.broken_image)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title'] ?? 'Untitled Video Source',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white, height: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${video['views'] ?? '0'} Views • ${video['likes'] ?? '0'} Likes',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ]
                  )
                )
              ]
            ),
          )
        );
      },
    );
  }
}
