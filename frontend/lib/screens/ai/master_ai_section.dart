import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../utils/app_colors.dart';
import '../../widgets/video_card_widget.dart';
import '../../widgets/transcript_modal.dart';
import '../../services/api_service.dart';
import '../../services/history_service.dart';

class MasterAISection extends StatefulWidget {
  const MasterAISection({super.key});

  @override
  State<MasterAISection> createState() => _MasterAISectionState();
}

class _MasterAISectionState extends State<MasterAISection> with AutomaticKeepAliveClientMixin {
  bool _isYouTubeConnected = false;
  String? _youtubeChannelName;
  bool _isMetaConnected = false;
  String? _metaUsername;
  String _selectedPlatform = 'YouTube';
  bool _isCheckingConnection = true;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  @override
  void initState() {
    super.initState();
    _checkConnections();
  }

  Future<void> _checkConnections() async {
    setState(() => _isCheckingConnection = true);
    try {
      final ytRes = await http.get(
        Uri.parse('https://creatoros-backend-rb5b.onrender.com/auth/youtube/status'),
        headers: ApiService.getAuthHeaders,
      );
      if (ytRes.statusCode == 200) {
        final d = jsonDecode(ytRes.body);
        _isYouTubeConnected = d['connected'] ?? false;
        _youtubeChannelName = d['name'];
      }
      final metaRes = await http.get(
        Uri.parse('https://creatoros-backend-rb5b.onrender.com/auth/meta/status'),
        headers: ApiService.getAuthHeaders,
      );
      if (metaRes.statusCode == 200) {
        final d = jsonDecode(metaRes.body);
        _isMetaConnected = d['connected'] ?? false;
        _metaUsername = d['username'] ?? d['name'];
      }
    } catch (e) {
      print('Connection check failed: $e');
    } finally {
      setState(() => _isCheckingConnection = false);
    }
  }

