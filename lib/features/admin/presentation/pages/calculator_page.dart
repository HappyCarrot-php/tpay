import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:math' as math;

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _display = '0';
  String _expression = '';
  bool _isAdvancedMode = false;

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _display = '0';
        _expression = '';
      } else if (value == '⌫') {
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
        } else {
          _display = '0';
        }
        _expression = _display;
      } else if (value == '=') {
        try {
          _expression = _display;
          final result = _evaluateExpression(_display);
          _display = result;
        } catch (e) {
          _display = 'Error';
        }
      } else {
        if (_display == '0' || _display == 'Error') {
          _display = value;
        } else {
          _display += value;
        }
        _expression = _display;
      }
    });
  }

  String _evaluateExpression(String expression) {
    try {
      // Reemplazar funciones especiales
      String exp = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', math.pi.toString())
          .replaceAll('e', math.e.toString());

      // Manejar funciones trigonométricas y otras
      exp = _handleSpecialFunctions(exp);

      Parser p = Parser();
      Expression e = p.parse(exp);
      ContextModel cm = ContextModel();
      double result = e.evaluate(EvaluationType.REAL, cm);

      // Formatear el resultado
      if (result == result.toInt()) {
        return result.toInt().toString();
      } else {
        return result.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    } catch (e) {
      return 'Error';
    }
  }

  String _handleSpecialFunctions(String exp) {
    // Aquí podrías agregar más funciones especiales si lo necesitas
    // Por ahora, math_expressions ya maneja sqrt, sin, cos, etc.
    return exp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora'),
        actions: [
          IconButton(
            icon: Icon(_isAdvancedMode ? Icons.calculate : Icons.functions),
            onPressed: () {
              setState(() {
                _isAdvancedMode = !_isAdvancedMode;
              });
            },
            tooltip: _isAdvancedMode ? 'Modo Básico' : 'Modo Avanzado',
          ),
        ],
      ),
      body: Column(
        children: [
          // Display
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.grey[900],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_expression.isNotEmpty && _expression != _display)
                    Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[400],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _display,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Teclado
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(8),
              child: _isAdvancedMode
                  ? _buildAdvancedKeyboard()
                  : _buildBasicKeyboard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicKeyboard() {
    final List<List<String>> buttons = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];

    return Column(
      children: buttons.map((row) {
        return Expanded(
          child: Row(
            children: row.map((button) {
              return Expanded(
                flex: button == '0' ? 2 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _buildButton(button),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedKeyboard() {
    final List<List<String>> buttons = [
      ['C', '⌫', '(', ')', '%'],
      ['sin', 'cos', 'tan', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', 'π', 'e', '='],
    ];

    return Column(
      children: buttons.map((row) {
        return Expanded(
          child: Row(
            children: row.map((button) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _buildButton(button),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButton(String text) {
    Color backgroundColor;
    Color textColor = Colors.black87;

    if (text == 'C' || text == '⌫') {
      backgroundColor = Colors.red[400]!;
      textColor = Colors.white;
    } else if (text == '=') {
      backgroundColor = const Color(0xFF00BCD4);
      textColor = Colors.white;
    } else if (['+', '-', '×', '÷', '%'].contains(text)) {
      backgroundColor = Colors.orange[400]!;
      textColor = Colors.white;
    } else if (['sin', 'cos', 'tan', '(', ')', 'π', 'e'].contains(text)) {
      backgroundColor = Colors.blue[400]!;
      textColor = Colors.white;
    } else {
      backgroundColor = Colors.white;
    }

    return ElevatedButton(
      onPressed: () => _onButtonPressed(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        padding: const EdgeInsets.all(8),
      ),
      child: FittedBox(
        child: Text(
          text,
          style: TextStyle(
            fontSize: ['sin', 'cos', 'tan'].contains(text) ? 16 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
