import 'package:flutter/material.dart';
import 'community/my_ai_section.dart';
import 'community/groups_section.dart';
import 'community/master_ai_section.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'My AI'),
              Tab(text: 'Groups'),
              Tab(text: 'Master AI'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: const TabBarView(
          children: [
            MyAISection(),
            GroupsSection(),
            MasterAISection(),
          ],
        ),
      ),
    );
  }
}
