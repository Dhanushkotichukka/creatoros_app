import 'package:flutter/material.dart';

class ContentPlannerScreen extends StatelessWidget {
  const ContentPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Planner'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Graphic Placeholder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('November 2024', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Mock Week
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDayItem('Mon', '12', hasPost: true),
                      _buildDayItem('Tue', '13'),
                      _buildDayItem('Wed', '14', hasPost: true, isToday: true),
                      _buildDayItem('Thu', '15'),
                      _buildDayItem('Fri', '16', hasPost: true),
                      _buildDayItem('Sat', '17'),
                      _buildDayItem('Sun', '18'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('Upcoming Scheduled Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildScheduledCard('YouTube Setup Tour', 'Tomorrow, 10:00 AM', Icons.play_circle_fill, Colors.red),
            _buildScheduledCard('Instagram Reel: Edits', 'Friday, 6:00 PM', Icons.camera_alt, Colors.pink),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem(String day, String date, {bool hasPost = false, bool isToday = false}) {
    return Column(
      children: [
        Text(day, style: TextStyle(color: isToday ? Colors.deepPurpleAccent : Colors.grey, fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isToday ? Colors.deepPurpleAccent : Colors.transparent,
            shape: BoxShape.circle,
            border: hasPost ? Border.all(color: Colors.green, width: 2) : null,
          ),
          child: Center(
            child: Text(date, style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledCard(String title, String time, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(time, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.more_vert),
      ),
    );
  }
}
