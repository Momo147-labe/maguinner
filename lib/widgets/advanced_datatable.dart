import 'package:flutter/material.dart';

/// DataTable avancée avec recherche, tri et actions CRUD
class AdvancedDataTable extends StatefulWidget {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final List<VoidCallback>? onEdit;
  final List<VoidCallback>? onDelete;
  final List<VoidCallback>? onDetails;
  final VoidCallback? onAdd;
  final bool searchable;
  final bool sortable;

  const AdvancedDataTable({
    Key? key,
    required this.title,
    required this.columns,
    required this.rows,
    this.onEdit,
    this.onDelete,
    this.onDetails,
    this.onAdd,
    this.searchable = true,
    this.sortable = true,
  }) : super(key: key);

  @override
  State<AdvancedDataTable> createState() => _AdvancedDataTableState();
}

class _AdvancedDataTableState extends State<AdvancedDataTable> {
  final TextEditingController _searchController = TextEditingController();
  List<List<String>> _filteredRows = [];
  int? _sortColumnIndex;
  bool _sortAscending = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredRows = List.from(widget.rows);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(AdvancedDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rows != oldWidget.rows) {
      _filteredRows = List.from(widget.rows);
      _filterRows();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterRows();
    });
  }

  void _filterRows() {
    if (_searchQuery.isEmpty) {
      _filteredRows = List.from(widget.rows);
    } else {
      _filteredRows = widget.rows.where((row) {
        return row.any((cell) => cell.toLowerCase().contains(_searchQuery));
      }).toList();
    }
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      
      _filteredRows.sort((a, b) {
        final aValue = a[columnIndex];
        final bValue = b[columnIndex];
        
        final aNum = double.tryParse(aValue.replaceAll(RegExp(r'[^\d.-]'), ''));
        final bNum = double.tryParse(bValue.replaceAll(RegExp(r'[^\d.-]'), ''));
        
        int result;
        if (aNum != null && bNum != null) {
          result = aNum.compareTo(bNum);
        } else {
          result = aValue.compareTo(bValue);
        }
        
        return ascending ? result : -result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header avec titre, recherche et bouton d'ajout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                if (widget.searchable) ...[
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                
                if (widget.onAdd != null)
                  ElevatedButton.icon(
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Table scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  showCheckboxColumn: false,
                  headingRowHeight: 56,
                  dataRowHeight: 56,
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  headingRowColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  columns: [
                    ...widget.columns.asMap().entries.map((entry) {
                      final index = entry.key;
                      final column = entry.value;
                      
                      return DataColumn(
                        label: Text(
                          column,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onSort: widget.sortable
                            ? (columnIndex, ascending) => _onSort(index, ascending)
                            : null,
                      );
                    }),
                    
                    // Colonne Actions
                    if (widget.onEdit != null || widget.onDelete != null || widget.onDetails != null)
                      const DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                  rows: _filteredRows.asMap().entries.map((entry) {
                    final originalIndex = widget.rows.indexOf(entry.value);
                    final row = entry.value;
                    
                    return DataRow(
                      color: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.hovered)) {
                          return Theme.of(context).colorScheme.primary.withOpacity(0.05);
                        }
                        return null;
                      }),
                      cells: [
                        ...row.map((cell) => DataCell(
                          Text(
                            cell,
                            style: const TextStyle(fontSize: 13),
                          ),
                        )),
                        
                        // Cellule Actions
                        if (widget.onEdit != null || widget.onDelete != null || widget.onDetails != null)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.onDetails != null && originalIndex >= 0)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ElevatedButton.icon(
                                      onPressed: () => widget.onDetails![originalIndex](),
                                      icon: const Icon(Icons.info, size: 16),
                                      label: const Text('Détails'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                    ),
                                  ),
                                if (widget.onEdit != null && originalIndex >= 0)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ElevatedButton.icon(
                                      onPressed: () => widget.onEdit![originalIndex](),
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Modifier'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                    ),
                                  ),
                                if (widget.onDelete != null && originalIndex >= 0)
                                  ElevatedButton.icon(
                                    onPressed: () => _showDeleteDialog(
                                      context,
                                      () => widget.onDelete![originalIndex](),
                                    ),
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text('Supprimer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
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
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${_filteredRows.length} élément(s) affiché(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Text(
                    ' sur ${widget.rows.length} total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}