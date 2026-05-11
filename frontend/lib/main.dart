import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/post_state.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'providers/view_state_provider.dart';
import 'screens/hub_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/ai/ai_script_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/creator_studio_screen.dart';
import 'screens/multi_post_hub_screen.dart';
import 'screens/creator_studio/creator_studio_layout.dart' as creator_studio;
import 'screens/video_editor_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_scaffold.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/history_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HistoryService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
      home: const SplashScreen(),
      routes: {
        '/ai/script_workshop': (context) {
           final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
           return AIScriptScreen(arguments: args);
        },
        '/ai-chat': (context) => const AiChatScreen(),
        // OpenCut video editor — opened with optional {videoUrl, title} args
        '/editor': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return VideoEditorScreen(
            videoUrl: args['videoUrl'] as String?,
            projectTitle: args['title'] as String?,
          );
        },
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
      );
    }

    if (!authProvider.isLoggedIn) {
      return const LoginScreen();
    }

    return const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<NavigatorState> _contentNavKey = GlobalKey<NavigatorState>();
  int _lastTab = 0;

  @override
  void initState() {
    super.initState();
    // Listen for global navigation events (like jumpToAnalytics)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ViewStateProvider>().addListener(_handleProviderTabChange);
    });
  }

  @override
  void dispose() {
    // Check if context is still valid or use a more robust way to remove listener
    // but usually provider is fine
    super.dispose();
  }

  void _handleProviderTabChange() {
    if (!mounted) return;
    final viewState = context.read<ViewStateProvider>();
    if (viewState.selectedTab != _lastTab) {
      setState(() {
        _lastTab = viewState.selectedTab;
      });
    }
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const AnalyticsScreen(),
    const SizedBox.shrink(), // Placeholder for Plus button action
    const HubScreen(),
    const AIScreen(),
  ];

  void _onItemTapped(int index) {
    final viewState = context.read<ViewStateProvider>();
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
        viewState.resetHome();
      });
      return;
    }
    
    // If Home is tapped, reset the view state even if already on Home
    if (index == 0) {
      viewState.resetHome();
    }

    if (viewState.selectedTab != index) {
      viewState.setSelectedTab(index);
    } else {
      // Pop to first route seamlessly if tapping the same active tab
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewState = context.watch<ViewStateProvider>();
    
    return AppScaffold(
      currentIndex: viewState.selectedTab,
      onIndexChanged: _onItemTapped,
      body: IndexedStack(
        index: viewState.selectedTab,
        children: _widgetOptions,
      ),
    );
  }
}
