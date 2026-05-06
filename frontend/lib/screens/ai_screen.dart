import 'package:flutter/material.dart';
import 'ai/my_ai_section.dart';
import 'ai/master_ai_section.dart';
import 'ai/ai_script_library.dart';
import '../utils/app_colors.dart';

class AIScreen extends StatelessWidget {
  const AIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.smart_toy, color: c.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Hub', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                )
              ),
            ],
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'My AI'),
              Tab(text: 'Master AI'),
              Tab(text: 'Scripts Library'),
            ],
            indicatorColor: c.primary,
            labelColor: c.primary,
            unselectedLabelColor: c.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            dividerColor: c.border,
            indicatorWeight: 3,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                c.surface,
                c.background,
              ],
            ),
          ),
          child: const TabBarView(
            children: [
              MyAISection(),
              MasterAISection(),
              AIScriptLibrary(),
            ],
          ),
        ),
      ),
    );
  }
}
