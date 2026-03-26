import 'package:flutter/material.dart';

class MasterAISection extends StatelessWidget {
  const MasterAISection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Master AI Analysis', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
          const Text('Personalized viral scripts based on YOUR history.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          _buildAnalysisStep('Step 1: Content History Analysis', 'Last 30 Videos (Recommended)', Icons.history),
          const SizedBox(height: 10),
          _buildAnalysisStep('Step 2: Internet Trend Matching', 'Niche: Technology / AI', Icons.trending_up),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Personalized Scripts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _generateMasterScripts(context),
                icon: const Icon(Icons.generating_tokens, size: 16),
                label: const Text('Generate Batch', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildScriptDraft('Bahubali Hidden Details', 'YT Shorts / Reels', 'Viral Potential: High (92%)'),
          _buildScriptDraft('Top 5 AI Tools 2025', 'Long Video', 'Viral Potential: Medium (75%)'),
          const SizedBox(height: 20),
          const Text('Breaking News + Scripts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: ListTile(
              leading: const Icon(Icons.newspaper, color: Colors.orange),
              title: const Text('New Movie Release Announcement'),
              subtitle: const Text('Convert this news into a script instantly.'),
              trailing: ElevatedButton(onPressed: () {}, child: const Text('Script for You', style: TextStyle(fontSize: 10))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisStep(String title, String subtitle, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildScriptDraft(String title, String format, String potential) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(format, style: const TextStyle(fontSize: 10, color: Colors.deepPurpleAccent)),
              ],
            ),
            const SizedBox(height: 8),
            Text(potential, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(onPressed: () {}, child: const Text('View Script')),
                const Spacer(),
                ElevatedButton(onPressed: () {}, child: const Text('Add to Planner')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generateMasterScripts(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Triggering Groq LLM for 10-batch generation...'))
    );
    // Real implementation would call ApiService.generateMasterScripts('Tech', 'General');
  }
}
