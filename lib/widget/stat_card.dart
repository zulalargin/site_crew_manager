import 'package:flutter/cupertino.dart';

class StatCard extends StatelessWidget {
  final String label;
  final int count;
  final String emoji;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.count,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
