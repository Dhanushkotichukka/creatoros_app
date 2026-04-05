import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/view_state_provider.dart';

class ConnectPlatformsView extends StatefulWidget {
  final VoidCallback? onConnected;
  
  ConnectPlatformsView({super.key, this.onConnected});

  @override
  State<ConnectPlatformsView> createState() => _ConnectPlatformsViewState();
}

class _ConnectPlatformsViewState extends State<ConnectPlatformsView> with WidgetsBindingObserver {
  Map<String, dynamic> _statuses = {
    'youtube': {'connected': false},
    'instagram': {'connected': false},
    'linkedin': {'connected': false},
  };
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh statuses when user returns to app from browser/OAuth
      _fetchStatuses();
    }
  }

  Future<void> _fetchStatuses() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getPlatformStatuses();
      if (mounted) {
        setState(() {
          _statuses = {
            'youtube': data['youtube'] ?? {'connected': false},
            'instagram': data['instagram'] ?? {'connected': false},
            'linkedin': data['linkedin'] ?? {'connected': false},
          };
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           _isLoading = false;
           _error = e.toString();
        });
      }
    }
  }

  Future<void> _disconnect(String platform) async {
    try {
      await ApiService.disconnectPlatform(platform);
      await _fetchStatuses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnected from $platform')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnect failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewState = context.watch<ViewStateProvider>();
    final canPop = Navigator.canPop(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Connect & Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: (canPop || viewState.showConnectView) 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
              onPressed: () {
                if (canPop) {
                  Navigator.pop(context);
                } else {
                  viewState.setShowConnectView(false);
                }
              },
            )
          : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white : Colors.black),
            onPressed: _fetchStatuses,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.link, color: Colors.blueAccent, size: 40)
                ),
                const SizedBox(height: 16),
                const Text('Link your accounts to unlock AI-powered insights and growth tracking.', 
                    style: TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 40),
                
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildConnectCard(
                      title: 'YouTube',
                      platformId: 'youtube',
                      icon: Icons.play_circle_fill,
                      color: Colors.red,
                      desc: 'Connect your Google account to fetch video stats and receive AI-powered content coaching.',
                      status: _statuses['youtube']!,
                      onConnect: () async {
                        await ApiService.loginWithYouTube();
                        _fetchStatuses();
                      }
                    ),
                    _buildConnectCard(
                      title: 'Instagram',
                      platformId: 'instagram',
                      icon: Icons.camera_alt,
                      color: Colors.pink,
                      desc: 'Link your Meta Business account to track reel performance, followers, and engagement.',
                      status: _statuses['instagram']!,
                      onConnect: () async {
                        await ApiService.loginWithMeta();
                        _fetchStatuses();
                      }
                    ),
                    _buildConnectCard(
                      title: 'LinkedIn',
                      platformId: 'linkedin',
                      icon: Icons.business,
                      color: Colors.blue,
                      desc: 'Link your LinkedIn profile to track post reach and professional network growth.',
                      status: _statuses['linkedin']!,
                      onConnect: () async {
                        await ApiService.loginWithLinkedIn();
                        _fetchStatuses();
                      }
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Error fetching status: $_error\nTip: Ensure backend is running and restart it if routes are missing.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 60),
              ]
            )
          )
    );
  }

  Widget _buildConnectCard({
    required String title, 
    required String platformId,
    required IconData icon, 
    required Color color, 
    required String desc, 
    required Map<String, dynamic> status, 
    required VoidCallback onConnect
  }) {
    final bool isConnected = status['connected'] ?? false;
    final String? accountName = status['name'];
    final String? accountAvatar = status['avatar'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 320,
      height: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isConnected ? color.withOpacity(0.5) : (isDark ? Colors.grey[900]! : Colors.grey[200]!)),
        boxShadow: isConnected 
            ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)] 
            : [BoxShadow(color: Colors.black.withOpacity(isDark ? 0 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               if (isConnected && accountAvatar != null)
                 CircleAvatar(
                   backgroundImage: NetworkImage(accountAvatar),
                   radius: 20,
                 )
               else
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                   child: Icon(icon, color: color, size: 28),
                 ),
               if (isConnected)
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green)),
                   child: const Row(
                     children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 12),
                        SizedBox(width: 4),
                        Text('CONNECTED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))
                     ]
                   )
                 )
            ]
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
          if (isConnected && accountName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(accountName, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          const SizedBox(height: 10),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
          const Spacer(),
          if (isConnected)
             Row(
               children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _disconnect(platformId), 
                      icon: const Icon(Icons.link_off, size: 18, color: Colors.redAccent), 
                      label: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  ),
               ]
             )
          else
             ElevatedButton.icon(
               onPressed: onConnect,
               icon: Icon(icon, size: 18),
               label: Text('Connect $title'),
               style: ElevatedButton.styleFrom(
                 backgroundColor: color,
                 foregroundColor: Colors.white,
                 minimumSize: const Size(double.infinity, 50),
                 elevation: 0,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
               )
             )
        ]
      )
    );
  }
}
