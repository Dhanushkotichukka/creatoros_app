import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class HomeScheduleCard extends StatelessWidget {
  const HomeScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    final scheduleItems = [
      _ScheduleItem(
        platform: 'Instagram',
        platformColor: const Color(0xFFE1306C),
        platformIcon: Icons.camera_alt,
        title: 'Movie Recommendation',
        type: 'Reel',
        time: '06:00 PM',
        status: _ScheduleStatus.scheduled,
      ),
      _ScheduleItem(
        platform: 'YouTube',
        platformColor: const Color(0xFFFF0000),
        platformIcon: Icons.play_circle_fill,
        title: 'Top 3 Feel Good Movies',
        type: 'Video',
        time: '09:00 PM',
        status: _ScheduleStatus.scheduled,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: c.primary, size: 16),
                    const SizedBox(width: 8),
                    Text("Today's Schedule",
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('View Calendar →',
                      style: TextStyle(
                          color: c.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Schedule items
          ...scheduleItems.map((item) => _ScheduleTile(item: item, c: c)),

          // Add button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, size: 16, color: c.primary),
                label: Text('Add New Schedule',
                    style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ScheduleStatus { scheduled, posted, failed }

class _ScheduleItem {
  final String platform;
  final Color platformColor;
  final IconData platformIcon;
  final String title;
  final String type;
  final String time;
  final _ScheduleStatus status;

  const _ScheduleItem({
    required this.platform,
    required this.platformColor,
    required this.platformIcon,
    required this.title,
    required this.type,
    required this.time,
    required this.status,
  });
}

class _ScheduleTile extends StatelessWidget {
  final _ScheduleItem item;
  final AppColors c;

  const _ScheduleTile({required this.item, required this.c});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.status == _ScheduleStatus.posted
        ? Colors.greenAccent
        : item.status == _ScheduleStatus.failed
            ? Colors.redAccent
            : Colors.blueAccent;
    final statusLabel = item.status == _ScheduleStatus.posted
        ? 'Posted'
        : item.status == _ScheduleStatus.failed
            ? 'Failed'
            : 'Scheduled';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.platformColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.platformColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.platformColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.platformIcon,
                  color: item.platformColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.type,
                      style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.time,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
