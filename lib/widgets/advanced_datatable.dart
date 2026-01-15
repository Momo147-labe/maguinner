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
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Card(
      elevation: 0,
      margin: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header avec titre, recherche et bouton d'ajout
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
              ),
            ),
            child: isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
          ),

          // Table scrollable
          Expanded(child: isMobile ? _buildMobileList() : _buildDesktopTable()),

          // Footer
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              border: Border(
                top: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_filteredRows.length} élément(s)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'sur ${widget.rows.length} total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
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
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],

        if (widget.onAdd != null)
          FilledButton.icon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.onAdd != null)
              FilledButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        if (widget.searchable) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              isDense: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopTable() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        child: Theme(
          data: theme.copyWith(
            dataTableTheme: DataTableThemeData(
              headingRowColor: MaterialStateProperty.all(
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              dataRowColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return theme.colorScheme.primary.withOpacity(0.04);
                }
                return null;
              }),
            ),
          ),
          child: DataTable(
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            showCheckboxColumn: false,
            headingRowHeight: 52,
            dataRowHeight: 60,
            horizontalMargin: 24,
            columnSpacing: 24,
            dividerThickness: 0.5,
            columns: [
              ...widget.columns.asMap().entries.map((entry) {
                final index = entry.key;
                final column = entry.value;

                return DataColumn(
                  label: Text(column),
                  onSort: widget.sortable
                      ? (columnIndex, ascending) => _onSort(index, ascending)
                      : null,
                );
              }),

              // Colonne Actions
              if (widget.onEdit != null ||
                  widget.onDelete != null ||
                  widget.onDetails != null)
                const DataColumn(label: Text('Actions')),
            ],
            rows: _filteredRows.asMap().entries.map((entry) {
              final originalIndex = widget.rows.indexOf(entry.value);
              final row = entry.value;

              return DataRow(
                cells: [
                  ...row.map(
                    (cell) =>
                        DataCell(Text(cell, style: theme.textTheme.bodyMedium)),
                  ),

                  // Cellule Actions
                  if (widget.onEdit != null ||
                      widget.onDelete != null ||
                      widget.onDetails != null)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onDetails != null && originalIndex >= 0)
                            IconButton(
                              onPressed: () =>
                                  widget.onDetails![originalIndex](),
                              icon: const Icon(Icons.info_rounded, size: 20),
                              tooltip: 'Détails',
                              style: IconButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.1),
                              ),
                            ),
                          if (widget.onEdit != null && originalIndex >= 0) ...[
                            if (widget.onDetails != null)
                              const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => widget.onEdit![originalIndex](),
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              tooltip: 'Modifier',
                              style: IconButton.styleFrom(
                                foregroundColor: theme.colorScheme.secondary,
                                backgroundColor: theme.colorScheme.secondary
                                    .withOpacity(0.1),
                              ),
                            ),
                          ],
                          if (widget.onDelete != null &&
                              originalIndex >= 0) ...[
                            if (widget.onEdit != null ||
                                widget.onDetails != null)
                              const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _showDeleteDialog(
                                context,
                                () => widget.onDelete![originalIndex](),
                              ),
                              icon: const Icon(Icons.delete_rounded, size: 20),
                              tooltip: 'Supprimer',
                              style: IconButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                backgroundColor: theme.colorScheme.error
                                    .withOpacity(0.1),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _filteredRows.length,
      itemBuilder: (context, index) {
        final originalIndex = widget.rows.indexOf(_filteredRows[index]);
        final row = _filteredRows[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section (First 2 columns if available)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons
                            .inventory_2_outlined, // Generic icon, could be dynamic
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.columns.isNotEmpty) ...[
                            Text(
                              widget.columns[0],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              row.isNotEmpty ? row[0] : '-',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.columns.length > 1 && row.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.columns[1],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              row[1],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Divider
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),

              // Content Section (Remaining columns)
              if (widget.columns.length > 2)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (int i = 2; i < widget.columns.length; i++)
                        if (i < row.length)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    widget.columns[i],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    row[i],
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.end,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),

              // Actions Section
              if (widget.onEdit != null ||
                  widget.onDelete != null ||
                  widget.onDetails != null) ...[
                Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.onDetails != null && originalIndex >= 0)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => widget.onDetails![originalIndex](),
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text('Détails'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      if (widget.onEdit != null && originalIndex >= 0)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => widget.onEdit![originalIndex](),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Modifier'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      if (widget.onDelete != null && originalIndex >= 0)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _showDeleteDialog(
                              context,
                              () => widget.onDelete![originalIndex](),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Supprimer'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
