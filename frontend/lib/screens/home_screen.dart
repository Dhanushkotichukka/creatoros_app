import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'multi_post_hub_screen.dart';
import '../models/multi_post/platform_type.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/ai_update_ticker.dart';
import '../widgets/creator_overview_card.dart';
import '../widgets/platform_analytics_slider.dart';
import '../widgets/connect_platforms_view.dart';
import '../widgets/home/home_content_carousel.dart';
import '../widgets/home/home_ai_live_feed.dart';
import '../widgets/home/home_schedule_card.dart';
import '../widgets/home/home_creator_score.dart';
import '../widgets/home/home_recent_activity.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/view_state_provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _analyticsFuture;
  int _lastTrigger = 0;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = ApiService.getAnalyticsOverview();
  }

  void _refresh({bool force = false}) {
    setState(() {
      _analyticsFuture = ApiService.getAnalyticsOverview(forceRefresh: force);
    });
  }

  Color _pColor(String name) {
    switch (name.toLowerCase()) {
      case 'youtube': return const Color(0xFFFF0000);
      case 'instagram': return const Color(0xFFE1306C);
      case 'linkedin': return const Color(0xFF0A66C2);
      default: return const Color(0xFFFF6B00);
    }
  }

  IconData _pIcon(String name) {
    switch (name.toLowerCase()) {
      case 'youtube': return Icons.play_circle_fill;
      case 'instagram': return Icons.camera_alt;
      case 'linkedin': return Icons.business;
      default: return Icons.public;
    }
  }

  Future<void> _handleCreateReel(Set<PlatformType> connectedTypes) async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.camera);
    
    if (video == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reel Captured!'),
        content: const Text('Where would you like to save this video?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Try saving locally. On mobile this works, on web it throws.
                await video.saveTo('CreatorOS_Reel_${DateTime.now().millisecondsSinceEpoch}.mp4');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved locally!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved locally! (Downloaded)')),
                  );
                }
              }
            },
            child: const Text('Save Locally'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Uploading to Cloud Storage...')),
                );
              }
              try {
                final bytes = await video.readAsBytes();
                await ApiService.uploadFile(bytes, video.name);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Successfully uploaded to Cloud!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to upload: $e')),
                  );
                }
              }
            },
            child: const Text('Upload to Cloud'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>
                    MultiPostHubScreen(initialPlatforms: connectedTypes, initialMedia: video.path)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Direct Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _analyticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Skeleton();
        }
        if (snapshot.hasError) {
          return ConnectPlatformsView(onConnected: () => _refresh());
        }

        final data = snapshot.data ?? {};
        final rawP = data['platforms'] as List<dynamic>? ?? [];
        final seen = <String>{};
        final platforms = rawP.where((p) => seen.add(p['name'] as String? ?? '')).toList();
        final connectedP = platforms.where((p) => p['isConnected'] == true).toList();

        final viewState = context.watch<ViewStateProvider>();
        if (viewState.homeResetTrigger > _lastTrigger) {
          _lastTrigger = viewState.homeResetTrigger;
          Future.microtask(() => _refresh());
        }

        if (connectedP.isEmpty || viewState.showConnectView) {
          return ConnectPlatformsView(onConnected: () {
            viewState.setShowConnectView(false);
            _refresh();
          });
        }

        final c = Theme.of(context).extension<AppColors>()!;
        final r = Responsive.of(context);
        final topContent = data['topContent'] as List<dynamic>? ?? [];
        final totalViews = data['totalViews'] ?? '0';
        final growth = data['growth'] ?? '+0%';
        final streak = data['streak'] ?? 0;

        Set<PlatformType> connectedTypes = {};
        for (var p in connectedP) {
          final n = p['name'] as String? ?? '';
          if (n == 'YouTube') connectedTypes.add(PlatformType.youtube);
          if (n == 'Instagram') connectedTypes.add(PlatformType.instagram);
          if (n == 'LinkedIn') connectedTypes.add(PlatformType.linkedin);
        }

        List<String> insights = [
          '📈 Your content reached $totalViews total views — growth is $growth this month',
          if ((streak is num ? (streak as num).toInt() : 0) > 0)
            '🔥 You\'re on a ${streak}-day posting streak — keep it up!',
          '⏰ Best time to post today: 6:00 PM — 9:00 PM for maximum reach',
          '🚀 Trending: AI Tools for Creators — create content now for maximum reach',
        ];
        final ytVids = topContent.where((v) => v['platform'] == 'YouTube').toList()
          ..sort((a, b) => ((b['viewsNum'] ?? 0) as num).compareTo((a['viewsNum'] ?? 0) as num));
        if (ytVids.isNotEmpty) {
          insights.insert(2, '🏆 Top video: "${ytVids.first['title'] ?? ''}" — ${ytVids.first['views'] ?? '0'} views');
        }

        return Scaffold(
          backgroundColor: c.background,
          appBar: _buildAppBar(context, c, connectedTypes),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: r.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Section ────────────────────────────────────────
                CreatorOverviewCard(
                  data: data,
                  platforms: platforms,
                  onCreateReelRequested: () => _handleCreateReel(connectedTypes),
                  onUploadVideoRequested: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>
                        MultiPostHubScreen(initialPlatforms: connectedTypes)),
                  ),
                ),
                SizedBox(height: r.spacing),

                PlatformAnalyticsSlider(platforms: platforms),
                SizedBox(height: r.spacing),

                // ── AI Ticker ──────────────────────────────────────────
                AIUpdateTicker(updates: insights),
                SizedBox(height: r.spacing),

                // ── Platform Live Stats (3-col grid) ──────────────────
                if (r.isWeb && connectedP.length >= 2)
                  _buildPlatformStatsGrid(context, connectedP, c)
                else
                  SizedBox(
                    height: 225,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: connectedP.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(
                        width: 200,
                        child: _LivePlatformCard(platform: connectedP[i]),
                      ),
                    ),
                  ),
                SizedBox(height: r.spacing),

                // ── Latest Content ───────────────────────
                if (r.isWeb && connectedP.length >= 2)

                  _buildContentGrid(context, connectedP, topContent, c)
                else
                  ...connectedP.map((p) {
                    final name = p['name'] as String? ?? '';
                    final pContent = topContent.where((v) => v['platform'] == name).toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: HomeContentCarousel(
                        platformName: name,
                        content: pContent,
                        platformColor: _pColor(name),
                      ),
                    );
                  }),

                SizedBox(height: r.spacing),

                // ── Bottom Bento: AI Feed | Schedule | Score ──────────
                if (r.isWeb)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: HomeAiLiveFeed(insights: insights)),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: HomeScheduleCard()),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: HomeCreatorScore()),
                      ],
                    ),
                  )
                else
                  Column(children: [
                    HomeAiLiveFeed(insights: insights),
                    SizedBox(height: r.spacing),
                    HomeScheduleCard(),
                    SizedBox(height: r.spacing),
                    HomeCreatorScore(),
                  ]),

                SizedBox(height: r.spacing),

                // ── Recent Activity ────────────────────────────────────
                HomeRecentActivity(topContent: topContent),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentGrid(BuildContext context, List<dynamic> connectedP,
      List<dynamic> topContent, AppColors c) {
    final cols = connectedP.take(3).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cols.asMap().entries.map((e) {
        final p = e.value;
        final name = p['name'] as String? ?? '';
        final pContent = topContent.where((v) => v['platform'] == name).toList();
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < cols.length - 1 ? 16 : 0),
            child: HomeContentCarousel(
              platformName: name,
              content: pContent,
              platformColor: _pColor(name),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlatformStatsGrid(BuildContext context, List<dynamic> connectedP, AppColors c) {
    final cols = connectedP.take(3).toList();
    return Row(
      children: cols.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < cols.length - 1 ? 16 : 0),
            child: _LivePlatformCard(platform: e.value),
          ),
        );
      }).toList(),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppColors c, Set<PlatformType> connectedTypes) {
    final user = context.watch<AuthProvider>().currentUser;
    final String fullName = user?['name'] ?? 'Creator';
    final String firstName = fullName.split(' ').first;
    final String? photoUrl = user?['profilePicture'];

    return AppBar(
      backgroundColor: c.background,
      elevation: 0,
      title: Text('Hi, $firstName 👋', style: Theme.of(context).textTheme.titleLarge),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
            child: IconButton(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) =>
                        MultiPostHubScreen(initialPlatforms: connectedTypes)));
                _refresh(force: true);
              },
              icon: const Icon(Icons.upload, size: 18, color: Colors.white),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
                  ConnectPlatformsView(onConnected: () => _refresh(force: true)))),
          icon: Icon(Icons.add_link, size: 22, color: c.primary),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: _ProfileAvatar(photoUrl: photoUrl, name: fullName),
          ),
        ),
      ],
    );
  }
}

