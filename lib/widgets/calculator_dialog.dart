import 'package:flutter/material.dart';
import 'dart:math';

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
      child: Container(
        width: 400,
        height: 680,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Calculatrice',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Calculator content
            Expanded(
              child: _buildCalculatorContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _display,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(_display),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Buttons
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.2,
              children: [
                // Row 1
                _buildButton('C', _clear, color: Colors.red),
                _buildButton('CE', _clearEntry, color: Colors.orange),
                _buildButton('%', () => _inputOperation('%'), color: Theme.of(context).colorScheme.primary),
                _buildButton('÷', () => _inputOperation('÷'), color: Theme.of(context).colorScheme.primary),
                
                // Row 2
                _buildButton('7', () => _inputNumber('7')),
                _buildButton('8', () => _inputNumber('8')),
                _buildButton('9', () => _inputNumber('9')),
                _buildButton('×', () => _inputOperation('×'), color: Theme.of(context).colorScheme.primary),
                
                // Row 3
                _buildButton('4', () => _inputNumber('4')),
                _buildButton('5', () => _inputNumber('5')),
                _buildButton('6', () => _inputNumber('6')),
                _buildButton('-', () => _inputOperation('-'), color: Theme.of(context).colorScheme.primary),
                
                // Row 4
                _buildButton('1', () => _inputNumber('1')),
                _buildButton('2', () => _inputNumber('2')),
                _buildButton('3', () => _inputNumber('3')),
                _buildButton('+', () => _inputOperation('+'), color: Theme.of(context).colorScheme.primary),
                
                // Row 5
                _buildButton('0', () => _addZeros('0')),
                _buildButton('00', () => _addZeros('00'), color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                _buildButton('000', () => _addZeros('000'), color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                _buildButton('=', _performCalculation, color: Colors.green),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Percentage buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _calculatePercentage(false),
                  icon: const Icon(Icons.trending_down),
                  label: const Text('Réduction %'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _calculatePercentage(true),
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Augmentation %'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {Color? color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).colorScheme.surface,
        foregroundColor: color != null ? Colors.white : null,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}