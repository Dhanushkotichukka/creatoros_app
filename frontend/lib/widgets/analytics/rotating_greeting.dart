import 'dart:async';
import 'package:flutter/material.dart';

class RotatingGreeting extends StatefulWidget {
  final List<dynamic> platforms;
  const RotatingGreeting({super.key, required this.platforms});

  @override
  State<RotatingGreeting> createState() => _RotatingGreetingState();
}

class _RotatingGreetingState extends State<RotatingGreeting> {
  int _currentIndex = 0;
  Timer? _timer;
  List<dynamic> _connectedPlatforms = [];

  @override
  void initState() {
    super.initState();
    _connectedPlatforms = widget.platforms.where((p) => p['isConnected'] == true).toList();
    if (_connectedPlatforms.length > 1) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(RotatingGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.platforms != oldWidget.platforms) {
      _connectedPlatforms = widget.platforms.where((p) => p['isConnected'] == true).toList();
      _currentIndex = 0;
      if (_connectedPlatforms.length <= 1) {
        _timer?.cancel();
      } else if (_timer == null || !_timer!.isActive) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _connectedPlatforms.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _connectedPlatforms.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_connectedPlatforms.isEmpty) {
      return const Text('Hey, Creator', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white));
    }
    
    final currentPlatform = _connectedPlatforms[_currentIndex];
    final String greeting = _getGreetingText(currentPlatform as Map<String, dynamic>);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<int>(_currentIndex),
        alignment: Alignment.centerLeft,
        child: Text(
          greeting,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  String _getGreetingText(Map<String, dynamic> platform) {
    if (platform['name'] == 'YouTube') {
      return 'Hey, ${platform['channelName'] ?? 'YouTube Creator'}';
    } else if (platform['name'] == 'Instagram') {
      return 'Hey, @${platform['handle'] ?? 'instagram_user'}';
    } else if (platform['name'] == 'LinkedIn') {
      return 'Hey, ${platform['handle'] ?? 'LinkedIn Professional'}';
    }
    return 'Hey, Creator';
  }
}
