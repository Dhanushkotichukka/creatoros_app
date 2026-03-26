import 'package:flutter/material.dart';

/// Emoji-based character reflecting channel health.
/// States: Happy (>5% engagement), Neutral (2-5%), Sad (<2%).
class CreatorHealth extends StatelessWidget {
  final double engagementRate;
  final int streakDays;

  const CreatorHealth({
    super.key,
    required this.engagementRate,
    required this.streakDays,
  });

  CreatorHealthState get _state {
    final ratePercent = engagementRate * 100;
    if (ratePercent > 5) return CreatorHealthState.happy;
    if (ratePercent >= 2) return CreatorHealthState.neutral;
    return CreatorHealthState.sad;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: state.backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: state.backgroundColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            state.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$streakDays Day Streak',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              state.message,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum CreatorHealthState {
  happy,
  neutral,
  sad,
}

extension CreatorHealthStateX on CreatorHealthState {
  String get emoji {
    switch (this) {
      case CreatorHealthState.happy:
        return '😊';
      case CreatorHealthState.neutral:
        return '😐';
      case CreatorHealthState.sad:
        return '😟';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case CreatorHealthState.happy:
        return Colors.green.withValues(alpha: 0.2);
      case CreatorHealthState.neutral:
        return Colors.orange.withValues(alpha: 0.2);
      case CreatorHealthState.sad:
        return Colors.red.withValues(alpha: 0.2);
    }
  }

  String get message {
    switch (this) {
      case CreatorHealthState.happy:
        return 'Great engagement! Keep it up.';
      case CreatorHealthState.neutral:
        return 'Engagement is okay. Room to grow.';
      case CreatorHealthState.sad:
        return 'Engagement needs attention.';
    }
  }
}
