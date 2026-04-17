import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/post_state.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'providers/view_state_provider.dart';
import 'screens/hub_screen.dart';
import 'screens/community_screen.dart';
import 'screens/creator_studio_screen.dart';
import 'screens/multi_post_hub_screen.dart';
import 'screens/creator_studio/creator_studio_layout.dart' as creator_studio;
import 'widgets/app_scaffold.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostState()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ViewStateProvider()),
      ],
      child: const CreatorOSApp(),
    ),
  );
}

class CreatorOSApp extends StatelessWidget {
  const CreatorOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Select the correct ThemeData for the active mode.
    final ThemeData activeTheme;
    final ThemeMode themeMode;
    switch (themeProvider.appMode) {
      case AppMode.light:
        activeTheme = ThemeProvider.lightTheme;
        themeMode = ThemeMode.light;
        break;
      case AppMode.dark:
        activeTheme = ThemeProvider.darkTheme;
        themeMode = ThemeMode.dark;
        break;
      case AppMode.ai:
        activeTheme = ThemeProvider.aiTheme;
        themeMode = ThemeMode.dark;
        break;
    }

    return MaterialApp(
      title: 'CreatorOS',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      darkTheme: activeTheme,
      themeMode: themeMode,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _contentNavKey = GlobalKey<NavigatorState>();

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    AnalyticsScreen(),
    const SizedBox.shrink(), // Placeholder for Plus button action
    HubScreen(),
    CommunityScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      print('DEBUG: Plus button clicked!');
      Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const creator_studio.CreatorStudioLayout(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        ),
      ).then((_) {
        // Trigger refresh on return
        context.read<ViewStateProvider>().resetHome();
      });
      return;
    }
    
    // If Home is tapped, reset the view state even if already on Home
    if (index == 0) {
      context.read<ViewStateProvider>().resetHome();
    }

    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      
      _contentNavKey.currentState?.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => _widgetOptions.elementAt(index),
          transitionDuration: Duration.zero,
        )
      );
    } else {
      // Pop to first route seamlessly if tapping the same active tab
      _contentNavKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: _selectedIndex,
      onIndexChanged: _onItemTapped,
      body: Navigator(
        key: _contentNavKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => _widgetOptions.elementAt(_selectedIndex),
          );
        },
      ),
    );
  }
}
