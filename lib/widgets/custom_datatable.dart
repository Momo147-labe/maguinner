import 'package:flutter/material.dart';

/// Widget DataTable personnalisé et réutilisable
class CustomDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final List<VoidCallback>? onEdit;
  final List<VoidCallback>? onDelete;
  final VoidCallback? onAdd;
  final String? title;

  const CustomDataTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.onEdit,
    this.onDelete,
    this.onAdd,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et bouton d'ajout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (onAdd != null)
                  ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  ...columns.map((column) => DataColumn(
                    label: Text(
                      column,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )),
                  if (onEdit != null || onDelete != null)
                    const DataColumn(
                      label: Text(
                        'Actions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
                rows: rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  
                  return DataRow(
                    cells: [
                      ...row.map((cell) => DataCell(Text(cell))),
                      if (onEdit != null || onDelete != null)
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (onEdit != null)
                                IconButton(
                                  onPressed: () => onEdit![index](),
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Modifier',
                                  color: Colors.blue,
                                ),
                              if (onDelete != null)
                                IconButton(
                                  onPressed: () => _showDeleteDialog(
                                    context,
                                    () => onDelete![index](),
                                  ),
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Supprimer',
                                  color: Colors.red,
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet élément ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}