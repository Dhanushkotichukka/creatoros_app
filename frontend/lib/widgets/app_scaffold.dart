import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

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
    _NavItem(label: 'Home',      icon: Icons.home_outlined,      activeIcon: Icons.home),
    _NavItem(label: 'Analytics', icon: Icons.analytics_outlined, activeIcon: Icons.analytics),
    _NavItem(label: 'Add',       icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, isAction: true),
    _NavItem(label: 'Hub',       icon: Icons.hub_outlined,       activeIcon: Icons.hub),
    _NavItem(label: 'AI',        icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy),
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
    final theme  = Theme.of(context);
    final c      = theme.extension<AppColors>()!;
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
          selectedItemColor:   c.primary,
          unselectedItemColor: c.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: AppScaffold._navItems.map((item) {
            if (item.isAction) {
              return BottomNavigationBarItem(
                icon: _ActionButton(c: c),
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
    final c     = theme.extension<AppColors>()!;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: c.surface,
            selectedIconTheme:   IconThemeData(color: c.primary),
            unselectedIconTheme: IconThemeData(color: c.textSecondary),
            destinations: AppScaffold._navItems.map((item) {
              if (item.isAction) {
                return NavigationRailDestination(
                  icon: _ActionButton(c: c, size: 40),
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
    final c     = theme.extension<AppColors>()!;

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
                  padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 0 : 12),
                  child: Row(
                    mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if the logo file hasn't been saved yet
                            return Container(
                              color: c.primary,
                              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                            );
                          },
                        ),
                      ),
                      if (!_isCollapsed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'CreatorOS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: c.textPrimary,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (!_isCollapsed)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
                      'MAIN MENU',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                if (!_isCollapsed) const SizedBox(height: 16),
                ...List.generate(AppScaffold._navItems.length, (i) {
                  final item = AppScaffold._navItems[i];
                  final isSelected = i == widget.currentIndex;

                  if (item.isAction) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: _isCollapsed ? 0 : 16.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: _isCollapsed ? 44 : double.infinity,
                          height: _isCollapsed ? 44 : 50,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: c.primary, width: 2),
                            borderRadius: BorderRadius.circular(_isCollapsed ? 22 : 16),
                            boxShadow: [
                              BoxShadow(
                                color: c.primary.withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: _isCollapsed
                            ? IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.add, color: c.primary),
                                onPressed: () => widget.onTap(i),
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: c.primary,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(Icons.add, color: c.primary),
                                label: Text(
                                  'New Project',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: c.primary),
                                ),
                                onPressed: () => widget.onTap(i),
                              ),
                        ),
                      ),
                    );
                  }

                  if (_isCollapsed) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Align(
                        alignment: Alignment.center,
                        child: InkWell(
                          onTap: () => widget.onTap(i),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected ? c.primary.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected ? c.primary : c.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? c.primary : c.textSecondary,
                      ),
                      title: Text(
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

// ── Shared "+" action button used in mobile, tablet, and web nav ─────────────
class _ActionButton extends StatelessWidget {
  final AppColors c;
  final double size;
  const _ActionButton({required this.c, this.size = 44});

  @override
  Widget build(BuildContext context) {
    // In AI mode use the gradient; in others use plain primary colour.
    final Decoration deco = c.primaryGradient != null
        ? BoxDecoration(
            shape: BoxShape.circle,
            gradient: c.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: c.primary.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          )
        : BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: c.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: c.primary.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          );

    return Container(
      width: size,
      height: size,
      decoration: deco,
      child: Icon(Icons.add, color: c.primaryGradient != null ? Colors.white : c.primary, size: size * 0.5),
    );
  }
}
