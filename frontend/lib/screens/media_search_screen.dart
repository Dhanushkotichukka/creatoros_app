import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'video_editor_screen.dart';

const _orange = Color(0xFFFF6B00);
const _pexels = Color(0xFF05A081);
const _pixabay = Color(0xFF2EC66E);

class MediaSearchScreen extends StatefulWidget {
  const MediaSearchScreen({super.key});
  @override
  State<MediaSearchScreen> createState() => _MediaSearchScreenState();
}

class _MediaSearchScreenState extends State<MediaSearchScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  late final AnimationController _shimmer;

  List<dynamic> _results = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasError = false;
  bool _hasMore = true;
  String _type = 'image';
  int _page = 1;
  String _lastQuery = '';

  // Download queue — each entry: {id, name, dest, status: 'loading'|'done'|'error', msg}
  final List<Map<String, dynamic>> _dlQueue = [];
  int _dlIdCounter = 0;


  static const _types = [
    ('image', Icons.image_rounded, 'Images'),
    ('video', Icons.videocam_rounded, 'Videos'),
    ('all', Icons.auto_awesome_rounded, 'All'),
  ];

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
          !_loadingMore && _hasMore && _lastQuery.isNotEmpty) _loadMore();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _hasError = false; _results = []; _page = 1; _hasMore = true; _lastQuery = q; });
    try {
      final data = await ApiService.searchMedia(q, type: _type, page: 1, perPage: 18);
      final hits = List<dynamic>.from(data['results'] ?? []);
      setState(() { _loading = false; _results = hits; _hasMore = hits.length >= 18; });
    } catch (_) {
      setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _loadMore() async {
    setState(() { _loadingMore = true; _page++; });
    try {
      final data = await ApiService.searchMedia(_lastQuery, type: _type, page: _page, perPage: 18);
      final hits = List<dynamic>.from(data['results'] ?? []);
      setState(() { _loadingMore = false; _results.addAll(hits); _hasMore = hits.length >= 18; });
    } catch (_) {
      setState(() { _loadingMore = false; _page--; });
    }
  }

  Color _srcColor(String src) {
    switch (src.toLowerCase()) {
      case 'pexels': return _pexels;
      case 'pixabay': return _pixabay;
      default: return Colors.white;
    }
  }

  String _srcLabel(String src) {
    switch (src.toLowerCase()) {
      case 'pexels': return 'Pexels';
      case 'pixabay': return 'Pixabay';
      default: return 'Unsplash';
    }
  }

  String _mimeType(dynamic item) {
    if ((item['type'] as String?) == 'video') return 'video/mp4';
    return 'image/jpeg';
  }

  String _ext(dynamic item) {
    if ((item['type'] as String?) == 'video') return 'mp4';
    return 'jpg';
  }

  void _showActions(BuildContext context, dynamic item) {
    final url = item['url'] as String? ?? '';
    final thumb = item['thumbnail'] as String? ?? '';
    final src = item['source'] as String? ?? '';
    final author = item['author'] as String? ?? 'Unknown';
    final isVideo = item['type'] == 'video';
    final srcColor = _srcColor(src);
    final fileName = '${_srcLabel(src)}_${item['id']}.${_ext(item)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActionSheet(
        url: url,
        thumb: thumb,
        fileName: fileName,
        author: author,
        isVideo: isVideo,
        srcLabel: _srcLabel(src),
        srcColor: srcColor,
        mimeType: _mimeType(item),
        onSaveLocal: () => _importMedia(url, fileName, 'local', _mimeType(item)),
        onSaveCloud: () => _importMedia(url, fileName, 's3', _mimeType(item)),
        onCopyUrl: () {
          Clipboard.setData(ClipboardData(text: url));
          _snack('URL copied!', Colors.blueAccent);
        },
        onOpenEditor: isVideo ? () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => VideoEditorScreen(videoUrl: url, projectTitle: fileName),
          ));
        } : null,
      ),
    );
  }

  /// Called from action sheet — does NOT pop the sheet
  Future<void> _importMedia(String url, String fileName, String dest, String mime) async {
    final id = _dlIdCounter++;
    final destLabel = dest == 's3' ? 'Cloud ☁' : 'Local 📁';
    setState(() => _dlQueue.insert(0, {
      'id': id, 'name': fileName, 'dest': destLabel,
      'status': 'loading', 'msg': 'Saving to $destLabel…',
    }));
    try {
      await ApiService.importMediaFromUrl(
        url: url, fileName: fileName, destination: dest, mimeType: mime);
      if (mounted) setState(() {
        final i = _dlQueue.indexWhere((e) => e['id'] == id);
        if (i >= 0) _dlQueue[i] = {..._dlQueue[i], 'status': 'done', 'msg': 'Saved to $destLabel ✓'};
      });
    } catch (e) {
      if (mounted) setState(() {
        final i = _dlQueue.indexWhere((e) => e['id'] == id);
        if (i >= 0) _dlQueue[i] = {..._dlQueue[i], 'status': 'error', 'msg': 'Failed: ${e.toString().split(':').last.trim()}'};
      });
    }
    // Auto remove done/error entries after 6s
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _dlQueue.removeWhere((e) => e['id'] == id));
    });
  }


  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(text: const TextSpan(
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          children: [TextSpan(text: 'Smart '), TextSpan(text: 'Media', style: TextStyle(color: _orange))],
        )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white12),
        ),
      ),
      body: Column(children: [
        _buildSearchBar(),
        _buildFilters(),
        if (_dlQueue.isNotEmpty) _buildDownloadBanner(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildDownloadBanner() {
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.download_rounded, color: _orange, size: 14),
            const SizedBox(width: 6),
            Text('Downloads (${_dlQueue.length})', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _dlQueue.clear()),
              child: const Text('Clear all', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 8),
          ..._dlQueue.map((e) {
            final status = e['status'] as String;
            final color = status == 'done' ? Colors.green : status == 'error' ? Colors.redAccent : _orange;
            final icon = status == 'done' ? Icons.check_circle_rounded : status == 'error' ? Icons.error_rounded : Icons.hourglass_top_rounded;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(children: [
                status == 'loading'
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: _orange, strokeWidth: 2))
                    : Icon(icon, color: color, size: 14),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(e['msg'] as String, style: TextStyle(color: color, fontSize: 10)),
                ])),
                if (status != 'loading')
                  GestureDetector(
                    onTap: () => setState(() => _dlQueue.removeWhere((x) => x['id'] == e['id'])),
                    child: const Icon(Icons.close_rounded, color: Colors.white24, size: 14),
                  ),
              ]),
            );
          }),
        ],
      ),
    );
  }


  Widget _buildSearchBar() => Container(
    color: const Color(0xFF0A0A0A),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(children: [
      Expanded(child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: TextField(
          controller: _ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          cursorColor: _orange,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search Unsplash, Pexels, Pixabay…',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white38, size: 20),
            suffixIcon: _ctrl.text.isNotEmpty ? IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
              onPressed: () { _ctrl.clear(); setState(() { _results = []; }); },
            ) : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      )),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: _loading ? null : _search,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _loading ? _orange.withOpacity(0.4) : _orange,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: _orange.withOpacity(0.35), blurRadius: 14)],
          ),
          child: _loading
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    ]),
  );

  Widget _buildFilters() => Container(
    color: const Color(0xFF0A0A0A),
    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
    child: Row(children: _types.map((t) {
      final sel = _type == t.$1;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () { setState(() => _type = t.$1); if (_lastQuery.isNotEmpty) _search(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? _orange : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? _orange : Colors.white12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(t.$2, color: Colors.white, size: 13),
              const SizedBox(width: 5),
              Text(t.$3, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ]),
          ),
        ),
      );
    }).toList()),
  );

  Widget _buildBody() {
    if (_loading) return _buildShimmer();
    if (_hasError) return _buildError();
    if (_results.isEmpty) return _buildEmpty();
    return _buildGrid();
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFF1A1A1A), shape: BoxShape.circle, border: Border.all(color: Colors.white12)),
      child: Icon(Icons.image_search_rounded, color: Colors.white24, size: 38)),
    const SizedBox(height: 18),
    const Text('Discover Stock Media', style: TextStyle(color: Colors.white70, fontSize: 17, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text('Search across 3 platforms at once.\nSave directly to your Local or Cloud storage.',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13, height: 1.6)),
    const SizedBox(height: 24),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (final s in [('Unsplash', Colors.white), ('Pexels', _pexels), ('Pixabay', _pixabay)])
        Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: s.$2.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: s.$2.withOpacity(0.4))),
          child: Text(s.$1, style: TextStyle(color: s.$2, fontSize: 11, fontWeight: FontWeight.bold)),
        )),
    ]),
  ]));

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.wifi_off_rounded, color: Colors.redAccent.withOpacity(0.6), size: 48),
    const SizedBox(height: 16),
    const Text('Search Failed', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text('Could not reach media servers.', style: TextStyle(color: Colors.white.withOpacity(0.4))),
    const SizedBox(height: 20),
    ElevatedButton.icon(
      onPressed: _search,
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: const Text('Retry'),
      style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
  ]));

  Widget _buildGrid() => CustomScrollView(controller: _scroll, slivers: [
    SliverPadding(
      padding: const EdgeInsets.all(10),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _MediaCard(
            item: _results[i],
            srcColor: _srcColor(_results[i]['source'] ?? ''),
            srcLabel: _srcLabel(_results[i]['source'] ?? ''),
            onTap: () => _showActions(ctx, _results[i]),
          ),
          childCount: _results.length,
        ),
      ),
    ),
    if (_loadingMore) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2)))),
    if (!_hasMore && _results.isNotEmpty) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('All results loaded', style: TextStyle(color: Colors.white24, fontSize: 12))))),
    const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
  ]);

  Widget _buildShimmer() => GridView.builder(
    padding: const EdgeInsets.all(10),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72),
    itemCount: 8,
    itemBuilder: (_, __) => AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [const Color(0xFF1A1A1A), const Color(0xFF252525), const Color(0xFF1A1A1A)],
            stops: [0.0, _shimmer.value, 1.0],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
      ),
    ),
  );
}

