import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../utils/app_colors.dart';

class AIScriptScreen extends StatefulWidget {
  final Map<String, dynamic> arguments;
  const AIScriptScreen({super.key, required this.arguments});

  @override
  State<AIScriptScreen> createState() => _AIScriptScreenState();
}

class _AIScriptScreenState extends State<AIScriptScreen>
    with TickerProviderStateMixin {
  // ── Core data ───────────────────────────────────────────────────────
  late String _topic;
  late Map<String, dynamic> _sourceDetails;
  late String _platform;
  late List<Map<String, dynamic>> _selectedVideos;
  late List<Map<String, dynamic>> _sourceTranscripts;

  // ── Wizard state ─────────────────────────────────────────────────────
  String _contentType = 'Shorts';
  String _styleMode = 'Viral';
  String _scriptLength = 'Medium';
  String _purpose = 'Viral Growth';
  String _language = 'English';

  // ── Generation state ─────────────────────────────────────────────────
  bool _isGenerating = false;
  bool _hasGenerated = false;
  String? _error;

  // ── Script editors ───────────────────────────────────────────────────
  final _hookController = TextEditingController();
  final _bodyController = TextEditingController();
  final _ctaController = TextEditingController();
  String _aiRating = '0.0';
  String _estimatedDuration = '';
  List<String> _hashtags = [];

  // ── Telugu ───────────────────────────────────────────────────────────
  Map<String, dynamic>? _teluguVersion;
  bool _showTelugu = false;
  late TabController _langTabController;

  // ── Section being AI-modified ─────────────────────────────────────────
  String? _modifying;
  String? _provenance;

  // ── Constants ────────────────────────────────────────────────────────
  static const _contentTypes = ['Reel', 'Shorts', 'Long Video'];
  static const _styleModes = ['Viral', 'Storytelling', 'Educational', 'Cinematic'];
  static const _lengths = ['Short', 'Medium', 'Full Detailed'];
  static const _purposes = ['Entertainment', 'Knowledge', 'Summary', 'Viral Growth'];
  static const _languages = ['English', 'Telugu'];

  static const _styleIcons = {
    'Viral': Icons.flash_on,
    'Viral Shorts': Icons.flash_on,
    'Storytelling': Icons.auto_stories,
    'Educational': Icons.school,
    'Cinematic': Icons.movie,
  };
  static const _styleColors = <String, Color>{
    'Viral': Colors.orange,
    'Viral Shorts': Colors.orange,
    'Storytelling': Colors.purple,
    'Educational': Colors.blue,
    'Cinematic': Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    _topic = widget.arguments['topic'] ?? '';
    _sourceDetails =
        Map<String, dynamic>.from(widget.arguments['sourceDetails'] ?? {});
    _platform = widget.arguments['platform'] ?? 'YouTube';
    _selectedVideos = (widget.arguments['selectedVideos'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
    _sourceTranscripts = (widget.arguments['sourceTranscripts'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
    _langTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _langTabController.dispose();
    _hookController.dispose();
    _bodyController.dispose();
    _ctaController.dispose();
    super.dispose();
  }

  // ── Generate Script ───────────────────────────────────────────────────
  Future<void> _generateScript() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/ai/my-ai/generate-script'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': _topic,
          'platform': _platform,
          'styleMode': _styleMode,
          'contentType': _contentType,
          'scriptLength': _scriptLength,
          'purpose': _purpose,
          'language': _language,
          'sourceContext': _sourceDetails,
          'sourceTranscripts': _sourceTranscripts,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final script = data['scriptPackage'] ?? {};
        setState(() {
          _hookController.text = script['hook'] ?? '';
          final content = script['mainContent'];
          _bodyController.text = content is List
              ? content.join('\n\n')
              : content?.toString() ?? '';
          _ctaController.text = script['callToAction'] ?? '';
          _aiRating = script['aiRating']?.toString() ?? '0.0';
          _estimatedDuration = script['estimatedDuration'] ?? '';
          _hashtags = List<String>.from(script['hashtags'] ?? []);
          _teluguVersion = script['teluguVersion'] != null
              ? Map<String, dynamic>.from(script['teluguVersion'])
              : null;
          _provenance = script['provenance']?.toString();
          _hasGenerated = true;
          _showTelugu = false;
        });
      } else {
        final err = jsonDecode(response.body);
        setState(() => _error = err['error'] ?? 'Failed to generate script.');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Is the backend running?');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  // ── Modify a section ──────────────────────────────────────────────────
  Future<void> _modifySection(
      String key, TextEditingController ctrl, String action) async {
    setState(() => _modifying = key);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/ai/my-ai/modify-script'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'section': key,
          'currentText': ctrl.text,
          'action': action,
          'topic': _topic,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ctrl.text = data['improvedText'] ?? ctrl.text;
      }
    } catch (_) {}
    setState(() => _modifying = null);
  }

  // ── Save script ───────────────────────────────────────────────────────
  Future<void> _saveScript() async {
    try {
      await http.post(
        Uri.parse('http://localhost:3000/api/ai/scripts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topicTitle': _topic,
          'sourceDetails': _sourceDetails,
          'hook': _hookController.text,
          'mainContent': _bodyController.text,
          'callToAction': _ctaController.text,
          'trendReason': _sourceDetails['reason'] ?? '',
          'aiRating': double.tryParse(_aiRating) ?? 0.0,
          'language': _language,
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Script saved to library!'),
            backgroundColor: Colors.green));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to save.'), backgroundColor: Colors.red));
      }
    }
  }

  // ── Copy ──────────────────────────────────────────────────────────────
  void _copyAll() {
    final text =
        '${_hookController.text}\n\n${_bodyController.text}\n\n${_ctaController.text}\n\n${_hashtags.join(' ')}';
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('📋 Script copied!')));
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.background,
      appBar: _buildAppBar(c),
      body: _hasGenerated ? _buildWorkspace(c) : _buildSetupPanel(c),
    );
  }

  AppBar _buildAppBar(AppColors c) {
    return AppBar(
      backgroundColor: c.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Script Workshop',
              style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17)),
          Text(_topic,
              style: TextStyle(color: c.textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
      iconTheme: IconThemeData(color: c.textPrimary),
      actions: [
        if (_hasGenerated) ...[
          IconButton(
              icon: Icon(Icons.copy, color: c.textSecondary),
              onPressed: _copyAll,
              tooltip: 'Copy All'),
          TextButton.icon(
            onPressed: _saveScript,
            icon: Icon(Icons.bookmark_add, color: c.primary, size: 18),
            label: Text('Save',
                style: TextStyle(
                    color: c.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SETUP PANEL (5-step wizard)
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildSetupPanel(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section A: Source Context
              _buildSourceContextSection(c),
              const SizedBox(height: 28),

              // Wizard header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.tune, color: c.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Customize Your Script',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary)),
                ],
              ),
              const SizedBox(height: 20),

              // Step 1: Content Type
              _buildWizardStep(
                step: 1,
                label: 'Content Type',
                description: 'What format are you creating?',
                options: _contentTypes,
                selected: _contentType,
                onSelect: (v) => setState(() => _contentType = v),
                getIcon: (v) {
                  if (v == 'Reel') return Icons.play_circle_outline;
                  if (v == 'Shorts') return Icons.bolt;
                  return Icons.video_library_outlined;
                },
                getColor: (v) {
                  if (v == 'Reel') return Colors.pink;
                  if (v == 'Shorts') return Colors.red;
                  return Colors.indigo;
                },
                c: c,
              ),
              const SizedBox(height: 20),

              // Step 2: Style
              _buildWizardStep(
                step: 2,
                label: 'Script Style',
                description: 'How should the script feel?',
                options: _styleModes,
                selected: _styleMode,
                onSelect: (v) => setState(() => _styleMode = v),
                getIcon: (v) => _styleIcons[v] ?? Icons.edit,
                getColor: (v) => _styleColors[v] ?? c.primary,
                c: c,
              ),
              const SizedBox(height: 20),

              // Step 3: Length
              _buildWizardStep(
                step: 3,
                label: 'Script Length',
                description: 'How long should the script be?',
                options: _lengths,
                selected: _scriptLength,
                onSelect: (v) => setState(() => _scriptLength = v),
                getIcon: (v) {
                  if (v == 'Short') return Icons.compress;
                  if (v == 'Medium') return Icons.remove;
                  return Icons.expand;
                },
                getColor: (v) {
                  if (v == 'Short') return Colors.green;
                  if (v == 'Medium') return Colors.orange;
                  return Colors.purple;
                },
                c: c,
              ),
              const SizedBox(height: 20),

              // Step 4: Purpose
              _buildWizardStep(
                step: 4,
                label: 'Purpose',
                description: 'What is the goal of this video?',
                options: _purposes,
                selected: _purpose,
                onSelect: (v) => setState(() => _purpose = v),
                getIcon: (v) {
                  if (v == 'Entertainment') return Icons.celebration;
                  if (v == 'Knowledge') return Icons.lightbulb_outline;
                  if (v == 'Summary') return Icons.summarize;
                  return Icons.trending_up;
                },
                getColor: (v) {
                  if (v == 'Entertainment') return Colors.pink;
                  if (v == 'Knowledge') return Colors.amber;
                  if (v == 'Summary') return Colors.cyan;
                  return Colors.green;
                },
                c: c,
              ),
              const SizedBox(height: 20),

              // Step 5: Language
              _buildLanguageStep(c),
              const SizedBox(height: 28),

              // Error
              if (_error != null)
                Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red))),
                    ])),

              // Generate button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isGenerating ? null : _generateScript,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                      _isGenerating
                          ? 'Writing your viral script...'
                          : 'Generate $_styleMode Script  →',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section A: Source Context ──────────────────────────────────────────
  Widget _buildSourceContextSection(AppColors c) {
    final hasVideos = _selectedVideos.isNotEmpty;
    final thumbnail = _sourceDetails['thumbnail']?.toString();
    final source = _sourceDetails['source']?.toString() ?? 'AI';
    final views = (_sourceDetails['viewsFormatted'] ?? _sourceDetails['views'] ?? '').toString();
    final ago = (_sourceDetails['timeAgo'] ?? '').toString();
    final url = _sourceDetails['url']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.video_collection_outlined,
                  color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Source Context',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary)),
                  Text(
                    hasVideos
                        ? 'Based on ${_selectedVideos.length} trending video${_selectedVideos.length > 1 ? 's' : ''}'
                        : 'Single video source',
                    style:
                        TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Selected videos strip (if multiple)
        if (hasVideos && _selectedVideos.length > 1)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedVideos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final v = _selectedVideos[index];
                final thumb = v['thumbnail']?.toString();
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: thumb != null
                      ? Stack(
                          children: [
                            Image.network(thumb,
                                width: 130,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _thumbPlaceholder(c)),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                color: Colors.black.withOpacity(0.6),
                                child: Text(
                                  v['title']?.toString() ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _thumbPlaceholder(c),
                );
              },
            ),
          ),
        const SizedBox(height: 12),

        // Single source card - Redesigned to Horizontal Layout
        Container(
          decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Small Thumbnail Box
              if (thumbnail != null && _selectedVideos.length <= 1)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(thumbnail,
                        width: 140,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbPlaceholder(c)),
                  ),
                )
              else if (_selectedVideos.length <= 1)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _thumbPlaceholder(c),
                  ),
                ),

              // Right: Content Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _chip(source, Colors.blue, c),
                          const Spacer(),
                          if (url != null)
                            IconButton(
                              icon: Icon(Icons.open_in_new, size: 16, color: c.primary),
                              onPressed: () async {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_topic,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                              height: 1.2)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (views.isNotEmpty)
                            _miniStat('👁 $views', c),
                          if (ago.isNotEmpty)
                            _miniStat('🕐 $ago', c),
                          if (_sourceTranscripts.isNotEmpty)
                            _miniStat('📄 ${_sourceTranscripts.length} Scripts', c),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.border),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: c.textSecondary)),
    );
  }


  // ── Wizard Step builder ───────────────────────────────────────────────
  Widget _buildWizardStep({
    required int step,
    required String label,
    required String description,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
    required IconData Function(String) getIcon,
    required Color Function(String) getColor,
    required AppColors c,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary)),
                  Text(description,
                      style: TextStyle(
                          fontSize: 11, color: c.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final sel = selected == opt;
              final color = getColor(opt);
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.12) : c.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? color : c.border,
                        width: sel ? 2 : 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(getIcon(opt),
                          size: 16,
                          color: sel ? color : c.textSecondary),
                      const SizedBox(width: 8),
                      Text(opt,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  sel ? color : c.textSecondary,
                              fontSize: 13)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Language Step ─────────────────────────────────────────────────────
  Widget _buildLanguageStep(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: c.primary, shape: BoxShape.circle),
                child: const Text('5',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Language',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary)),
                  Text('Script language output',
                      style:
                          TextStyle(fontSize: 11, color: c.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: _languages.map((lang) {
              final sel = _language == lang;
              final isTelugu = lang == 'Telugu';
              final color = isTelugu ? Colors.deepOrange : Colors.blue;
              return GestureDetector(
                onTap: () => setState(() => _language = lang),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.12) : c.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? color : c.border,
                        width: sel ? 2 : 1),
                  ),
                  child: Column(
                    children: [
                      Text(isTelugu ? '🇮🇳' : '🇺🇸',
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(lang,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sel ? color : c.textSecondary,
                              fontSize: 13)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_language == 'Telugu') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.deepOrange.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.deepOrange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Script will be generated in English first, then adapted to natural, conversational Telugu. Both versions will be available.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepOrange.shade700,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // WORKSPACE (after generating)
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildWorkspace(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section A: Source videos strip
          if (_selectedVideos.isNotEmpty) _buildWorkspaceSourceStrip(c),

          // Rating + badges row
          _buildRatingRow(c),
          const SizedBox(height: 20),

          // ── Telugu language tab bar ───────────────────────────────
          if (_language == 'Telugu' && _teluguVersion != null)
            _buildLanguageTabs(c),

          // Hook
          _buildScriptSection(
            label: '⚡ HOOK',
            subtitle: 'First 3 seconds — create curiosity or shock',
            controller: _hookController,
            accentColor: Colors.orange,
            c: c,
            actions: [
              _actionBtn('Improve Hook', Icons.flash_on, Colors.orange,
                  _hookController, c),
              _actionBtn('Add Emotion', Icons.favorite, Colors.pink,
                  _hookController, c),
            ],
            minLines: 2,
          ),
          const SizedBox(height: 16),

          // Body
          _buildScriptSection(
            label: '📝 MAIN SCRIPT',
            subtitle: 'Short punchy sentences. Story arc. Fast pace.',
            controller: _bodyController,
            accentColor: c.primary,
            c: c,
            actions: [
              _actionBtn('Make More Viral', Icons.trending_up, Colors.red,
                  _bodyController, c),
              _actionBtn('Shorten', Icons.compress, Colors.blue,
                  _bodyController, c),
              _actionBtn('Add Emotion', Icons.favorite, Colors.pink,
                  _bodyController, c),
            ],
            minLines: 6,
          ),
          const SizedBox(height: 16),

          // CTA
          _buildScriptSection(
            label: '🎯 CALL TO ACTION',
            subtitle: 'Specific, urgent — never generic',
            controller: _ctaController,
            accentColor: Colors.green,
            c: c,
            actions: [
              _actionBtn('Make More Viral', Icons.trending_up, Colors.red,
                  _ctaController, c),
              _actionBtn('Improve Hook', Icons.flash_on, Colors.orange,
                  _ctaController, c),
            ],
            minLines: 2,
          ),
          const SizedBox(height: 16),

          // Hashtags
          if (_hashtags.isNotEmpty) _buildHashtags(c),
          const SizedBox(height: 16),

          // Action buttons
          _buildWorkspaceActions(c),
          
          if (_provenance != null) ...[
            const SizedBox(height: 24),
            _buildProvenanceCard(c),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWorkspaceSourceStrip(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.video_collection_outlined,
                  size: 14, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                'Based on ${_selectedVideos.length} trending video${_selectedVideos.length > 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedVideos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final v = _selectedVideos[i];
                final thumb = v['thumbnail'] as String?;
                final url = v['url'] as String?;
                return GestureDetector(
                  onTap: url != null
                      ? () async {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        }
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumb != null
                        ? Image.network(thumb,
                            width: 110,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _thumbPlaceholder(c))
                        : _thumbPlaceholder(c),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvenanceCard(AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Text(
                'WHY THIS WORKS (AI STRATEGY)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber.shade800,
                    letterSpacing: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _provenance ?? 'Analyzing source viral patterns...',
            style: TextStyle(
                fontSize: 14,
                color: c.textPrimary,
                height: 1.6,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(AppColors c) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text('AI Rating: $_aiRating / 10',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.amber)),
          ]),
        ),
        const SizedBox(width: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color:
                  (_styleColors[_styleMode] ?? c.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_styleIcons[_styleMode] ?? Icons.edit,
                color: _styleColors[_styleMode] ?? c.primary, size: 14),
            const SizedBox(width: 4),
            Text(_styleMode,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _styleColors[_styleMode] ?? c.primary,
                    fontSize: 12)),
          ]),
        ),
        if (_estimatedDuration.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_outlined,
                  color: Colors.green, size: 14),
              const SizedBox(width: 4),
              Text(_estimatedDuration,
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ]),
          ),
        ],
        const Spacer(),
        TextButton.icon(
          onPressed: () => setState(() {
            _hasGenerated = false;
          }),
          icon: Icon(Icons.tune, size: 16, color: c.textSecondary),
          label: Text('Edit Settings',
              style: TextStyle(color: c.textSecondary, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildLanguageTabs(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _langTab('🇺🇸 English', !_showTelugu, c),
                const SizedBox(width: 4),
                _langTab('🇮🇳 Telugu', _showTelugu, c),
              ],
            ),
          ),
          if (_showTelugu && _teluguVersion != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.deepOrange.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TELUGU VERSION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    if (_teluguVersion!['hook'] != null)
                      _teluguBlock('⚡ Hook', _teluguVersion!['hook'], c),
                    if (_teluguVersion!['mainContent'] != null)
                      _teluguBlock(
                          '📝 Script',
                          (_teluguVersion!['mainContent'] is List)
                              ? (_teluguVersion!['mainContent'] as List)
                                  .join('\n\n')
                              : _teluguVersion!['mainContent'].toString(),
                          c),
                    if (_teluguVersion!['callToAction'] != null)
                      _teluguBlock(
                          '🎯 CTA', _teluguVersion!['callToAction'], c),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _langTab(String label, bool selected, AppColors c) {
    return GestureDetector(
      onTap: () => setState(() => _showTelugu = label.contains('Telugu')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? c.primary : c.textSecondary,
                fontSize: 13)),
      ),
    );
  }

  Widget _teluguBlock(String label, String text, AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange)),
          const SizedBox(height: 4),
          Text(text,
              style: TextStyle(
                  color: c.textPrimary, height: 1.6, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildScriptSection({
    required String label,
    required String subtitle,
    required TextEditingController controller,
    required Color accentColor,
    required AppColors c,
    required List<Widget> actions,
    int minLines = 3,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16)),
              border: Border(
                  bottom:
                      BorderSide(color: accentColor.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            letterSpacing: 0.5)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 10, color: c.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          // Editable text area
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller,
              maxLines: null,
              minLines: minLines,
              style: TextStyle(
                  color: c.textPrimary, height: 1.7, fontSize: 14),
              decoration: InputDecoration(
                hintText: '${label.toLowerCase()} will appear here...',
                hintStyle:
                    TextStyle(color: c.textSecondary.withOpacity(0.4)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(spacing: 8, runSpacing: 6, children: actions),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtags(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('# HASHTAGS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: c.textSecondary,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _hashtags
                .map((h) => Chip(
                      label: Text(h,
                          style: TextStyle(
                              color: c.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      backgroundColor: c.primary.withOpacity(0.08),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceActions(AppColors c) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyAll,
            icon: Icon(Icons.copy, size: 16, color: c.textSecondary),
            label: Text('Copy All',
                style: TextStyle(
                    color: c.textSecondary, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _saveScript,
            icon: const Icon(Icons.bookmark_add, size: 16),
            label: const Text('Save Script',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () => setState(() => _hasGenerated = false),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Regenerate',
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.grey.shade700,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color,
      TextEditingController ctrl, AppColors c) {
    final isLoading = _modifying == label;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: isLoading ? null : () => _modifySection(label, ctrl, label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isLoading
              ? color.withOpacity(0.18)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color))
            else
              Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _thumbPlaceholder(AppColors c) {
    return Container(
      width: 110,
      height: 72,
      decoration: BoxDecoration(
          color: c.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child:
          Icon(Icons.video_library, color: c.primary.withOpacity(0.4), size: 24),
    );
  }
}
