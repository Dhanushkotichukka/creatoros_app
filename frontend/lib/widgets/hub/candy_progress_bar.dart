import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class CandyProgressBar extends StatelessWidget {
  final double value;
  final Duration duration;

  const CandyProgressBar({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    
    final surfaceColor  = c.secondary;
    final primaryAccent = c.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return Container(
          height: 16,
          decoration: BoxDecoration(
            color: surfaceColor, // Background color of bar
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: primaryAccent.withOpacity(0.5), 
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryAccent.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Stack(
                children: [
                  // The filled portion
                  Container(
                    width: maxWidth * animatedValue,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          c.secondary.withOpacity(0.8),
                          primaryAccent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // The "White streak / Glossy shine" like candy/chocolate
                  if (animatedValue > 0)
                    Positioned(
                      top: 2,
                      left: 4,
                      child: Container(
                        height: 6,
                        width: (maxWidth * animatedValue) - 12 > 0 ? (maxWidth * animatedValue) - 12 : 0,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
