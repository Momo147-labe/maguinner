import 'package:flutter/material.dart';

class SalesChart extends StatelessWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [
      {"label": "Juin", "sales": 60, "purchases": 40},
      {"label": "Juil", "sales": 75, "purchases": 45},
      {"label": "Août", "sales": 50, "purchases": 55},
      {"label": "Sep", "sales": 85, "purchases": 30},
      {"label": "Oct", "sales": 65, "purchases": 50},
      {"label": "Nov", "sales": 90, "purchases": 35},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((e) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 20,
                    height: 100,
                    color: Colors.grey[300],
                  ),
                  Container(
                    width: 20,
                    height: (e['sales'] as num?)?.toDouble() ?? 0.0,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(e['label'].toString()),
            ],
          );
        }).toList(),
      ),
    );
  }
}
