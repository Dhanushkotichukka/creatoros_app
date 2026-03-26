import 'package:flutter/material.dart';

class AIUpdateTicker extends StatelessWidget {
  final List<String> updates;

  const AIUpdateTicker({super.key, required this.updates});

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    for (int i = 0; i < updates.length; i++) {
        children.add(TickerItem(text: updates[i]));
        if (i < updates.length - 1) {
            children.add(const SizedBox(width: 30));
        }
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepPurpleAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: children.isEmpty 
                    ? [const TickerItem(text: 'Analyzing recent performance...')]
                    : children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TickerItem extends StatelessWidget {
  final String text;
  const TickerItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 14, color: Colors.white70));
  }
}
