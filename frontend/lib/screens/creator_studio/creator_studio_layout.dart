import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

import 'edit_screen.dart';
import 'ai_lab_screen.dart';
import 'projects_screen.dart';
import 'storage_screen.dart';
import 'discover_screen.dart';
import '../profile_screen.dart';

class _StudioNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _StudioNavItem({required this.label, required this.icon, required this.activeIcon});
}

class CreatorStudioLayout extends StatefulWidget {
  const CreatorStudioLayout({super.key});

  @override
  State<CreatorStudioLayout> createState() => _CreatorStudioLayoutState();
}

class _CreatorStudioLayoutState extends State<CreatorStudioLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    EditScreen(),
    AILabScreen(),
    ProjectsScreen(),
    StorageScreen(),
    DiscoverScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    _StudioNavItem(label: 'Edit', icon: Icons.edit_outlined, activeIcon: Icons.edit),
    _StudioNavItem(label: 'AI Lab', icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome),
    _StudioNavItem(label: 'Projects', icon: Icons.movie_creation_outlined, activeIcon: Icons.movie_creation),
    _StudioNavItem(label: 'Storage', icon: Icons.cloud_outlined, activeIcon: Icons.cloud),
    _StudioNavItem(label: 'Discover', icon: Icons.explore_outlined, activeIcon: Icons.explore),
    _StudioNavItem(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  void _onIndexChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return _WebLayout(
            currentIndex: _selectedIndex,
            onTap: _onIndexChanged,
            child: IndexedStack(index: _selectedIndex, children: _pages),
          );
        } else if (constraints.maxWidth >= 700) {
          return _TabletLayout(
            currentIndex: _selectedIndex,
            onTap: _onIndexChanged,
            child: IndexedStack(index: _selectedIndex, children: _pages),
          );
        } else {
          return _MobileLayout(
            currentIndex: _selectedIndex,
            onTap: _onIndexChanged,
            child: IndexedStack(index: _selectedIndex, children: _pages),
          );
        }
      },
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MobileLayout({
    required this.child,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: c.surface,
          selectedItemColor: c.primary,
          unselectedItemColor: c.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.edit_outlined), activeIcon: Icon(Icons.edit), label: 'Edit'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'AI Lab'),
            BottomNavigationBarItem(icon: Icon(Icons.movie_creation_outlined), activeIcon: Icon(Icons.movie_creation), label: 'Projects'),
            BottomNavigationBarItem(icon: Icon(Icons.cloud_outlined), activeIcon: Icon(Icons.cloud), label: 'Storage'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Discover'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _TabletLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TabletLayout({
    required this.child,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: c.surface,
            selectedIconTheme: IconThemeData(color: c.primary),
            unselectedIconTheme: IconThemeData(color: c.textSecondary),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.edit_outlined), selectedIcon: Icon(Icons.edit), label: Text('Edit')),
              NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: Text('AI Lab')),
              NavigationRailDestination(icon: Icon(Icons.movie_creation_outlined), selectedIcon: Icon(Icons.movie_creation), label: Text('Projects')),
              NavigationRailDestination(icon: Icon(Icons.cloud_outlined), selectedIcon: Icon(Icons.cloud), label: Text('Storage')),
              NavigationRailDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: Text('Discover')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
            ],
          ),
          VerticalDivider(width: 1, color: c.border),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _WebLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _WebLayout({
    required this.child,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<_WebLayout> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isCollapsed ? 80 : 250,
            color: c.surface,
            child: Column(
              crossAxisAlignment: _isCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 0 : 24),
                  child: Row(
                    mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.brush, color: Colors.white, size: 20),
                      ),
                      if (!_isCollapsed) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Studio',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: c.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                      ],
                      if (!_isCollapsed)
                        IconButton(
                          icon: Icon(Icons.menu_open, color: c.textPrimary, size: 20),
                          onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                        ),
                    ],
                  ),
                ),
                if (_isCollapsed)
                   Padding(
                     padding: const EdgeInsets.only(top: 16),
                     child: IconButton(
                       icon: Icon(Icons.menu, color: c.textPrimary, size: 20),
                       onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                     ),
                   ),
                const SizedBox(height: 36),
                if (!_isCollapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'CREATOR TOOLS',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                if (!_isCollapsed) const SizedBox(height: 16),
                ...List.generate(_CreatorStudioLayoutState._navItems.length, (i) {
                  final item = _CreatorStudioLayoutState._navItems[i];
                  final isSelected = i == widget.currentIndex;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 8 : 12, vertical: 4),
                    child: ListTile(
                      contentPadding: _isCollapsed ? const EdgeInsets.symmetric(horizontal: 8) : null,
                      leading: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? c.primary : c.textSecondary,
                      ),
                      title: _isCollapsed ? null : Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? c.primary : c.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: c.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () => widget.onTap(i),
                    ),
                  );
                }),
                const Spacer(),
                if (!_isCollapsed)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.surface,
                        foregroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Exit Studio', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: const Icon(Icons.exit_to_app, color: Colors.red),
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: c.border),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
