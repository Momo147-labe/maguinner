import 'package:flutter/material.dart';

class ProColumn<T> {
  final String title;
  final double width;
  final Widget Function(T row) cell;
  final dynamic Function(T row)? sortValue;
  final bool fixed;

  const ProColumn({
    required this.title,
    required this.width,
    required this.cell,
    this.sortValue,
    this.fixed = false,
  });
}

class DataTablePro<T> extends StatefulWidget {
  final List<T> data;
  final List<ProColumn<T>> columns;
  final String Function(T row) searchBy;
  final int rowsPerPage;

  const DataTablePro({
    super.key,
    required this.data,
    required this.columns,
    required this.searchBy,
    this.rowsPerPage = 10,
  });

  @override
  State<DataTablePro<T>> createState() => _DataTableProState<T>();
}

class _DataTableProState<T> extends State<DataTablePro<T>> {
  late List<T> _filtered;
  int _page = 0;

  int? _sortColumnIndex;
  bool _sortAscending = true;

  Map<String, String> _filters = {};

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  final double _fontSize = 16;

  @override
  void initState() {
    super.initState();
    _filtered = widget.data;
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    setState(() {
      _filtered = widget.data.where((row) {
        bool match = true;

        if (_filters.containsKey('search')) {
          final query = _filters['search']!.toLowerCase();
          match &= widget.searchBy(row).toLowerCase().contains(query);
        }

        _filters.forEach((key, value) {
          if (key != 'search' && value.isNotEmpty) {
            final rowValue = widget.searchBy(row).toLowerCase();
            match &= rowValue.contains(value.toLowerCase());
          }
        });

        return match;
      }).toList();
      _page = 0;
    });
  }

  void _sort<TValue>(int columnIndex, bool ascending,
      dynamic Function(T row)? getValue) {
    if (getValue == null) return;
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _filtered.sort((a, b) {
        final aValue = getValue(a);
        final bValue = getValue(b);
        if (aValue is Comparable && bValue is Comparable) {
          return ascending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        }
        return 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = _page * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, _filtered.length);
    final pageData = _filtered.sublist(start, end);

    final fixedColumns =
        widget.columns.where((c) => c.fixed).toList(growable: false);
    final scrollColumns =
        widget.columns.where((c) => !c.fixed).toList(growable: false);

    final theme = Theme.of(context);
    final headerColor =
        theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200];
    final evenRowColor =
        theme.brightness == Brightness.dark ? Colors.transparent : Colors.transparent;
    final oddRowColor =
        theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey.withOpacity(0.1);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return SizedBox.expand(
      child: Column(
        children: [
          // Recherche globale
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: textColor),
                hintText: 'Rechercher...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                _filters['search'] = value;
                _applyFilter();
              },
            ),
          ),

          // Filtres avancés
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: widget.columns.map((col) {
                return SizedBox(
                  width: col.width,
                  child: TextField(
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                        labelText: col.title,
                        labelStyle: TextStyle(color: textColor),
                        border: const OutlineInputBorder()),
                    onChanged: (val) {
                      _filters[col.title] = val;
                      _applyFilter();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Tableau avec header fixe
          Expanded(
            child: Row(
              children: [
                if (fixedColumns.isNotEmpty)
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        children: fixedColumns.map((col) {
                          final index = widget.columns.indexOf(col);
                          return GestureDetector(
                            onTap: () {
                              _sort(
                                  index,
                                  _sortColumnIndex == index
                                      ? !_sortAscending
                                      : true,
                                  col.sortValue);
                            },
                            child: Container(
                              width: col.width,
                              height: 56,
                              color: headerColor,
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Text(col.title,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: _fontSize,
                                          color: textColor)),
                                  if (_sortColumnIndex == index)
                                    Icon(
                                      _sortAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 16,
                                      color: textColor,
                                    )
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _verticalController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _verticalController,
                            itemCount: pageData.length,
                            itemBuilder: (context, index) {
                              final row = pageData[index];
                              return Row(
                                children: fixedColumns.map((col) {
                                  return Container(
                                    width: col.width,
                                    height: 56,
                                    padding: const EdgeInsets.all(12.0),
                                    color: index.isEven ? evenRowColor : oddRowColor,
                                    child: DefaultTextStyle(
                                        style: TextStyle(
                                            fontSize: _fontSize, color: textColor),
                                        child: col.cell(row)),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                // Colonnes scrollables
                Expanded(
                  child: Scrollbar(
                    controller: _horizontalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: [
                          Row(
                            children: scrollColumns.asMap().entries.map((entry) {
                              final index = widget.columns.indexOf(entry.value);
                              final col = entry.value;
                              return GestureDetector(
                                onTap: () {
                                  _sort(
                                      index,
                                      _sortColumnIndex == index
                                          ? !_sortAscending
                                          : true,
                                      col.sortValue);
                                },
                                child: Container(
                                  width: col.width,
                                  height: 56,
                                  color: headerColor,
                                  alignment: Alignment.centerLeft,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      Text(col.title,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: _fontSize,
                                              color: textColor)),
                                      if (_sortColumnIndex == index)
                                        Icon(
                                          _sortAscending
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          size: 16,
                                          color: textColor,
                                        )
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          Expanded(
                            child: SizedBox(
                              width: scrollColumns.fold<double>(
                                  0, (sum, col) => sum + col.width),
                              child: ListView.builder(
                                controller: _verticalController,
                                itemCount: pageData.length,
                                itemBuilder: (context, index) {
                                  final row = pageData[index];
                                  return Row(
                                    children: scrollColumns.map((col) {
                                      return Container(
                                        width: col.width,
                                        height: 56,
                                        padding: const EdgeInsets.all(12.0),
                                        color: index.isEven
                                            ? evenRowColor
                                            : oddRowColor,
                                        child: DefaultTextStyle(
                                          style: TextStyle(
                                              fontSize: _fontSize,
                                              color: textColor),
                                          child: col.cell(row),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _page > 0 ? () => setState(() => _page--) : null,
              ),
              Text(
                "Page ${_page + 1} / ${(_filtered.length / widget.rowsPerPage).ceil()}",
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: (_page + 1) * widget.rowsPerPage < _filtered.length
                    ? () => setState(() => _page++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
