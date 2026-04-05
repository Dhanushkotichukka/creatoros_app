import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PlatformAnalyticsSlider extends StatelessWidget {
  final List<dynamic> platforms;

  const PlatformAnalyticsSlider({super.key, required this.platforms});

  IconData _getIconForPlatform(String name) {
    switch (name.toLowerCase()) {
      case 'youtube': return Icons.play_circle_fill;
      case 'instagram': return Icons.camera_alt;
      case 'linkedin': return Icons.business;
      case 'facebook': return Icons.facebook;
      default: return Icons.public;
    }
  }

  Color _getColorForPlatform(String name) {
    switch (name.toLowerCase()) {
      case 'youtube': return Colors.red;
      case 'instagram': return Colors.pink;
      case 'linkedin': return Colors.blue;
      case 'facebook': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: platforms.length + 1,
        itemBuilder: (context, index) {
          if (index == platforms.length) {
            return _AddPlatformCard();
          }

          final pData = platforms[index];
          if (pData['isConnected'] == false) {
            return _ConnectPlatformCard(name: pData['name'] as String? ?? 'Unknown');
          }

          final subText = pData['subscribers'] != null
              ? '${pData['subscribers']} Subscribers'
              : (pData['followers'] != null ? '${pData['followers']} Followers' : '');

          final viewsReach = (pData['views'] ?? pData['reach'] ?? '0') as String;

          return _PlatformCard(
            name: pData['name'] as String? ?? 'Unknown',
            views: viewsReach,
            subText: subText,
            icon: _getIconForPlatform(pData['name'] as String? ?? ''),
            color: _getColorForPlatform(pData['name'] as String? ?? ''),
            avatarUrl: pData['channelAvatar'] as String?,
            accountName: pData['channelName'] as String?,
          );
        },
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String name;
  final String views;
  final String subText;
  final IconData icon;
  final Color color;
  final String? avatarUrl;
  final String? accountName;

  _PlatformCard({
    required this.name,
    required this.views,
    required this.subText,
    required this.icon,
    required this.color,
    this.avatarUrl,
    this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (avatarUrl != null)
                CircleAvatar(radius: 10, backgroundImage: NetworkImage(avatarUrl!))
              else
                Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  accountName ?? name, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                  overflow: TextOverflow.ellipsis
                )
              ),
            ],
          ),
          const Spacer(),
          Text(views, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subText, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }
}

class _AddPlatformCard extends StatelessWidget {
  _AddPlatformCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        color: isDark ? Colors.grey[950] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: Colors.grey),
          SizedBox(height: 5),
          Text('Add Platform', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ConnectPlatformCard extends StatelessWidget {
  final String name;

  _ConnectPlatformCard({required this.name});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData iconData;
    switch (name.toLowerCase()) {
      case 'youtube': iconData = Icons.play_circle_fill; break;
      case 'instagram': iconData = Icons.camera_alt; break;
      case 'linkedin': iconData = Icons.business; break;
      default: iconData = Icons.public;
    }

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: Colors.grey, size: 28),
          const SizedBox(height: 8),
          Text(
            'Connect $name',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              if (name == 'YouTube') ApiService.loginWithYouTube();
              if (name == 'Instagram') ApiService.loginWithMeta();
              if (name == 'LinkedIn') ApiService.loginWithLinkedIn();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              foregroundColor: Colors.blueAccent,
              elevation: 0,
              minimumSize: const Size(100, 30),
            ),
            child: const Text('Connect', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