// ── Media Card ───────────────────────────────────────────────────────────────
class _MediaCard extends StatefulWidget {
  final dynamic item;
  final Color srcColor;
  final String srcLabel;
  final VoidCallback onTap;
  const _MediaCard({required this.item, required this.srcColor, required this.srcLabel, required this.onTap});
  @override
  State<_MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<_MediaCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final thumb = widget.item['thumbnail'] as String? ?? '';
    final isVideo = widget.item['type'] == 'video';
    final tc = widget.srcColor == Colors.white ? Colors.black : Colors.white;

    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _scale, child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFF1A1A1A), border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(fit: StackFit.expand, children: [
          thumb.isNotEmpty
              ? Image.network(thumb, fit: BoxFit.cover,
                  loadingBuilder: (_, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 1.5)),
                  errorBuilder: (_, __, ___) => Center(child: Icon(isVideo ? Icons.videocam_off_rounded : Icons.broken_image_rounded, color: Colors.white24, size: 36)))
              : Center(child: Icon(isVideo ? Icons.videocam_rounded : Icons.image_rounded, color: Colors.white12, size: 40)),

          // Bottom gradient
          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 65, decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.85), Colors.transparent]),
          ))),

          // Video badge
          if (isVideo) Center(child: Container(width: 38, height: 38,
            decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white38)),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22))),

          // Bottom row
          Positioned(bottom: 7, left: 7, right: 7, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: widget.srcColor.withOpacity(0.9), borderRadius: BorderRadius.circular(5)),
              child: Text(widget.srcLabel, style: TextStyle(color: tc, fontSize: 9, fontWeight: FontWeight.bold))),
            Container(padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 12)),
          ])),
        ])),
      )),
    );
  }
}

