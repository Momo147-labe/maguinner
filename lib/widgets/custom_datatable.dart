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
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et bouton d'ajout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
              ),
              color: theme.colorScheme.surfaceContainerLowest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                if (onAdd != null)
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Theme(
              data: theme.copyWith(
                dataTableTheme: DataTableThemeData(
                  headingRowColor: MaterialStateProperty.all(
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  ),
                  dataRowColor: MaterialStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return theme.colorScheme.primary.withOpacity(0.08);
                    }
                    return null; // Use default
                  }),
                  headingTextStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              child: DataTable(
                headingRowHeight: 56,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                dividerThickness: 0.5,
                horizontalMargin: 20,
                columnSpacing: 24,
                columns: [
                  ...columns.map((column) => DataColumn(label: Text(column))),
                  if (onEdit != null || onDelete != null)
                    const DataColumn(label: Text('Actions')),
                ],
                rows: rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;

                  return DataRow(
                    cells: [
                      ...row.map(
                        (cell) => DataCell(
                          Text(cell, style: theme.textTheme.bodyMedium),
                        ),
                      ),
                      if (onEdit != null || onDelete != null)
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (onEdit != null)
                                IconButton(
                                  onPressed: () => onEdit![index](),
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    size: 20,
                                  ),
                                  tooltip: 'Modifier',
                                  style: IconButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                  ),
                                ),
                              if (onEdit != null && onDelete != null)
                                const SizedBox(width: 8),
                              if (onDelete != null)
                                IconButton(
                                  onPressed: () => _showDeleteDialog(
                                    context,
                                    () => onDelete![index](),
                                  ),
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    size: 20,
                                  ),
                                  tooltip: 'Supprimer',
                                  style: IconButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                    backgroundColor: theme.colorScheme.error
                                        .withOpacity(0.1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cet élément ?\nCette action est irréversible.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
