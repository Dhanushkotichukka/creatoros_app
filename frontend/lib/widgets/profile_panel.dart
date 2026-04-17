import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';

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
    final theme         = Theme.of(context);
    final c             = theme.extension<AppColors>()!;
    final themeProvider = context.watch<ThemeProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
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
                    color: c.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // ── Avatar + name row ──
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: c.primaryGradient ??
                          LinearGradient(
                            colors: [c.primary, c.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withOpacity(0.4),
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
                            color: c.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: c.primaryGradient ??
                                LinearGradient(colors: [c.primary, c.accent]),
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
              Divider(color: c.border),
              const SizedBox(height: 8),

              // ── Theme Toggle ──────────────────────────────────────
              _SectionLabel(label: 'APPEARANCE', color: c.textSecondary),
              const SizedBox(height: 12),
              _ThemeSwitcher(themeProvider: themeProvider, c: c),

              const SizedBox(height: 24),
              Divider(color: c.border),
              const SizedBox(height: 8),

              // ── Account ──────────────────────────────────────────
              _SectionLabel(label: 'ACCOUNT', color: c.textSecondary),
              const SizedBox(height: 4),
              _MenuTile(icon: Icons.person_outline,          label: 'Profile Information',  color: c.primary, textColor: c.textPrimary, chevronColor: c.textSecondary, onTap: () {}),
              _MenuTile(icon: Icons.link_outlined,           label: 'Connected Platforms',  color: c.primary, textColor: c.textPrimary, chevronColor: c.textSecondary, onTap: () => Navigator.pop(context)),
              _MenuTile(icon: Icons.workspace_premium_outlined, label: 'Subscription & Plans', color: c.accent, textColor: c.textPrimary, chevronColor: c.textSecondary, onTap: () {}),

              const SizedBox(height: 8),
              Divider(color: c.border),
              const SizedBox(height: 8),

              // ── Preferences ───────────────────────────────────────
              _SectionLabel(label: 'PREFERENCES', color: c.textSecondary),
              const SizedBox(height: 4),
              _MenuTile(icon: Icons.notifications_outlined, label: 'Notifications',     color: c.primary, textColor: c.textPrimary, chevronColor: c.textSecondary, onTap: () {}),
              _MenuTile(icon: Icons.language_outlined,      label: 'Language & Region', color: c.primary, textColor: c.textPrimary, chevronColor: c.textSecondary, onTap: () {}),
              _MenuTile(icon: Icons.privacy_tip_outlined,   label: 'Privacy & Security', color: c.primary, textColor: c.textPrimary, chevronColor: c.textSecondary, onTap: () {}),

              const SizedBox(height: 8),
              Divider(color: c.border),
              const SizedBox(height: 8),

              // ── Danger zone ───────────────────────────────────────
              _MenuTile(icon: Icons.logout, label: 'Sign Out', color: Colors.redAccent, textColor: c.textPrimary, chevronColor: c.textSecondary, onTap: () => Navigator.pop(context)),

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
  final String   label;
  final Color    color;
  final Color    textColor;
  final Color    chevronColor;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.chevronColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
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
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: textColor),
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: chevronColor),
      onTap: onTap,
    );
  }
}

// ── Theme switcher pill ───────────────────────────────────────────────────────
class _ThemeSwitcher extends StatelessWidget {
  final ThemeProvider themeProvider;
  final AppColors c;
  const _ThemeSwitcher({required this.themeProvider, required this.c});

  @override
  Widget build(BuildContext context) {
    final mode = themeProvider.appMode;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.secondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ThemeOption(
            icon: Icons.wb_sunny_outlined,
            label: 'Light',
            selected: mode == AppMode.light,
            selectedColor: const Color(0xFFFF6B00),
            onTap: () => themeProvider.setLight(),
          ),
          _ThemeOption(
            icon: Icons.nights_stay_outlined,
            label: 'Dark',
            selected: mode == AppMode.dark,
            selectedColor: const Color(0xFFFF6B00),
            onTap: () => themeProvider.setDark(),
          ),
          _ThemeOption(
            icon: Icons.auto_awesome,
            label: 'AI',
            selected: mode == AppMode.ai,
            selectedColor: const Color(0xFF7C3AED),
            onTap: () => themeProvider.setAI(),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData   icon;
  final String     label;
  final bool       selected;
  final Color      selectedColor;
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
                ? [BoxShadow(color: selectedColor.withOpacity(0.4), blurRadius: 12)]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey),
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
