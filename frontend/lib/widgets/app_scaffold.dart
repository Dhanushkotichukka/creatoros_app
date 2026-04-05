import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const AppScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  static const _navItems = [
    _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItem(label: 'Analytics', icon: Icons.analytics_outlined, activeIcon: Icons.analytics),
    _NavItem(label: 'Add', icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, isAction: true),
    _NavItem(label: 'Hub', icon: Icons.hub_outlined, activeIcon: Icons.hub),
    _NavItem(label: 'Community', icon: Icons.people_outline, activeIcon: Icons.people),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return _WebLayout(
            currentIndex: currentIndex,
            onTap: onIndexChanged,
            child: body,
          );
        } else if (constraints.maxWidth >= 700) {
          return _TabletLayout(
            currentIndex: currentIndex,
            onTap: onIndexChanged,
            child: body,
          );
        } else {
          return _MobileLayout(
            currentIndex: currentIndex,
            onTap: onIndexChanged,
            child: body,
          );
        }
      },
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isAction;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.isAction = false,
  });
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
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.secondary; // orange in dark, primary in light
    final inactiveColor = isDark ? const Color(0xFFA0A0B0) : const Color(0xFF6B6B6B);
    final navBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E5E5);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor, width: 1)),
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
          backgroundColor: navBg,
          selectedItemColor: activeColor,
          unselectedItemColor: inactiveColor,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: AppScaffold._navItems.map((item) {
            if (item.isAction) {
              return BottomNavigationBarItem(
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFFFF6A3D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
                label: '',
              );
            }
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            );
          }).toList(),
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
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.secondary;
    final navBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E5E5);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: navBg,
            selectedIconTheme: IconThemeData(color: activeColor),
            unselectedIconTheme: IconThemeData(
              color: isDark ? const Color(0xFFA0A0B0) : const Color(0xFF6B6B6B),
            ),
            destinations: AppScaffold._navItems.map((item) {
              if (item.isAction) {
                return NavigationRailDestination(
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFFF6A3D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  label: const Text(''),
                );
              }
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          VerticalDivider(width: 1, color: borderColor),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _WebLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _WebLayout({
    required this.child,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.secondary;
    final sidebarBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E5E5);
    final textActive = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final textInactive = isDark ? const Color(0xFFA0A0B0) : const Color(0xFF6B6B6B);
    final menuLabel = isDark ? const Color(0xFFA0A0B0) : const Color(0xFFAAAAAA);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: sidebarBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFFFF6A3D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bolt, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'CreatorOS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textActive,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'MAIN MENU',
                    style: TextStyle(
                      fontSize: 12,
                      color: menuLabel,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(AppScaffold._navItems.length, (i) {
                  final item = AppScaffold._navItems[i];
                  final isSelected = i == currentIndex;

                  if (item.isAction) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFFFF6A3D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.35),
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'New Project',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => onTap(i),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? activeColor : textInactive,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? activeColor : textInactive,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: activeColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () => onTap(i),
                    ),
                  );
                }),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: borderColor),
          Expanded(child: child),
        ],
      ),
    );
  }
}
