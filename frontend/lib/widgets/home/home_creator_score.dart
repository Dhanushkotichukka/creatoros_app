import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/app_colors.dart';

class HomeCreatorScore extends StatefulWidget {
  const HomeCreatorScore({super.key});
  @override
  State<HomeCreatorScore> createState() => _HomeCreatorScoreState();
}

class _HomeCreatorScoreState extends State<HomeCreatorScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    const score = 82;
    const metrics = [
      _ScoreMetric('Consistency', 90, Colors.greenAccent),
      _ScoreMetric('Engagement', 75, Colors.orangeAccent),
      _ScoreMetric('Frequency', 85, Colors.blueAccent),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Creator Score', style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('What is this?', style: TextStyle(color: c.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => SizedBox(
                  width: 90, height: 90,
                  child: CustomPaint(
                    painter: _GaugePainter(score: score.toDouble(), progress: _anim.value, color: c.primary),
                    child: Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${(score * _anim.value).round()}',
                            style: TextStyle(color: c.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                        Text('/100', style: TextStyle(color: c.textSecondary, fontSize: 10)),
                      ],
                    )),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                children: metrics.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Icon(Icons.trending_up, size: 12, color: m.color),
                    const SizedBox(width: 6),
                    Expanded(child: Text(m.label, style: TextStyle(color: c.textSecondary, fontSize: 11))),
                    SizedBox(width: 70, child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: m.value / 100,
                        backgroundColor: c.border,
                        valueColor: AlwaysStoppedAnimation(m.color),
                        minHeight: 5,
                      ),
                    )),
                    const SizedBox(width: 6),
                    Text('${m.value}', style: TextStyle(color: c.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                )).toList(),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text("🎯  Great Job! You're doing better than 82% of creators.",
                style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.trending_up, size: 16),
              label: const Text('Improve Score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreMetric {
  final String label; final int value; final Color color;
  const _ScoreMetric(this.label, this.value, this.color);
}

class _GaugePainter extends CustomPainter {
  final double score, progress; final Color color;
  _GaugePainter({required this.score, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngle, false,
      Paint()..color = color.withOpacity(0.15)..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngle * (score / 100) * progress, false,
      Paint()..color = color..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.progress != progress;
}
