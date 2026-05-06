import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/charts/reusable_line_chart.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoId;
  final String platform;

  const VideoDetailScreen({super.key, required this.videoId, this.platform = 'YouTube'});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late Future<Map<String, dynamic>> _videoFuture;
  
  // Comments state
  List<dynamic> _comments = [];
  String? _nextPageToken;
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;
  String? _replyingToId;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _videoFuture = ApiService.getVideoAnalytics(widget.videoId);
    _fetchComments();
  }
  
  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments({bool loadMore = false}) async {
    if (_isLoadingComments || !_hasMoreComments) return;
    
    setState(() => _isLoadingComments = true);
    
    try {
      final res = await ApiService.getVideoComments(widget.videoId, pageToken: loadMore ? _nextPageToken : null);
      setState(() {
        if (loadMore) {
          _comments.addAll(res['comments'] ?? []);
        } else {
          _comments = res['comments'] ?? [];
        }
        _nextPageToken = res['nextPageToken'];
        _hasMoreComments = _nextPageToken != null;
      });
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _postReply(String commentId) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    
    try {
      await ApiService.postVideoReply(widget.videoId, commentId, text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply posted successfully')));
      _replyController.clear();
      setState(() => _replyingToId = null);
      // Ideally we'd refresh just that comment's thread, but for simplicity refresh all or ignore.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to post reply'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Details', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}, tooltip: 'Edit Details'),
          IconButton(icon: const Icon(Icons.open_in_browser), onPressed: () {}, tooltip: 'View on YouTube'),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}, tooltip: 'Share'),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _videoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Failed to load video data", style: TextStyle(color: Colors.red)));
          }

          final data = snapshot.data!;
          final video = data['video'] ?? {};
          final earlyPerf = data['earlyPerformance'] ?? {};
          final deepMetrics = data['deepMetrics'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopSection(video),
                const SizedBox(height: 24),
                _buildPerformanceGraphs(theme, c),
                const SizedBox(height: 24),
                _buildAudienceRetentionGraph(deepMetrics, theme, c),
                const SizedBox(height: 24),
                _buildEarlyPerformanceSummary(earlyPerf, c),
                const SizedBox(height: 24),
                _buildCommentsSection(theme, c),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
      )
    );
  }

  Widget _buildTopSection(Map<String, dynamic> video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                video['thumbnail'] ?? '',
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(height: 220, color: Colors.grey[900]),
              ),
            ),
            Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.play_arrow, size: 40, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        Text(video['title'] ?? 'Untitled Video', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${video['views']} views', style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 16),
            const Icon(Icons.thumb_up, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${video['likes']} likes', style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 16),
            const Icon(Icons.comment, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${video['commentsCount']} comments', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceGraphs(ThemeData theme, AppColors c) {
    // Mock performance graph data
    final views = List.generate(14, (i) => 100.0 + (i * 50) + (i % 3 * 20));
    final watchTime = List.generate(14, (i) => 5.0 + (i * 2) + (i % 2 * 3));
    final labels = List.generate(14, (i) => 'Day $i');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance (First 14 Days)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ReusableLineChart(
                values: views,
                labels: labels,
                title: 'Views',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ReusableLineChart(
                values: watchTime,
                labels: labels,
                title: 'Watch Time (Hours)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceRetentionGraph(Map<String, dynamic> deepMetrics, ThemeData theme, AppColors c) {
    final retentionRaw = deepMetrics['watchRetention'] as List<dynamic>? ?? [100, 85, 70, 50, 30];
    final retention = retentionRaw.map((e) => (e as num).toDouble()).toList();
    final labels = List.generate(retention.length, (i) => '${(i / (retention.length - 1) * 100).toInt()}%');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audience Retention', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ReusableLineChart(
                values: retention,
                labels: labels,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarlyPerformanceSummary(Map<String, dynamic> earlyPerf, AppColors c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Early Performance Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('First ${earlyPerf['timeSinceUpload'] ?? 'Unknown'}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
            const Divider(),
            _buildSummaryRow('Views', earlyPerf['views'] ?? '0', isUp: true),
            _buildSummaryRow('Impression Rate', earlyPerf['impressionRate'] ?? '0%', isUp: true),
            _buildSummaryRow('Subscriber Gain', earlyPerf['subGain'] ?? '0', isUp: true),
            _buildSummaryRow('Comments Ratio', earlyPerf['commentsToViews'] ?? '0%', isUp: false),
          ],
        )
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isUp = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(label, style: const TextStyle(color: Colors.grey)),
           Row(
             children: [
               Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isUp ? Colors.green : null)),
               if (isUp) const SizedBox(width: 4),
               if (isUp) const Icon(Icons.arrow_upward, size: 12, color: Colors.green),
             ]
           )
        ],
      )
    );
  }

  Widget _buildCommentsSection(ThemeData theme, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_comments.isEmpty && !_isLoadingComments)
          const Text('No comments available.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (ctx, i) {
              final comment = _comments[i];
              return _buildCommentCard(comment, theme, c);
            },
          ),
        if (_isLoadingComments)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_hasMoreComments && !_isLoadingComments && _comments.isNotEmpty)
          Center(
            child: TextButton(
              onPressed: () => _fetchComments(loadMore: true),
              child: const Text('Load More Comments'),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> c, ThemeData theme, AppColors colors) {
    final bool isReplying = _replyingToId == c['id'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(c['authorAvatar'] ?? ''),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(width: 8),
                Text(c['author'] ?? '@user', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                if ((c['likes'] ?? 0) > 0)
                  Row(
                    children: [
                      const Icon(Icons.thumb_up, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${c['likes']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(c['text'] ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _replyingToId = isReplying ? null : c['id']),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.reply, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('Reply', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            if (isReplying)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: const InputDecoration(
                          hintText: 'Add a reply...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: theme.colorScheme.primary),
                      onPressed: () => _postReply(c['id']),
                    ),
                  ],
                ),
              ),
            if ((c['replies'] as List<dynamic>? ?? []).isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: (c['replies'] as List<dynamic>).map((r) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: NetworkImage(r['authorAvatar'] ?? ''),
                          onBackgroundImageError: (_, __) {},
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['author'] ?? '@user', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(r['text'] ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        )
      )
    );
  }
}
