import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../models/multi_post/platform_type.dart';
import '../widgets/upload_components/header_section.dart';
import '../widgets/upload_components/upload_content_section.dart';
import '../widgets/upload_components/time_section.dart';
import '../widgets/upload_components/platform_content_section.dart';
import '../widgets/upload_components/actions_section.dart';
import '../widgets/upload_components/bottom_sections.dart';

class MultiPostHubScreen extends StatelessWidget {
  final Set<PlatformType> initialPlatforms;
  const MultiPostHubScreen({Key? key, this.initialPlatforms = const {}}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostProvider(initialPlatforms: initialPlatforms),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Post to Everywhere', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HeaderSection(),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 2, child: UploadContentSection()),
                    const SizedBox(width: 16),
                    const Expanded(flex: 1, child: TimeSection()),
                  ],
                ),
                const SizedBox(height: 20),
                const PlatformContentSection(),
                const SizedBox(height: 10),
                const ActionsSection(),
                const SizedBox(height: 20),
                const BottomSections(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
