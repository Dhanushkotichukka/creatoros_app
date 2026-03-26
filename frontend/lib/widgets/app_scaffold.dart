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
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: Colors.deepPurpleAccent,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: AppScaffold._navItems.map((item) {
            if (item.isAction) {
              return BottomNavigationBarItem(
                icon: const CircleAvatar(
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.add, color: Colors.white),
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
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            selectedIconTheme: const IconThemeData(color: Colors.deepPurpleAccent),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            destinations: AppScaffold._navItems.map((item) {
              if (item.isAction) {
                return const NavigationRailDestination(
                  icon: CircleAvatar(
                    backgroundColor: Colors.deepPurpleAccent,
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                  label: Text(''),
                );
              }
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),
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
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: Theme.of(context).scaffoldBackgroundColor,
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
                          color: Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bolt, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'CreatorOS',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'MAIN MENU',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(AppScaffold._navItems.length, (i) {
                  final item = AppScaffold._navItems[i];
                  final isSelected = i == currentIndex;
                  
                  if (item.isAction) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('New Project', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => onTap(i),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? Colors.deepPurpleAccent : Colors.grey,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? Colors.deepPurpleAccent : Colors.white70,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: Colors.deepPurpleAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () => onTap(i),
                    ),
                  );
                }),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
