import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

/// Bottom sheet modal that fetches and displays a video transcript.
/// Shows a loading state, then the formatted transcript text.
/// Has a "Use This Transcript for Script" action button.
class TranscriptModal extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final VoidCallback? onUseTranscript;
  final Function(String transcript)? onTranscriptLoaded;

  const TranscriptModal({
    super.key,
    required this.videoId,
    required this.videoTitle,
    this.onUseTranscript,
    this.onTranscriptLoaded,
  });

  static Future<void> show(
    BuildContext context, {
    required String videoId,
    required String videoTitle,
    Function(String transcript)? onTranscriptLoaded,
    VoidCallback? onUseTranscript,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TranscriptModal(
        videoId: videoId,
        videoTitle: videoTitle,
        onUseTranscript: onUseTranscript,
        onTranscriptLoaded: onTranscriptLoaded,
      ),
    );
  }

  @override
  State<TranscriptModal> createState() => _TranscriptModalState();
}

class _TranscriptModalState extends State<TranscriptModal> {
  bool _isLoading = true;
  bool _available = false;
  String? _transcript;
  String? _message;
  int _wordCount = 0;
  String? _language;
  bool _isTranslated = false;
  String? _originalLanguage;
  
  // For manual pasting
  final TextEditingController _pasteController = TextEditingController();
  bool _isPasting = false;

  @override
  void initState() {
    super.initState();
    _fetchTranscript();
  }
  
  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _fetchTranscript() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://creatoros-backend-rb5b.onrender.com/api/ai/my-ai/extract-transcript'),
        headers: ApiService.authHeaders,
        body: jsonEncode({
          'videoId': widget.videoId,
          'title': widget.videoTitle,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _available = data['available'] ?? false;
          _transcript = data['transcript'];
          _message = data['message'];
          _wordCount = data['wordCount'] ?? 0;
          _language = data['language'];
          _isTranslated = data['isTranslated'] ?? false;
          _originalLanguage = data['originalLanguage'];
        });
        if (_available && _transcript != null) {
          widget.onTranscriptLoaded?.call(_transcript!);
        }
      } else {
        setState(() {
          _available = false;
          _message = data['error'] ?? 'Failed to fetch transcript.';
        });
      }
    } catch (e) {
      setState(() {
        _available = false;
        _message = 'Network error. Is the backend running?';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.82,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ── Handle ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.article_outlined,
                      color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPasting ? 'Paste Your Own Transcript' : 'Video Script / Transcript',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        widget.videoTitle,
                        style: TextStyle(
                            fontSize: 11, color: c.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: c.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Divider(color: c.border, height: 1),

          // ── Body ─────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildLoading(c)
                : _isPasting 
                    ? _buildPasteArea(c)
                    : _available
                        ? _buildTranscript(c)
                        : _buildNotAvailable(c),
          ),

          // ── Footer ─────────────────────────────
          if ((_available && _transcript != null) || _isPasting)
            _buildFooter(c),
        ],
      ),
    );
  }

  Widget _buildLoading(AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.blue.withOpacity(0.2), strokeWidth: 6),
                CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing video...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Checking for English & Multi-lingual captions',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscript(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _statChip('$_wordCount words', Icons.text_fields, Colors.green),
              const SizedBox(width: 8),
              if (_isTranslated)
                _statChip('AI Translated from ${_originalLanguage?.toUpperCase() ?? 'N/A'}', Icons.translate, Colors.purple)
              else
                _statChip('Detected: ${_language?.toUpperCase() ?? 'EN'}', Icons.closed_caption, Colors.blue),
            ],
          ),
          const SizedBox(height: 16),

          // Divider with label
          Row(
            children: [
              Text(
                'EXTRACTED TRANSCRIPT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: c.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Divider(color: c.border)),
            ],
          ),
          const SizedBox(height: 12),

          // Message if any
          if (_message != null && !_message!.contains('successfully'))
             Container(
               margin: const EdgeInsets.only(bottom: 16),
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
               child: Text(_message!, style: TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic)),
             ),

          // Transcript paragraphs
          ...(_transcript ?? '').split('\n\n').where((p) => p.trim().isNotEmpty).map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                paragraph.trim(),
                style: TextStyle(
                  fontSize: 14,
                  color: c.textPrimary,
                  height: 1.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasteArea(AppColors c) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text('Manually paste contents below. This will be used to analyze viral triggers and hooks.', 
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _pasteController,
                maxLines: null,
                expands: true,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Paste transcript or notes here...',
                  hintStyle: TextStyle(color: c.textSecondary.withOpacity(0.5)),
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotAvailable(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.closed_caption_disabled_outlined,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Transcript Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This video has no manual or auto-generated captions enabled in reachable languages.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                height: 1.6,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            
            // Actions
            Column(
              children: [
                FilledButton.icon(
                  onPressed: () => setState(() => _isPasting = true),
                  icon: const Icon(Icons.paste, size: 16),
                  label: const Text('Paste Script Manually'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary.withOpacity(0.1),
                    foregroundColor: c.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close and use AI fallback', style: TextStyle(color: c.textSecondary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(AppColors c) {
    bool canSubmit = _transcript != null || (_isPasting && _pasteController.text.isNotEmpty);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                if (_isPasting) {
                  setState(() => _isPasting = false);
                } else {
                  Navigator.of(context).pop();
                }
              },
              icon: Icon(_isPasting ? Icons.arrow_back : Icons.close, size: 16, color: c.textSecondary),
              label: Text(_isPasting ? 'Back' : 'Close',
                  style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600)),
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
            flex: 2,
            child: FilledButton.icon(
              onPressed: !canSubmit ? null : () {
                final result = _isPasting ? _pasteController.text : _transcript;
                if (result != null) {
                  widget.onTranscriptLoaded?.call(result);
                  widget.onUseTranscript?.call();
                }
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                _isPasting ? 'Use This Text' : 'Use for Script Generation',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
