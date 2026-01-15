import 'package:flutter/material.dart';

/// Dialog de calculatrice intégrée pour la gestion de magasin
class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({Key? key}) : super(key: key);

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  String _previousValue = '';
  String _operation = '';
  bool _waitingForOperand = false;
  bool _hasDecimal = false;

  void _inputNumber(String number) {
    setState(() {
      if (_waitingForOperand) {
        _display = number;
        _waitingForOperand = false;
        _hasDecimal = false;
      } else {
        _display = _display == '0' ? number : _display + number;
      }
    });
  }

  void _inputDecimal() {
    if (!_hasDecimal) {
      setState(() {
        _display += '.';
        _hasDecimal = true;
      });
    }
  }

  void _inputOperation(String nextOperation) {
    double inputValue = double.tryParse(_display) ?? 0;

    if (_previousValue.isEmpty) {
      _previousValue = inputValue.toString();
    } else if (!_waitingForOperand) {
      double previousValue = double.tryParse(_previousValue) ?? 0;
      double result = _calculate(previousValue, inputValue, _operation);

      setState(() {
        _display = _formatResult(result);
        _previousValue = result.toString();
      });
    }

    setState(() {
      _waitingForOperand = true;
      _operation = nextOperation;
      _hasDecimal = false;
    });
  }

  double _calculate(double firstValue, double secondValue, String operation) {
    switch (operation) {
      case '+':
        return firstValue + secondValue;
      case '-':
        return firstValue - secondValue;
      case '×':
        return firstValue * secondValue;
      case '÷':
        return secondValue != 0 ? firstValue / secondValue : 0;
      default:
        return secondValue;
    }
  }

  void _performCalculation() {
    double inputValue = double.tryParse(_display) ?? 0;

    if (_previousValue.isNotEmpty && _operation.isNotEmpty) {
      double previousValue = double.tryParse(_previousValue) ?? 0;
      double result = _calculate(previousValue, inputValue, _operation);

      setState(() {
        _display = _formatResult(result);
        _previousValue = '';
        _operation = '';
        _waitingForOperand = true;
        _hasDecimal = result != result.floor();
      });
    }
  }

  void _clear() {
    setState(() {
      _display = '0';
      _previousValue = '';
      _operation = '';
      _waitingForOperand = false;
      _hasDecimal = false;
    });
  }

  void _clearEntry() {
    setState(() {
      _display = '0';
      _hasDecimal = false;
    });
  }

  void _addZeros(String zeros) {
    setState(() {
      if (_display == '0') {
        _display = zeros;
      } else {
        _display += zeros;
      }
    });
  }

  void _calculatePercentage(bool isIncrease) {
    double currentValue = double.tryParse(_display) ?? 0;
    double percentage = double.tryParse(_previousValue) ?? 0;

    if (percentage != 0) {
      double result;
      if (isIncrease) {
        result = currentValue * (1 + percentage / 100);
      } else {
        result = currentValue * (1 - percentage / 100);
      }

      setState(() {
        _display = _formatResult(result);
        _previousValue = '';
        _waitingForOperand = true;
        _hasDecimal = result != result.floor();
      });
    }
  }

  String _formatResult(double value) {
    if (value == value.floor()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(2);
    }
  }

  String _formatCurrency(String value) {
    double numValue = double.tryParse(value) ?? 0;
    String formatted = numValue.toStringAsFixed(0);

    // Ajouter des espaces pour les milliers
    String result = '';
    int count = 0;
    for (int i = formatted.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ' $result';
        count = 0;
      }
      result = formatted[i] + result;
      count++;
    }

    return '$result GNF';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 400,
        height: 680,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calculate_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Calculatrice',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Calculator content
            Expanded(child: _buildCalculatorContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorContent() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _display,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  _formatCurrency(_display),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Buttons
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                // Row 1
                _buildButton(
                  'C',
                  _clear,
                  backgroundColor: theme.colorScheme.errorContainer,
                  textColor: theme.colorScheme.error,
                ),
                _buildButton(
                  'CE',
                  _clearEntry,
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  textColor: theme.colorScheme.tertiary,
                ),
                _buildButton(
                  '%',
                  () => _inputOperation('%'),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  textColor: theme.colorScheme.secondary,
                ),
                _buildButton(
                  '÷',
                  () => _inputOperation('÷'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  textColor: theme.colorScheme.primary,
                ),

                // Row 2
                _buildButton('7', () => _inputNumber('7')),
                _buildButton('8', () => _inputNumber('8')),
                _buildButton('9', () => _inputNumber('9')),
                _buildButton(
                  '×',
                  () => _inputOperation('×'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  textColor: theme.colorScheme.primary,
                ),

                // Row 3
                _buildButton('4', () => _inputNumber('4')),
                _buildButton('5', () => _inputNumber('5')),
                _buildButton('6', () => _inputNumber('6')),
                _buildButton(
                  '-',
                  () => _inputOperation('-'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  textColor: theme.colorScheme.primary,
                ),

                // Row 4
                _buildButton('1', () => _inputNumber('1')),
                _buildButton('2', () => _inputNumber('2')),
                _buildButton('3', () => _inputNumber('3')),
                _buildButton(
                  '+',
                  () => _inputOperation('+'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  textColor: theme.colorScheme.primary,
                ),

                // Row 5
                _buildButton('0', () => _addZeros('0')),
                _buildButton('00', () => _addZeros('00'), fontSize: 16),
                _buildButton('.', _inputDecimal),
                _buildButton(
                  '=',
                  _performCalculation,
                  backgroundColor: theme.colorScheme.primary,
                  textColor: theme.colorScheme.onPrimary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Percentage buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _calculatePercentage(false),
                  icon: const Icon(Icons.trending_down_rounded, size: 18),
                  label: const Text('Réduction'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _calculatePercentage(true),
                  icon: const Icon(Icons.trending_up_rounded, size: 18),
                  label: const Text('Hausse'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Colors.green, // Keep specific green for increase
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    Color? backgroundColor,
    Color? textColor,
    double fontSize = 20,
  }) {
    final theme = Theme.of(context);
    final isNumber = backgroundColor == null;

    return Material(
      color:
          backgroundColor ??
          (theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.surface),
      borderRadius: BorderRadius.circular(16),
      elevation: isNumber ? 1 : 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            border: isNumber
                ? Border.all(color: theme.dividerColor.withOpacity(0.2))
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