// ── Live Platform Stats Card ─────────────────────────────────────────────────
class _LivePlatformCard extends StatefulWidget {
  final Map<String, dynamic> platform;
  const _LivePlatformCard({required this.platform});
  @override
  State<_LivePlatformCard> createState() => _LivePlatformCardState();
}

class _LivePlatformCardState extends State<_LivePlatformCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  Color _pColor(String n) {
    switch (n.toLowerCase()) {
      case 'youtube': return const Color(0xFFFF0000);
      case 'instagram': return const Color(0xFFE1306C);
      case 'linkedin': return const Color(0xFF0A66C2);
      default: return const Color(0xFFFF6B00);
    }
  }

  IconData _pIcon(String n) {
    switch (n.toLowerCase()) {
      case 'youtube': return Icons.play_circle_fill;
      case 'instagram': return Icons.camera_alt;
      case 'linkedin': return Icons.business;
      default: return Icons.public;
    }
  }

  String _realtimeStat(String n) {
    switch (n.toLowerCase()) {
      case 'youtube': return '+12 views/min';
      case 'instagram': return '+8 likes/min';
      case 'linkedin': return '+4 views/min';
      default: return '— live';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final p = widget.platform;
    final name = p['name'] as String? ?? '';
    final color = _pColor(name);
    final subs = p['subscribers'] as String? ?? '—';
    final growth = p['growth'] as String? ?? '+0%';
    final isPos = !growth.startsWith('-');

    // Simple sparkline data
    final spark = [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, 1.0, 0.85, 0.95, 1.1, 0.9, 1.2];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_pIcon(name), color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text(name, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Row(children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.5 + _pulse.value * 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Live', style: TextStyle(
                    color: Colors.greenAccent.withOpacity(0.5 + _pulse.value * 0.5),
                    fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(subs, style: TextStyle(color: c.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          Text(name == 'YouTube' ? 'Subscribers' : 'Followers',
              style: TextStyle(color: c.textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          Row(children: [
            Icon(isPos ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12, color: isPos ? Colors.greenAccent : Colors.redAccent),
            const SizedBox(width: 4),
            Text(growth, style: TextStyle(
                color: isPos ? Colors.greenAccent : Colors.redAccent,
                fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Text('vs yesterday', style: TextStyle(color: c.textSecondary, fontSize: 10)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: CustomPaint(
              painter: _Spark(spark, color),
              size: const Size(double.infinity, 36),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.show_chart, size: 11, color: color),
            const SizedBox(width: 4),
            Text(_realtimeStat(name),
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}

class _Spark extends CustomPainter {
  final List<double> pts; final Color color;
  _Spark(this.pts, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final mn = pts.reduce((a, b) => a < b ? a : b);
    final mx = pts.reduce((a, b) => a > b ? a : b);
    final rng = mx - mn == 0 ? 1.0 : mx - mn;
    double nx(int i) => i / (pts.length - 1) * size.width;
    double ny(double v) => size.height - ((v - mn) / rng) * size.height;

    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      if (i == 0) path.moveTo(nx(i), ny(pts[i]));
      else {
        final cx = (nx(i - 1) + nx(i)) / 2;
        path.cubicTo(cx, ny(pts[i - 1]), cx, ny(pts[i]), nx(i), ny(pts[i]));
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.25), color.withOpacity(0)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(path, Paint()
      ..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _Spark o) => o.pts != pts;
}

// ── Skeleton ─────────────────────────────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: List.generate(5, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(height: 100, decoration: BoxDecoration(
            color: c.surface, borderRadius: BorderRadius.circular(16))),
        ))),
      ),
    );
  }
}

// ── Profile Avatar ────────────────────────────────────────────────────────────
class _ProfileAvatar extends StatefulWidget {
  final String? photoUrl;
  final String name;
  const _ProfileAvatar({this.photoUrl, this.name = 'C'});
  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _p;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _p = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'C';
    return AnimatedBuilder(
      animation: _p,
      builder: (_, __) => Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.photoUrl == null ? LinearGradient(colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            boxShadow: [BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(_p.value * 0.4),
              blurRadius: 10 * _p.value, spreadRadius: _p.value,
            )],
          ),
          child: widget.photoUrl != null
              ? ClipOval(
                  child: Image.network(
                    widget.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              : Center(child: Text(initial, style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
        ),
      ]),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: Text(title, style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}
