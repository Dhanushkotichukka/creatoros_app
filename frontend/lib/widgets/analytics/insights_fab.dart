import 'package:flutter/material.dart';

/// Premium floating "Insights" button with gradient + glow + pulse animation.
/// Callbacks:
///   [onPressed] – called when the button is tapped
///   [isLoading] – shows a spinner instead of the icon while insights load
class InsightsFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const InsightsFAB({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<InsightsFAB> createState() => _InsightsFABState();
}

class _InsightsFABState extends State<InsightsFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 8.0, end: 20.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AI-mode gradient colours (purple → cyan)
    const Color gradStart = Color(0xFF8B5CF6);
    const Color gradEnd   = Color(0xFF06B6D4);

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isLoading ? 1.0 : _scaleAnim.value,
          child: GestureDetector(
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [gradStart, gradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradStart.withOpacity(0.45),
                    blurRadius: widget.isLoading ? 10 : _glowAnim.value,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: gradEnd.withOpacity(0.25),
                    blurRadius: widget.isLoading ? 6 : _glowAnim.value * 0.6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    widget.isLoading ? 'Analyzing…' : 'AI Insights',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