// ── Action Sheet ─────────────────────────────────────────────────────────────
class _ActionSheet extends StatefulWidget {
  final String url, thumb, fileName, author, srcLabel, mimeType;
  final Color srcColor;
  final bool isVideo;
  final VoidCallback onSaveLocal;
  final VoidCallback onSaveCloud;
  final VoidCallback onCopyUrl;
  final VoidCallback? onOpenEditor;

  const _ActionSheet({
    required this.url, required this.thumb, required this.fileName,
    required this.author, required this.srcLabel, required this.srcColor,
    required this.mimeType, required this.isVideo,
    required this.onSaveLocal, required this.onSaveCloud,
    required this.onCopyUrl, this.onOpenEditor,
  });

  @override
  State<_ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<_ActionSheet> {
  bool _savingLocal = false;
  bool _savingCloud = false;
  String? _localStatus; // null | 'done' | 'error'
  String? _cloudStatus;

  Future<void> _run(bool isCloud) async {
    if (isCloud) {
      setState(() { _savingCloud = true; _cloudStatus = null; });
      try {
        widget.onSaveCloud();
        await Future.delayed(const Duration(milliseconds: 300)); // let queue register
        if (mounted) setState(() { _savingCloud = false; _cloudStatus = 'done'; });
      } catch (_) {
        if (mounted) setState(() { _savingCloud = false; _cloudStatus = 'error'; });
      }
    } else {
      setState(() { _savingLocal = true; _localStatus = null; });
      try {
        widget.onSaveLocal();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) setState(() { _savingLocal = false; _localStatus = 'done'; });
      } catch (_) {
        if (mounted) setState(() { _savingLocal = false; _localStatus = 'error'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = widget.srcColor == Colors.white ? Colors.black : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),

        // Preview row
        Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 72, height: 72,
            child: widget.thumb.isNotEmpty
                ? Image.network(widget.thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF222222), child: const Icon(Icons.image_rounded, color: Colors.white24)))
                : Container(color: const Color(0xFF222222), child: Icon(widget.isVideo ? Icons.videocam_rounded : Icons.image_rounded, color: Colors.white24)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: widget.srcColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: widget.srcColor.withOpacity(0.5))),
                child: Text(widget.srcLabel, style: TextStyle(color: widget.srcColor, fontSize: 10, fontWeight: FontWeight.bold))),
              const SizedBox(width: 6),
              Icon(widget.isVideo ? Icons.videocam_rounded : Icons.image_rounded, color: Colors.white38, size: 13),
            ]),
            const SizedBox(height: 4),
            Text('By ${widget.author}', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
          ])),
        ]),

        const SizedBox(height: 22),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 18),

        // Action buttons — 2x2 grid
        Row(children: [
          Expanded(child: _Btn(
            icon: _localStatus == 'done' ? Icons.check_circle_rounded : _localStatus == 'error' ? Icons.error_rounded : Icons.folder_rounded,
            label: _localStatus == 'done' ? 'Saved! ✓' : _localStatus == 'error' ? 'Failed ✗' : 'Save Local',
            sublabel: 'To device storage',
            color: _localStatus == 'done' ? Colors.green : _localStatus == 'error' ? Colors.redAccent : const Color(0xFF4CAF50),
            loading: _savingLocal,
            onTap: (_savingLocal || _localStatus == 'done') ? () {} : () => _run(false))),
          const SizedBox(width: 10),
          Expanded(child: _Btn(
            icon: _cloudStatus == 'done' ? Icons.check_circle_rounded : _cloudStatus == 'error' ? Icons.error_rounded : Icons.cloud_upload_rounded,
            label: _cloudStatus == 'done' ? 'Uploaded! ✓' : _cloudStatus == 'error' ? 'Failed ✗' : 'Save to Cloud',
            sublabel: 'Upload to S3',
            color: _cloudStatus == 'done' ? Colors.green : _cloudStatus == 'error' ? Colors.redAccent : const Color(0xFF2196F3),
            loading: _savingCloud,
            onTap: (_savingCloud || _cloudStatus == 'done') ? () {} : () => _run(true))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Btn(icon: Icons.copy_rounded, label: 'Copy URL', sublabel: 'Copy media link', color: const Color(0xFFFF9800),
            onTap: () { Navigator.pop(context); widget.onCopyUrl(); })),
          const SizedBox(width: 10),
          Expanded(child: widget.onOpenEditor != null
            ? _Btn(icon: Icons.video_camera_back_rounded, label: 'Open in Editor', sublabel: 'Edit with OpenCut', color: _orange,
                onTap: () { Navigator.pop(context); widget.onOpenEditor!(); })
            : _Btn(icon: Icons.share_rounded, label: 'Share Link', sublabel: 'Copy & share', color: const Color(0xFF9C27B0),
                onTap: () { Navigator.pop(context); widget.onCopyUrl(); })),
        ]),

        const SizedBox(height: 16),

        // Attribution note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text('Photo by ${widget.author} on ${widget.srcLabel}. Attribution required.',
              style: const TextStyle(color: Colors.white38, fontSize: 10))),
          ]),
        ),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color;
  final VoidCallback onTap;
  final bool loading;
  const _Btn({required this.icon, required this.label, required this.sublabel, required this.color, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))),
      child: loading
          ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: color, strokeWidth: 2)))
          : Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(sublabel, style: TextStyle(color: color.withOpacity(0.6), fontSize: 10)),
              ])),
            ]),
    ),
  );
}
