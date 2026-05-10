import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/hub/task_tracker.dart';
import '../widgets/hub/storage_manager.dart';
import 'media_search_screen.dart';
import 'notes_screen.dart';
import 'ai_chat_screen.dart';
import 'content_planner_screen.dart';
import 'multi_post_hub_screen.dart';
import 'creator_toolkit_screen.dart';
import '../utils/responsive.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> with TickerProviderStateMixin {
  late final AnimationController _greetAnim;
  late final Animation<double> _greetFade;

  final PageController _quickActionsController = PageController(viewportFraction: 1.0);
  int _currentQuickActionPage = 0;

  @override
  void initState() {
    super.initState();
    _greetAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _greetFade = CurvedAnimation(parent: _greetAnim, curve: Curves.easeOut);
    _greetAnim.forward();
  }

  @override
  void dispose() {
    _greetAnim.dispose();
    _quickActionsController.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = Responsive.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                children: [
                  const TextSpan(text: 'Multi'),
                  TextSpan(text: 'HUB', style: TextStyle(color: theme.colorScheme.primary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MediaSearchScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  onPressed: () {},
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('3', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: r.contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── GREETING HEADER ─────────────────────────────────────────────
            FadeTransition(
              opacity: _greetFade,
              child: _buildGreetingHeader(theme),
            ),
            const SizedBox(height: 20),

            // ── TODAY'S TASKS ────────────────────────────────────────────────
            const TaskTracker(),
            const SizedBox(height: 28),

            // ── QUICK ACCESS CAROUSEL ────────────────────────────────────────
            _buildQuickActions(context, theme),
            const SizedBox(height: 32),

            // ── STORAGE MANAGER ──────────────────────────────────────────────
            const StorageManager(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.08), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👋', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$_greeting, Creator!',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Let's make today productive and amazing!",
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Creator Score Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_outline_rounded, color: theme.colorScheme.primary, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'Creator Score',
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 13),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Icon(Icons.star_rounded, color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '87',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Great going!',
                  style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    final actions = [
      _QuickAction(
        label: 'Notes',
        subtitle: '12 Notes',
        icon: Icons.description_rounded,
        color: const Color(0xFFFF6B00),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen())),
      ),
      _QuickAction(
        label: 'AI Chat',
        subtitle: '8 Conversations',
        icon: Icons.smart_toy_rounded,
        color: const Color(0xFF9C27B0),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
      ),
      _QuickAction(
        label: 'Content Planner',
        subtitle: '7 Schedules',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF4CAF50),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentPlannerScreen())),
      ),
      _QuickAction(
        label: 'Ideas',
        subtitle: '15 Ideas',
        icon: Icons.lightbulb_rounded,
        color: const Color(0xFFFFC107),
        onTap: () {},
      ),
      _QuickAction(
        label: 'Toolkit',
        subtitle: 'Creator Tools',
        icon: Icons.business_center_rounded,
        color: const Color(0xFF2196F3),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatorToolkitScreen())),
      ),
    ];

    final totalPages = (actions.length / 3).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 6),
                const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.add, size: 12, color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text('Swipe to explore', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Cards carousel
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _quickActionsController,
            padEnds: false,
            itemCount: totalPages,
            onPageChanged: (idx) => setState(() => _currentQuickActionPage = idx),
            itemBuilder: (context, pageIdx) {
              final items = <Widget>[];
              for (int i = 0; i < 3; i++) {
                final actionIdx = pageIdx * 3 + i;
                if (actionIdx < actions.length) {
                  items.add(Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < 2 ? 8.0 : 0,
                      ),
                      child: _BentoActionCard(action: actions[actionIdx], theme: theme),
                    ),
                  ));
                } else {
                  items.add(const Expanded(child: SizedBox()));
                }
              }
              return Row(children: items);
            },
          ),
        ),
        const SizedBox(height: 12),

        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalPages, (i) {
            final isActive = i == _currentQuickActionPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive ? theme.colorScheme.primary : Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _menuTile(Icons.settings_outlined, 'Settings', () => Navigator.pop(context)),
            _menuTile(Icons.download_rounded, 'Export Tasks', () => Navigator.pop(context)),
            _menuTile(Icons.info_outline, 'About MultiHUB', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Data Model
// ─────────────────────────────────────────────────────────
class _QuickAction {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────
// Bento Action Card  (matches screenshot exactly)
// ─────────────────────────────────────────────────────────
class _BentoActionCard extends StatefulWidget {
  final _QuickAction action;
  final ThemeData theme;
  const _BentoActionCard({required this.action, required this.theme});

  @override
  State<_BentoActionCard> createState() => _BentoActionCardState();
}

class _BentoActionCardState extends State<_BentoActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.action.color;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.action.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withOpacity(0.35), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Top glow bloom
                Positioned(
                  top: -30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: c.withOpacity(0.55),
                            blurRadius: 50,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon circle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.action.icon, color: c, size: 22),
                      ),
                      const Spacer(),
                      // Label
                      Text(
                        widget.action.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Bottom row: subtitle + arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.action.subtitle,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: c.withOpacity(0.8), width: 1),
                            ),
                            child: Icon(Icons.arrow_forward_rounded, size: 10, color: c),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
