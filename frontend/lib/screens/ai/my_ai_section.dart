import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../utils/app_colors.dart';
import '../../widgets/video_card_widget.dart';
import '../../widgets/transcript_modal.dart';
import '../../services/auth_service.dart';
import '../../services/history_service.dart';

class MyAISection extends StatefulWidget {
  const MyAISection({super.key});

  @override
  State<MyAISection> createState() => _MyAISectionState();
}

class _MyAISectionState extends State<MyAISection>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _categoryController = TextEditingController();
  late TabController _tabController;

  bool _isLoading = false;
  List<dynamic> _videos = [];
  List<dynamic> _topics = [];
  String? _error;
  String? _message;

  // Selected video IDs for script generation
  final Set<String> _selectedVideoIds = {};
  // Cached transcripts by videoId
  final Map<String, String> _transcriptCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // ── Fetch both videos and topics in parallel ─────────────────────────
  Future<void> _fetchAll() async {
    final category = _categoryController.text.trim();
    if (category.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _videos = [];
      _topics = [];
      _error = null;
      _message = null;
      _selectedVideoIds.clear();
    });

    try {
      final headers = await AuthService.getAuthHeaders();
      final results = await Future.wait([
        http.post(
          Uri.parse('https://creatoros-backend-rb5b.onrender.com/api/ai/my-ai/trending-videos'),
          headers: headers,
          body: jsonEncode({'category': category}),
        ),
        http.post(
          Uri.parse('https://creatoros-backend-rb5b.onrender.com/api/ai/my-ai/trends'),
          headers: headers,
          body: jsonEncode({'category': category}),
        ),
      ]);

      final videoRes = results[0];
      final topicRes = results[1];

      // Handle video results
      if (videoRes.statusCode == 200) {
        final d = jsonDecode(videoRes.body);
        _videos = d['videos'] ?? [];
        _message = d['message'];
      } else if (videoRes.statusCode >= 400) {
        final d = jsonDecode(videoRes.body);
        _error = d['error'] ?? 'Search failed (Error ${videoRes.statusCode})';
      }

      // Handle topic results
      if (topicRes.statusCode == 200) {
        final d = jsonDecode(topicRes.body);
        _topics = d['topics'] ?? [];
      } else if (topicRes.statusCode >= 400 && _error == null) {
        final d = jsonDecode(topicRes.body);
        _error = d['error'];
      }

      if (_error == null && _videos.isEmpty && _topics.isEmpty) {
        _error = 'No data found for "$category". Try a different topic.';
      } else if (_error == null) {
        await HistoryService.saveMyAiHistory(category, _videos, _topics);
      }
    } catch (e) {
      _error = 'Network error. Please ensure the backend is running and you have an active internet connection.';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Navigate to Script Workshop ───────────────────────────────────────
  void _goToScriptWorkshop({
    required String topic,
    Map<String, dynamic>? sourceDetails,
    List<Map<String, dynamic>>? selectedVideos,
  }) {
    // Build transcripts list from cache
    final transcripts = <Map<String, dynamic>>[];
    if (selectedVideos != null) {
      for (final v in selectedVideos) {
        final vid = v['videoId'] as String?;
        if (vid != null && _transcriptCache.containsKey(vid)) {
          transcripts.add({
            'title': v['title'] ?? '',
            'transcript': _transcriptCache[vid],
          });
        }
      }
    }

    Navigator.of(context, rootNavigator: true).pushNamed(
      '/ai/script_workshop',
      arguments: {
        'topic': topic,
        'sourceDetails': sourceDetails ?? {},
        'platform': 'YouTube',
        'selectedVideos': selectedVideos ?? [],
        'sourceTranscripts': transcripts,
      },
    );
  }

  // ── Get selected video objects ────────────────────────────────────────
  List<Map<String, dynamic>> get _selectedVideos {
    return _videos
        .where((v) => _selectedVideoIds.contains(_videoKey(v)))
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
  }

  String _videoKey(dynamic v) =>
      v['videoId']?.toString() ?? v['url']?.toString() ?? v['title']?.toString() ?? '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        _buildSearchBar(c),
        // Tab bar
        Container(
          color: c.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: c.primary,
            unselectedLabelColor: c.textSecondary,
            indicatorColor: c.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.video_library_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Text('Trending Videos'),
                    if (_videos.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_videos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Text('AI Topic Ideas'),
                    if (_topics.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_topics.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? _buildLoadingState(c)
              : _error != null
                  ? _buildError(c)
                  : _videos.isEmpty && _topics.isEmpty
                      ? _buildEmptyState(c)
                      : _buildTabs(c),
        ),
      ],
    );
  }

  void _showHistoryModal() {
    final history = HistoryService.getMyAiHistory();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final c = Theme.of(context).extension<AppColors>()!;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🕰️ Search History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.textPrimary)),
                    TextButton(
                      onPressed: () async {
                        await HistoryService.clearMyAiHistory();
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: history.isEmpty
                    ? Center(child: Text('No history available', style: TextStyle(color: c.textSecondary)))
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return ListTile(
                            leading: const Icon(Icons.search),
                            title: Text('"${item['category']}"', style: TextStyle(color: c.textPrimary)),
                            subtitle: Text('Videos: ${item['videos']?.length ?? 0} | Topics: ${item['topics']?.length ?? 0}', style: TextStyle(color: c.textSecondary)),
                            trailing: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _categoryController.text = item['category'];
                                  _videos = item['videos'];
                                  _topics = item['topics'];
                                  _error = null;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.primary.withOpacity(0.1),
                                foregroundColor: c.primary,
                                elevation: 0,
                              ),
                              child: const Text('Restore'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(AppColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trend Intelligence',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Real-time trending videos + AI-powered topic ideas',
                        style: TextStyle(fontSize: 13, color: c.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.history, color: c.textSecondary),
                onPressed: _showHistoryModal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  onSubmitted: (_) => _fetchAll(),
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText:
                        'Enter your niche (e.g. Telugu Cinema, Finance)...',
                    hintStyle: TextStyle(color: c.textSecondary),
                    filled: true,
                    fillColor: c.background,
                    prefixIcon:
                        Icon(Icons.search, color: c.textSecondary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Search',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(AppColors c) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildVideosTab(c),
        _buildTopicsTab(c),
      ],
    );
  }

  // ── VIDEOS TAB ────────────────────────────────────────────────────────
  Widget _buildVideosTab(AppColors c) {
    if (_videos.isEmpty) {
      return _buildSectionEmpty(
          'No trending videos found. Try connecting your YouTube account for personalized results.',
          Icons.video_library_outlined,
          c);
    }

    final hasSelection = _selectedVideoIds.isNotEmpty;

    return Column(
      children: [
        // Selection action bar
        if (hasSelection)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            color: c.primary.withOpacity(0.06),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedVideoIds.length} selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Selected videos will be used as context for script generation',
                    style: TextStyle(
                        fontSize: 11, color: c.textSecondary),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final category = _categoryController.text.trim();
                    _goToScriptWorkshop(
                      topic: category.isNotEmpty ? '$category — Viral Script' : 'Viral Script',
                      selectedVideos: _selectedVideos,
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 14),
                  label: const Text('Generate',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

        // Videos list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              final video = _videos[index];
              final key = _videoKey(video);
              final videoId = video['videoId'] as String?;

              return VideoCard(
                video: Map<String, dynamic>.from(video),
                isSelected: _selectedVideoIds.contains(key),
                showSelection: true,
                onToggleSelect: () {
                  setState(() {
                    if (_selectedVideoIds.contains(key)) {
                      _selectedVideoIds.remove(key);
                    } else {
                      _selectedVideoIds.add(key);
                    }
                  });
                },
                onViewScript: videoId != null
                    ? () {
                        TranscriptModal.show(
                          context,
                          videoId: videoId,
                          videoTitle: video['title'] ?? '',
                          onTranscriptLoaded: (t) {
                            _transcriptCache[videoId] = t;
                          },
                          onUseTranscript: () {
                            // Auto-select this video and go to workshop
                            setState(() => _selectedVideoIds.add(key));
                            _goToScriptWorkshop(
                              topic: video['title'] ?? 'Viral Script',
                              sourceDetails: Map<String, dynamic>.from(video),
                              selectedVideos: [Map<String, dynamic>.from(video)],
                            );
                          },
                        );
                      }
                    : null,
                onGenerateScript: () {
                  _goToScriptWorkshop(
                    topic: video['title'] ?? 'Viral Script',
                    sourceDetails: Map<String, dynamic>.from(video),
                    selectedVideos: _selectedVideoIds.isNotEmpty
                        ? _selectedVideos
                        : [Map<String, dynamic>.from(video)],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── TOPICS TAB ────────────────────────────────────────────────────────
  Widget _buildTopicsTab(AppColors c) {
    if (_topics.isEmpty) {
      return _buildSectionEmpty(
          'No AI topic ideas generated yet. Search a niche to begin.',
          Icons.auto_awesome_outlined,
          c);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final topic = _topics[index];
        return _buildTopicCard(topic, c);
      },
    );
  }

  Widget _buildTopicCard(dynamic topic, AppColors c) {
    final title = topic['title'] ?? 'Unknown Topic';
    final trendScore = (topic['trendScore'] ?? 0) as num;
    final whyTrending = topic['whyTrending'] ?? '';
    final srcDetails = topic['sourceDetails'] ?? {};
    final source = srcDetails['source'] ?? 'AI';
    final origTitle = srcDetails['originalTitle'] ?? title;
    final thumbnail = srcDetails['thumbnail'];
    final views = srcDetails['views'] ?? '';
    final ago = srcDetails['timeAgo'] ?? '';
    final url = srcDetails['url'];
    final videoId = srcDetails['videoId'];
    final scoreInt = trendScore.toInt();

    final scoreColor = scoreInt >= 80
        ? Colors.green
        : scoreInt >= 60
            ? Colors.orange
            : Colors.red;
    final sourceColor = source == 'YouTube'
        ? Colors.red
        : source == 'Google Trends'
            ? Colors.blue
            : Colors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (thumbnail != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(thumbnail,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(height: 80, color: c.background)),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up,
                              color: scoreColor, size: 13),
                          const SizedBox(width: 4),
                          Text('$scoreInt',
                              style: TextStyle(
                                  color: scoreColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source tag + meta
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: sourceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_sourceIcon(source),
                              color: sourceColor, size: 11),
                          const SizedBox(width: 4),
                          Text(source,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: sourceColor)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (views.isNotEmpty)
                      Text('👁 $views',
                          style: TextStyle(
                              color: c.textSecondary, fontSize: 11)),
                    if (ago.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('🕐 $ago',
                          style: TextStyle(
                              color: c.textSecondary, fontSize: 11)),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // Title
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                        height: 1.35)),
                if (origTitle != title && origTitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text('Based on: "$origTitle"',
                      style: TextStyle(
                          fontSize: 11,
                          color: c.textSecondary,
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                if (whyTrending.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 13, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(whyTrending,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: c.textSecondary,
                                  height: 1.4))),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                // Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (url != null)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(url);
                          // ignore: deprecated_member_use
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new, size: 13),
                        label: const Text('View Source',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.primary,
                          side: BorderSide(
                              color: c.primary.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (videoId != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          TranscriptModal.show(
                            context,
                            videoId: videoId.toString(),
                            videoTitle: origTitle,
                            onTranscriptLoaded: (t) {
                              _transcriptCache[videoId.toString()] = t;
                            },
                          );
                        },
                        icon: const Icon(Icons.article_outlined, size: 13),
                        label: const Text('View Script',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(
                              color: Colors.blue.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: () {
                        _goToScriptWorkshop(
                          topic: title,
                          sourceDetails: Map<String, dynamic>.from(srcDetails),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 13),
                      label: const Text('Generate Script',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _sourceIcon(String source) {
    if (source == 'YouTube') return Icons.play_circle_filled;
    if (source == 'Google Trends') return Icons.trending_up;
    return Icons.article;
  }

  Widget _buildSectionEmpty(String msg, IconData icon, AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.06),
                  shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: c.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: c.textSecondary, fontSize: 13, height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                    color: c.primary.withOpacity(0.2), strokeWidth: 7),
                CircularProgressIndicator(
                    color: c.primary,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Scanning Trending Videos...',
              style: TextStyle(
                  color: c.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('YouTube + Google Trends + News',
              style: TextStyle(color: c.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
                color: c.primary.withOpacity(0.07), shape: BoxShape.circle),
            child: Icon(Icons.video_library,
                size: 52, color: c.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
              _message ?? 'Enter your niche to discover trending videos',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Real data from YouTube, Google Trends & News',
              style: TextStyle(color: c.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError(AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchAll, child: const Text('Retry')),
        ],
      ),
    );
  }
}


