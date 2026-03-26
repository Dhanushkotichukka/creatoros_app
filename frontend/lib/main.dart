import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/community_screen.dart';
import 'screens/creator_studio_screen.dart';
import 'widgets/app_scaffold.dart';

void main() {

  runApp(const CreatorOSApp());
}

class CreatorOSApp extends StatelessWidget {
  const CreatorOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CreatorOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatorStudioScreen()),
      );
      return;
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

// End of main.dart
