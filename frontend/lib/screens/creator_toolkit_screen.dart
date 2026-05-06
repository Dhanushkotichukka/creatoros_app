import 'dart:async';
import 'package:flutter/material.dart';
import 'multi_post_hub_screen.dart';

class CreatorToolkitScreen extends StatefulWidget {
  const CreatorToolkitScreen({super.key});

  @override
  State<CreatorToolkitScreen> createState() => _CreatorToolkitScreenState();
}

class _CreatorToolkitScreenState extends State<CreatorToolkitScreen> {
  bool _focusActive = false;
  int _focusSeconds = 0;
  Timer? _focusTimer;

  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }

  void _toggleFocus() {
    setState(() {
      if (_focusActive) {
        _focusActive = false;
        _focusSeconds = 0;
        _focusTimer?.cancel();
      } else {
        _focusActive = true;
        _focusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => _focusSeconds++);
        });
      }
    });
  }

  String get _focusTime {
    final m = _focusSeconds ~/ 60;
    final s = _focusSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Toolkit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: QuickTimerCard()),
                const SizedBox(width: 12),
                Expanded(child: FocusModeCard(
                  isActive: _focusActive,
                  timeStr: _focusTime,
                  onToggle: _toggleFocus,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: StatsSnapshotCard()),
                const SizedBox(width: 12),
                const Expanded(child: PublishCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK TIMER CARD (Pomodoro)
// ─────────────────────────────────────────────────────────────────────────────
class QuickTimerCard extends StatefulWidget {
  const QuickTimerCard({super.key});

  @override
  State<QuickTimerCard> createState() => _QuickTimerCardState();
}

class _QuickTimerCardState extends State<QuickTimerCard>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 25 * 60;
  int _secondsLeft = _totalSeconds;
  bool _running = false;
  Timer? _timer;
  int _sessionCount = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_running) {
        _running = false;
        _timer?.cancel();
      } else {
        _running = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_secondsLeft <= 0) {
            _timer?.cancel();
            setState(() {
              _running = false;
              _sessionCount++;
              _secondsLeft = _totalSeconds;
            });
          } else {
            setState(() => _secondsLeft--);
          }
        });
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _secondsLeft = _totalSeconds;
    });
  }

  String get _timeStr {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1 - (_secondsLeft / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFF6B00);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_rounded, color: primaryColor, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Pomodoro',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              if (_sessionCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_sessionCount 🍅',
                    style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Circular Progress
          Center(
            child: ScaleTransition(
              scale: _running ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 6,
                      backgroundColor: primaryColor.withOpacity(0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    Text(
                      _timeStr,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timerBtn(
                icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: primaryColor,
                onTap: _toggle,
                label: _running ? 'Pause' : 'Start',
                theme: theme,
              ),
              const SizedBox(width: 10),
              _timerBtn(
                icon: Icons.replay_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                onTap: _reset,
                label: 'Reset',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timerBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS SNAPSHOT CARD
// ─────────────────────────────────────────────────────────────────────────────
class StatsSnapshotCard extends StatelessWidget {
  const StatsSnapshotCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays + 1;
    final weekday = DateTime.now().weekday;
    final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1).withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Color(0xFF1565C0), size: 18),
              const SizedBox(width: 6),
              const Text(
                'Day Snapshot',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _snapRow(context, '📅', 'Day', dayName),
          const SizedBox(height: 8),
          _snapRow(context, '🗓️', 'Day #', '$dayOfYear of year'),
          const SizedBox(height: 8),
          _snapRow(context, '⏰', 'Time', _formatTime()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFF1565C0), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Keep the streak going!',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF1565C0).withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  Widget _snapRow(BuildContext context, String emoji, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOCUS MODE CARD (2x2 Grid Item)
// ─────────────────────────────────────────────────────────────────────────────
class FocusModeCard extends StatelessWidget {
  final bool isActive;
  final String timeStr;
  final VoidCallback onToggle;
  const FocusModeCard({
    super.key,
    required this.isActive,
    required this.timeStr,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = const Color(0xFF1B5E20);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.12) : color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? color.withOpacity(0.4) : color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.self_improvement_rounded, color: color, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Focus Mode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Icon(
              isActive ? Icons.spa_rounded : Icons.spa_outlined,
              size: 40,
              color: isActive ? color : color.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              isActive ? timeStr : 'Stay in the zone',
              style: TextStyle(
                fontSize: isActive ? 18 : 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? color : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton(
              onPressed: onToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? color : color.withOpacity(0.1),
                foregroundColor: isActive ? Colors.white : color,
                elevation: 0,
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isActive ? 'End Session' : 'Start Focus', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLISH CARD (2x2 Grid Item)
// ─────────────────────────────────────────────────────────────────────────────
class PublishCard extends StatelessWidget {
  const PublishCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = const Color(0xFFBF360C);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: color, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Publish',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Icon(
              Icons.send_rounded,
              size: 40,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Multi-post everywhere',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiPostHubScreen())),
              icon: const Icon(Icons.bolt_rounded, size: 16),
              label: const Text('Post Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
