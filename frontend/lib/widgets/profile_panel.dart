import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Call this to open the profile panel from any screen.
void showProfilePanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ProfilePanelSheet(),
  );
}

class _ProfilePanelSheet extends StatelessWidget {
  const _ProfilePanelSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    // Colours that adapt
    final sheetBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final handleColor = isDark ? Colors.white24 : Colors.black12;
    final divColor = isDark ? Colors.white12 : const Color(0xFFE5E5E5);
    final subtitleColor = isDark ? const Color(0xFFA0A0B0) : const Color(0xFF6B6B6B);
    final primary = isDark ? const Color(0xFF6C63FF) : const Color(0xFFFF6A3D);
    final orange = const Color(0xFFFF6A3D);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // ── Avatar + name row ──
              Row(
                children: [
                  // Gradient avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFFF6A3D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vasanth Kumar',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'vasanth@creatoros.ai',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFFFF6A3D)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Pro Creator',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              Divider(color: divColor),
              const SizedBox(height: 8),

              // ── Theme Toggle ──────────────────────────────────────
              _SectionLabel(label: 'APPEARANCE', color: subtitleColor),
              const SizedBox(height: 12),
              _ThemeSwitcher(themeProvider: themeProvider, isDark: isDark),

              const SizedBox(height: 24),
              Divider(color: divColor),
              const SizedBox(height: 8),

              // ── Account ──────────────────────────────────────────
              _SectionLabel(label: 'ACCOUNT', color: subtitleColor),
              const SizedBox(height: 4),
              _MenuTile(
                icon: Icons.person_outline,
                label: 'Profile Information',
                color: primary,
                onTap: () {},
              ),
              _MenuTile(
                icon: Icons.link_outlined,
                label: 'Connected Platforms',
                color: primary,
                onTap: () => Navigator.pop(context),
              ),
              _MenuTile(
                icon: Icons.workspace_premium_outlined,
                label: 'Subscription & Plans',
                color: orange,
                onTap: () {},
              ),

              const SizedBox(height: 8),
              Divider(color: divColor),
              const SizedBox(height: 8),

              // ── Preferences ───────────────────────────────────────
              _SectionLabel(label: 'PREFERENCES', color: subtitleColor),
              const SizedBox(height: 4),
              _MenuTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                color: primary,
                onTap: () {},
              ),
              _MenuTile(
                icon: Icons.language_outlined,
                label: 'Language & Region',
                color: primary,
                onTap: () {},
              ),
              _MenuTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy & Security',
                color: primary,
                onTap: () {},
              ),

              const SizedBox(height: 8),
              Divider(color: divColor),
              const SizedBox(height: 8),

              // ── Danger zone ───────────────────────────────────────
              _MenuTile(
                icon: Icons.logout,
                label: 'Sign Out',
                color: Colors.redAccent,
                onTap: () => Navigator.pop(context),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ── Menu tile ─────────────────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1E1E1E),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: isDark ? Colors.white30 : Colors.black26,
      ),
      onTap: onTap,
    );
  }
}

// ── Theme switcher pill ───────────────────────────────────────────────────────
class _ThemeSwitcher extends StatelessWidget {
  final ThemeProvider themeProvider;
  final bool isDark;
  const _ThemeSwitcher({required this.themeProvider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ThemeOption(
            icon: Icons.wb_sunny_outlined,
            label: 'Light',
            selected: !isDark,
            selectedColor: const Color(0xFFFF6A3D),
            onTap: () => themeProvider.setLight(),
          ),
          _ThemeOption(
            icon: Icons.nights_stay_outlined,
            label: 'Dark',
            selected: isDark,
            selectedColor: const Color(0xFF6C63FF),
            onTap: () => themeProvider.setDark(),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