  Future<void> _analyzeChannel() async {
    setState(() { _isAnalyzing = true; _analysisResult = null; });
    try {
      final response = await http.post(
        Uri.parse('https://creatoros-backend-rb5b.onrender.com/api/ai/master-ai/analyze-channel'),
        headers: ApiService.authHeaders,
        body: jsonEncode({'platform': _selectedPlatform}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _analysisResult = data['analysis']);
        await HistoryService.saveMasterAiHistory(_selectedPlatform, data['analysis']);
      } else {
        final err = jsonDecode(response.body)['error'] ?? 'Analysis failed';
        _showError(err);
      }
    } catch (e) {
      _showError('Network error. Is backend running?');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = Theme.of(context).extension<AppColors>()!;
    if (_isCheckingConnection) return const Center(child: CircularProgressIndicator());
    final isConnected = _selectedPlatform == 'YouTube' ? _isYouTubeConnected : _isMetaConnected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlatformSelector(c),
          const SizedBox(height: 16),
          if (!isConnected)
            _buildConnectionPrompt(c)
          else if (_isAnalyzing)
            _buildLoadingState(c)
          else if (_analysisResult == null)
            _buildStartPrompt(c)
          else
            _buildDashboard(c, _analysisResult!),
        ],
      ),
    );
  }

  Widget _buildPlatformSelector(AppColors c) {
    return Center(
      child: Container(
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlatTab('YouTube', Icons.play_circle, Colors.red, c),
            _buildPlatTab('Instagram', Icons.camera_alt, Colors.pink, c),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatTab(String label, IconData icon, Color color, AppColors c) {
    final sel = _selectedPlatform == label;
    return GestureDetector(
      onTap: () => setState(() { _selectedPlatform = label; _analysisResult = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(color: sel ? color.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, size: 18, color: sel ? color : c.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: sel ? color : c.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildConnectionPrompt(AppColors c) {
    final color = _selectedPlatform == 'YouTube' ? Colors.red : Colors.pink;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(40),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.border)),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(_selectedPlatform == 'YouTube' ? Icons.play_circle : Icons.camera_alt, color: color, size: 48)),
            const SizedBox(height: 24),
            Text('Connect $_selectedPlatform to Unlock Master AI', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 12),
            Text('Master AI analyzes your real channel data and combines it with live trending signals to generate high-impact content ideas.',
                textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.5)),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                final url = Uri.parse(_selectedPlatform == 'YouTube'
                    ? 'https://creatoros-backend-rb5b.onrender.com/auth/youtube/login'
                    : 'https://creatoros-backend-rb5b.onrender.com/auth/meta/login');
                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.link),
              label: Text('Connect $_selectedPlatform', style: const TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _checkConnections, child: const Text('I connected, refresh status')),
          ],
        ),
      ),
    );
  }

  Widget _buildStartPrompt(AppColors c) {
    final name = _selectedPlatform == 'YouTube' ? _youtubeChannelName : _metaUsername;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border)),
      child: Column(
        children: [
          Text('✅ Connected as: ${name ?? _selectedPlatform}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Icon(Icons.auto_awesome, size: 56, color: c.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('Ready for Deep Intelligence Analysis?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('We\'ll analyze your last 30 videos, detect your niche\nand combine it with live trending data.',
              textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.5)),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _analyzeChannel,
            icon: const Icon(Icons.analytics),
            label: const Text('Start Master Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: FilledButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppColors c) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [c.primary.withOpacity(0.08), c.surface],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: c.primary.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            SizedBox(width: 80, height: 80,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(color: c.primary.withOpacity(0.15), strokeWidth: 10),
                CircularProgressIndicator(color: c.primary, strokeWidth: 4, strokeCap: StrokeCap.round),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary.withOpacity(0.12)),
                  child: Icon(Icons.auto_awesome, color: c.primary, size: 22),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            Text('Running Deep Intelligence...', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c.textPrimary, letterSpacing: 0.3)),
            const SizedBox(height: 10),
            Text('Scraping real videos → Detecting niche → Scanning live signals', style: TextStyle(color: c.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              _stepChip('📹 Fetching Videos', c),
              _stepChip('🎯 Niche Detection', c),
              _stepChip('🚀 Trend Analysis', c),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _stepChip(String label, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.primary.withOpacity(0.25)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: c.primary, fontWeight: FontWeight.w600)),
    );
  }

  void _showHistoryModal() {
    final history = HistoryService.getMasterAiHistory(_selectedPlatform);
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
                    Text('🕰️ $_selectedPlatform History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.textPrimary)),
                    TextButton(
                      onPressed: () async {
                        await HistoryService.clearMasterAiHistory(_selectedPlatform);
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
                          // Format timestamp
                          final dt = DateTime.parse(item['timestamp']).toLocal();
                          final ts = '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                          return ListTile(
                            leading: const Icon(Icons.analytics),
                            title: Text('Analysis Report', style: TextStyle(color: c.textPrimary)),
                            subtitle: Text(ts, style: TextStyle(color: c.textSecondary)),
                            trailing: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _analysisResult = item['analysisResult'];
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

  // ─── DASHBOARD ──────────────────────────────────────────────────────
  Widget _buildDashboard(AppColors c, Map<String, dynamic> data) {
    final niche = data['niche'] ?? {};
    final topPerforming = data['topPerforming'] as List? ?? [];
    final externalTrends = data['externalTrends'] as List? ?? [];
    final smartTopics = data['smartTopics'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Banner ─────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [c.primary.withOpacity(0.15), c.primary.withOpacity(0.04)],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            border: Border.all(color: c.primary.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: c.primary.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.psychology, color: c.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Master Intelligence Report', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: c.textPrimary)),
                  Text('Real channel data · Live niche detection', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                ]),
              ),
              FilledButton.icon(
                onPressed: _analyzeChannel,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Re-analyze', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary.withOpacity(0.15),
                  foregroundColor: c.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.history, color: c.textSecondary),
                onPressed: _showHistoryModal,
              ),
            ],
          ),
        ),

        // ── SECTION 1: Niche ─────────────────────────────────────────
        _sectionLabel('🎯 SECTION 1: Niche Detection', c),
        _buildNicheCard(niche, c),
        const SizedBox(height: 24),

        // ── SECTION 2: Top Performing ───────────────────────────────
        _sectionLabel('🔥 SECTION 2: Your Top Performing Content', c),
        if (topPerforming.isEmpty)
          _buildEmptySection('No video data available', c)
        else
          ...topPerforming.take(5).map((v) => _buildVideoCardItem(v, c, isChannelVideo: true)).toList(),
        const SizedBox(height: 24),

        // ── SECTION 3: Trending Now ─────────────────────────────────
        _sectionLabel('🚀 SECTION 3: Trending Now in Your Niche', c),
        if (externalTrends.isEmpty)
          _buildEmptySection('No trending data found', c)
        else
          ...externalTrends.take(5).map((t) => _buildVideoCardItem(t, c, isChannelVideo: false)).toList(),
        const SizedBox(height: 24),

        // ── SECTION 4: Smart Opportunities ─────────────────────────
        _sectionLabel('💡 SECTION 4: Smart Content Opportunities', c),
        if (smartTopics.isEmpty)
          _buildEmptySection('No smart topics generated', c)
        else
          ...smartTopics.map((t) => _buildSmartTopicCard(t, c)).toList(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _sectionLabel(String title, AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 4, height: 20, margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(2))),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _buildNicheCard(Map<dynamic, dynamic> niche, AppColors c) {
    final conf = niche['confidence'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withOpacity(0.3)),
        gradient: LinearGradient(colors: [c.primary.withOpacity(0.05), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(niche['primary'] ?? 'Unknown', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c.textPrimary)),
                const SizedBox(height: 4),
                Text(niche['secondary'] ?? '', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                if ((niche['keywords'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: (niche['keywords'] as List).map((k) => Chip(
                      label: Text(k.toString(), style: TextStyle(fontSize: 11, color: c.primary)),
                      backgroundColor: c.primary.withOpacity(0.08),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            children: [
              SizedBox(
                width: 72, height: 72,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(value: conf / 100, backgroundColor: c.border, color: c.primary, strokeWidth: 7),
                  Text('$conf%', style: TextStyle(fontWeight: FontWeight.bold, color: c.textPrimary, fontSize: 15)),
                ]),
              ),
              const SizedBox(height: 6),
              Text('Confidence', style: TextStyle(fontSize: 11, color: c.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCardItem(dynamic v, AppColors c, {required bool isChannelVideo}) {
    // Ensure source field is set for channel videos
    final videoData = Map<String, dynamic>.from(v);
    if (isChannelVideo && (videoData['source'] == null || videoData['source'] == '')) {
      videoData['source'] = 'YouTube';
    }
    final videoId = videoData['videoId'] as String?;

    return VideoCard(
      video: videoData,
      isCompact: true,
      onViewScript: videoId != null
          ? () {
              TranscriptModal.show(
                context,
                videoId: videoId,
                videoTitle: videoData['title'] ?? '',
              );
            }
          : null,
      onGenerateScript: () {
        Navigator.of(context, rootNavigator: true).pushNamed(
          '/ai/script_workshop',
          arguments: {
            'topic': videoData['title'] ?? 'Viral Script',
            'sourceDetails': videoData,
            'platform': _selectedPlatform,
            'selectedVideos': [videoData],
            'sourceTranscripts': [],
          },
        );
      },
    );
  }

  Widget _buildSmartTopicCard(dynamic topic, AppColors c) {
    final score = (topic['trendScore'] ?? 0) as num;
    final scoreInt = score.toInt();
    final scoreClr = _scoreColor(scoreInt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withOpacity(0.15)),
        gradient: LinearGradient(colors: [c.primary.withOpacity(0.04), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: c.primary.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(topic['title'] ?? '', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.textPrimary, height: 1.3))),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: scoreClr.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Text('$scoreInt', style: TextStyle(fontWeight: FontWeight.w900, color: scoreClr, fontSize: 18)),
              Text('/ 100', style: TextStyle(fontSize: 9, color: scoreClr.withOpacity(0.7))),
            ]),
          ),
        ]),
        if (topic['hook']?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.withOpacity(0.2))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.flash_on, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text('"${topic['hook']}"', style: TextStyle(fontStyle: FontStyle.italic, color: c.textPrimary, fontSize: 13))),
            ]),
          ),
        ],
        if (topic['whyTrending']?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber.shade600),
            const SizedBox(width: 6),
            Expanded(child: Text(topic['whyTrending'], style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.4))),
          ]),
        ],
        if (topic['sourceRef']?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text('📌 Based on: "${topic['sourceRef']}"', style: TextStyle(fontSize: 11, color: c.textSecondary, fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/ai/script_workshop', arguments: {
                'topic': topic['title'],
                'sourceDetails': {'source': 'Master AI', 'reason': topic['whyTrending'], 'hook': topic['hook']},
                'platform': _selectedPlatform,
                'selectedVideos': [],
                'sourceTranscripts': [],
              });
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Generate Script', style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptySection(String msg, AppColors c) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
        child: Text(msg, style: TextStyle(color: c.textSecondary))),
  );

  Color _scoreColor(int score) => score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
}

