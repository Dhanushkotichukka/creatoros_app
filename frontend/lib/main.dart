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
    return MaterialApp(
      title: 'CreatorOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.mode,
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MultiPostHubScreen()),
      );
      return;
    }
    
    // If Home is tapped, reset the view state even if already on Home
    if (index == 0) {
      context.read<ViewStateProvider>().resetHome();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: _selectedIndex,
      onIndexChanged: _onItemTapped,
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}
