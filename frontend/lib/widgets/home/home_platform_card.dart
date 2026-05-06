import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/app_colors.dart';

class HomePlatformCard extends StatefulWidget {
  final Map<String, dynamic> platform;
  final VoidCallback? onTap;

  const HomePlatformCard({super.key, required this.platform, this.onTap});

  @override
  State<HomePlatformCard> createState() => _HomePlatformCardState();
}

class _HomePlatformCardState extends State<HomePlatformCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _platformColor(String name) {
    switch (name.toLowerCase()) {
      case 'youtube': return const Color(0xFFFF0000);
      case 'instagram': return const Color(0xFFE1306C);
      case 'linkedin': return const Color(0xFF0A66C2);
      default: return const Color(0xFFFF6B00);
    }
  }

  IconData _platformIcon(String name) {
    switch (name.toLowerCase()) {
      case 'youtube': return Icons.play_circle_fill;
      case 'instagram': return Icons.camera_alt;
      case 'linkedin': return Icons.business;
      default: return Icons.public;
    }
  }

  String _realtimeStat(String name) {
    switch (name.toLowerCase()) {
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
    final name = p['name'] as String? ?? 'Platform';
    final color = _platformColor(name);
    final subscribers = p['subscribers'] as String? ?? '—';
    final growth = p['growth'] as String? ?? '+0%';
    final isPositive = !growth.startsWith('-');

    // Generate a mock sparkline — real apps pass real data points
    final spark = List.generate(12, (i) =>
        0.3 + math.sin(i * 0.7 + (name.hashCode % 10)) * 0.3 + math.Random(i + name.hashCode).nextDouble() * 0.3);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_platformIcon(name), color: color, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
                // Live badge
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent
                              .withOpacity(_pulseAnim.value),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('Live',
                          style: TextStyle(
                            color:
                                Colors.greenAccent.withOpacity(_pulseAnim.value),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Main metric ─────────────────────────────────────────────
            Text(
              subscribers,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              name == 'YouTube' ? 'Subscribers' : 'Followers',
              style: TextStyle(color: c.textSecondary, fontSize: 11),
            ),

            const SizedBox(height: 8),

            // ── Growth ──────────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  growth,
                  style: TextStyle(
                    color:
                        isPositive ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text('vs yesterday',
                    style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 10)),
              ],
            ),

            const SizedBox(height: 16),

            // ── Sparkline ───────────────────────────────────────────────
            SizedBox(
              height: 40,
              child: CustomPaint(
                painter: _SparklinePainter(points: spark, color: color),
                size: const Size(double.infinity, 40),
              ),
            ),

            const SizedBox(height: 10),

            // ── Realtime stat ───────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.show_chart, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  _realtimeStat(name),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final min = points.reduce(math.min);
    final max = points.reduce(math.max);
    final range = max - min == 0 ? 1.0 : max - min;

    final normalize = (double v) =>
        size.height - ((v - min) / range) * size.height;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final y = normalize(points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) / (points.length - 1) * size.width;
        final prevY = normalize(points[i - 1]);
        final cx = (prevX + x) / 2;
        path.cubicTo(cx, prevY, cx, y, x, y);
      }
    }

    // Gradient fill under line
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points != points || old.color != color;
}
