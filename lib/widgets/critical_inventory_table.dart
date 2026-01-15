import 'package:flutter/material.dart';

class CriticalInventoryTable extends StatelessWidget {
  const CriticalInventoryTable({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [
      {
        "product": "Dell XPS 13",
        "ref": "REF-DX13-900",
        "category": "Électronique",
        "currentStock": 2,
        "minStock": 5,
        "status": "Critique"
      },
      {
        "product": "Chaise Ergonomique",
        "ref": "REF-CH-E200",
        "category": "Mobilier",
        "currentStock": 4,
        "minStock": 10,
        "status": "Bas"
      },
      {
        "product": "Casque Sony WH-1000XM4",
        "ref": "REF-SN-WH4",
        "category": "Électronique",
        "currentStock": 1,
        "minStock": 8,
        "status": "Critique"
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Produit')),
            DataColumn(label: Text('Catégorie')),
            DataColumn(label: Text('Stock Actuel')),
            DataColumn(label: Text('Stock Min.')),
            DataColumn(label: Text('Statut')),
          ],
          rows: data
              .map(
                (e) => DataRow(
                  cells: [
                    DataCell(Text('${e['product']} (${e['ref']})')),
                    DataCell(Text(e['category'].toString())),
                    DataCell(Text(e['currentStock'].toString())),
                    DataCell(Text(e['minStock'].toString())),
                    DataCell(Text(e['status'].toString())),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
