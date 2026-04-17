import 'package:flutter/material.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Projects'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Video'),
            Tab(text: 'Image'),
            Tab(text: 'Template'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Cloud', 'Local', 'Draft'].map((filter) {
                  final isActive = _activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isActive,
                      onSelected: (selected) {
                        if (selected) setState(() => _activeFilter = filter);
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Project List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectList(Icons.movie_creation, Colors.blue),
                _buildProjectList(Icons.image, Colors.green),
                _buildProjectList(Icons.dashboard_customize, Colors.orange),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildProjectList(IconData icon, Color color) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // bottom padding for FAB
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
            ),
            title: Text('Project ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Last edited ${index + 1} hours ago'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }
}
