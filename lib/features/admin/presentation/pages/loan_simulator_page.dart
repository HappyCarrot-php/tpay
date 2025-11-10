import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoanSimulatorPage extends StatefulWidget {
  const LoanSimulatorPage({super.key});

  @override
  State<LoanSimulatorPage> createState() => _LoanSimulatorPageState();
}

class _LoanSimulatorPageState extends State<LoanSimulatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  double _interes = 10.0; // Porcentaje de interés por defecto
  
  bool _recalcular = false;
  double _totalConInteres = 0.0;
  double _interesCalculado = 0.0;

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  void _simular() {
    if (_formKey.currentState!.validate()) {
      final monto = double.tryParse(_montoController.text) ?? 0.0;
      final interesDecimal = _interes / 100;
      final interesCalculado = monto * interesDecimal;
      final totalConInteres = monto + interesCalculado;

      setState(() {
        _interesCalculado = interesCalculado;
        _totalConInteres = totalConInteres;
        _recalcular = true;
      });
    }
  }

  void _limpiar() {
    _montoController.clear();
    setState(() {
      _interes = 10.0;
      _recalcular = false;
      _totalConInteres = 0.0;
      _interesCalculado = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simular Préstamo'),
        backgroundColor: const Color(0xFF00BCD4),
        actions: [
          if (_recalcular)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _limpiar,
              tooltip: 'Limpiar',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este simulador NO guarda datos. Solo calcula un recibo de ejemplo.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Campo Monto
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Monto del Préstamo',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el monto';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null || monto <= 0) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Selector de Interés (Scroll)
              Text(
                'Interés: ${_interes.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  diameterRatio: 1.5,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _interes = (index + 1) * 0.5; // Incrementos de 0.5%
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      final valor = (index + 1) * 0.5;
                      final esSeleccionado = valor == _interes;
                      return Center(
                        child: Text(
                          '${valor.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: esSeleccionado ? 20 : 16,
                            fontWeight: esSeleccionado ? FontWeight.bold : FontWeight.normal,
                            color: esSeleccionado ? const Color(0xFF00BCD4) : Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                    childCount: 200, // Hasta 100% (200 * 0.5)
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Botón Simular
              ElevatedButton.icon(
                onPressed: _simular,
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'Simular Préstamo',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              // Resultado (Recibo falso)
              if (_recalcular) ...[
                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 16),
                
                // Título del recibo
                const Text(
                  'RECIBO DE SIMULACIÓN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BCD4),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '(No válido para transacciones reales)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Detalles del recibo
                _buildReciboItem('Monto Prestado', '\$${_montoController.text}'),
                _buildReciboItem('Tasa de Interés', '${_interes.toStringAsFixed(1)}%'),
                _buildReciboItem('Interés Calculado', '\$${_interesCalculado.toStringAsFixed(2)}'),
                
                const Divider(thickness: 2, height: 32),
                
                _buildReciboItem(
                  'Total a Pagar',
                  '\$${_totalConInteres.toStringAsFixed(2)}',
                  destacado: true,
                ),
                
                const SizedBox(height: 24),
                
                // Nota final
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este es un cálculo estimado. No se ha guardado ningún dato en la base de datos.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReciboItem(String label, String valor, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: destacado ? 18 : 16,
              fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
              color: destacado ? const Color(0xFF00BCD4) : Colors.black87,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: destacado ? 20 : 16,
              fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
              color: destacado ? const Color(0xFF00BCD4) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
