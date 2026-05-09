import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final String name = user?['name'] ?? 'Creator';
    final String email = user?['email'] ?? '';
    final String? photoUrl = user?['profilePicture'];
    final String phone = user?['phone'] ?? '';
    final String bio = user?['bio'] ?? '';
    final int creatorScore = user?['creatorScore'] ?? 0;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // ── Avatar + info ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: photoUrl == null
                      ? (c.primaryGradient ??
                          LinearGradient(colors: [c.primary, c.accent]))
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withOpacity(0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _FallbackAvatar(name: name),
                        ),
                      )
                    : _FallbackAvatar(name: name),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 12, color: c.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: c.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '⭐ $creatorScore pts',
                            style: TextStyle(
                              color: c.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Text(
                bio,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Edit Profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              icon: Icon(Icons.edit_outlined, size: 16, color: c.primary),
              label: Text(
                'Edit Profile',
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Divider(color: c.border),
          const SizedBox(height: 8),

          _SectionLabel(label: 'APPEARANCE', color: c.textSecondary),
          const SizedBox(height: 12),
          _ThemeSwitcher(themeProvider: themeProvider, c: c),

          const SizedBox(height: 24),
          Divider(color: c.border),
          const SizedBox(height: 8),

          _SectionLabel(label: 'ACCOUNT', color: c.textSecondary),
          const SizedBox(height: 4),
          _MenuTile(
            icon: Icons.link_outlined,
            label: 'Connected Platforms',
            color: c.primary,
            c: c,
            onTap: () => Navigator.pop(context),
          ),
          _MenuTile(
            icon: Icons.workspace_premium_outlined,
            label: 'Subscription & Plans',
            color: c.accent,
            c: c,
            onTap: () {},
          ),

          const SizedBox(height: 8),
          Divider(color: c.border),
          const SizedBox(height: 8),

          _SectionLabel(label: 'PREFERENCES', color: c.textSecondary),
          const SizedBox(height: 4),
          _MenuTile(icon: Icons.notifications_outlined, label: 'Notifications',     color: c.primary, c: c, onTap: () {}),
          _MenuTile(icon: Icons.language_outlined,      label: 'Language & Region',  color: c.primary, c: c, onTap: () {}),
          _MenuTile(icon: Icons.privacy_tip_outlined,   label: 'Privacy & Security', color: c.primary, c: c, onTap: () {}),

          const SizedBox(height: 8),
          Divider(color: c.border),
          const SizedBox(height: 8),

          _MenuTile(
            icon: Icons.logout,
            label: 'Sign Out',
            color: Colors.redAccent,
            c: c,
            onTap: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String name;
  const _FallbackAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final AppColors c;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.c,
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
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: c.textPrimary),
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: c.textSecondary),
      onTap: onTap,
    );
  }
}

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
          _ThemeOption(icon: Icons.wb_sunny_outlined,  label: 'Light', selected: mode == AppMode.light, selectedColor: const Color(0xFFFF6B00), onTap: () => themeProvider.setLight()),
          _ThemeOption(icon: Icons.nights_stay_outlined, label: 'Dark', selected: mode == AppMode.dark,  selectedColor: const Color(0xFFFF6B00), onTap: () => themeProvider.setDark()),
          _ThemeOption(icon: Icons.auto_awesome,         label: 'AI',   selected: mode == AppMode.ai,   selectedColor: const Color(0xFF7C3AED), onTap: () => themeProvider.setAI()),
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
  const _ThemeOption({required this.icon, required this.label, required this.selected, required this.selectedColor, required this.onTap});

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
            boxShadow: selected ? [BoxShadow(color: selectedColor.withOpacity(0.4), blurRadius: 12)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
