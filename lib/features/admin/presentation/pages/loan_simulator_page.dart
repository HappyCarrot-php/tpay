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
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaPago = DateTime.now().add(const Duration(days: 30));
  
  bool _recalcular = false;
  double _totalConInteres = 0.0;
  double _interesCalculado = 0.0;

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  /// Calcula el interés mensual con la regla: 30 días = 1 mes
  /// Días adicionales se calculan proporcionalmente
  /// 
  /// Ejemplo: $100 al 10% durante 60 días (2 meses)
  /// - Días totales: 60
  /// - Meses completos: 60 ÷ 30 = 2 meses
  /// - Días restantes: 60 % 30 = 0 días
  /// - Interés: $100 × 10% × 2 = $20
  double _calcularInteresMensual(double monto, double tasaMensual, DateTime fechaInicio, DateTime fechaPago) {
    final diasTotales = fechaPago.difference(fechaInicio).inDays;
    
    // Cada 30 días cuenta como 1 mes completo
    final mesesCompletos = diasTotales ~/ 30;
    final diasRestantes = diasTotales % 30;
    
    // Interés por meses completos
    final interesMeses = monto * tasaMensual * mesesCompletos;
    
    // Interés por días restantes (proporcional)
    final interesDias = monto * tasaMensual * (diasRestantes / 30);
    
    return interesMeses + interesDias;
  }

  String _obtenerPlazoDias() {
    final diasTotales = _fechaPago.difference(_fechaInicio).inDays;
    final mesesCompletos = diasTotales ~/ 30;
    final diasRestantes = diasTotales % 30;
    
    if (mesesCompletos == 0) {
      return '$diasTotales días';
    } else if (diasRestantes == 0) {
      return '$mesesCompletos ${mesesCompletos == 1 ? "mes" : "meses"} ($diasTotales días)';
    } else {
      return '$mesesCompletos ${mesesCompletos == 1 ? "mes" : "meses"} + $diasRestantes días ($diasTotales días totales)';
    }
  }

  void _simular() {
    if (_formKey.currentState!.validate()) {
      final monto = double.tryParse(_montoController.text) ?? 0.0;
      final tasaMensual = _interes / 100;
      final interesCalculado = _calcularInteresMensual(monto, tasaMensual, _fechaInicio, _fechaPago);
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
      _fechaInicio = DateTime.now();
      _fechaPago = DateTime.now().add(const Duration(days: 30));
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
              
              // Fecha de Inicio
              InkWell(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaInicio,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    locale: const Locale('es', 'MX'),
                  );
                  if (fecha != null) {
                    setState(() => _fechaInicio = fecha);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Inicio',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  child: Text(
                    '${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Fecha de Pago
              InkWell(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaPago,
                    firstDate: _fechaInicio,
                    lastDate: DateTime(2030),
                    locale: const Locale('es', 'MX'),
                  );
                  if (fecha != null) {
                    setState(() => _fechaPago = fecha);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Pago',
                    prefixIcon: const Icon(Icons.event),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  child: Text(
                    '${_fechaPago.day}/${_fechaPago.month}/${_fechaPago.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Selector de Interés (Dropdown moderno)
              DropdownButtonFormField<double>(
                value: _interes,
                decoration: InputDecoration(
                  labelText: 'Tipo de Interés',
                  prefixIcon: const Icon(Icons.percent, color: Color(0xFF00BCD4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: const [
                  DropdownMenuItem(value: 3.0, child: Text('3% mensual')),
                  DropdownMenuItem(value: 5.0, child: Text('5% mensual')),
                  DropdownMenuItem(value: 10.0, child: Text('10% mensual')),
                  DropdownMenuItem(value: 15.0, child: Text('15% mensual')),
                  DropdownMenuItem(value: 20.0, child: Text('20% mensual')),
                  DropdownMenuItem(value: 25.0, child: Text('25% mensual')),
                  DropdownMenuItem(value: 30.0, child: Text('30% mensual')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _interes = value);
                  }
                },
              ),
              
              const SizedBox(height: 32),
              
              // Información sobre cálculo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Regla de cálculo: 30 días = 1 mes de interés. Días adicionales se calculan proporcionalmente.',
                        style: TextStyle(fontSize: 12, color: Colors.green[900]),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
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
                _buildReciboItem('Tasa de Interés', '${_interes.toStringAsFixed(1)}% mensual'),
                _buildReciboItem('Fecha de Inicio', '${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}'),
                _buildReciboItem('Fecha de Pago', '${_fechaPago.day}/${_fechaPago.month}/${_fechaPago.year}'),
                _buildReciboItem('Plazo', _obtenerPlazoDias()),
                const SizedBox(height: 8),
                _buildDesglosInteresItem(),
                const SizedBox(height: 8),
                _buildReciboItem('Interés Total', '\$${_interesCalculado.toStringAsFixed(2)}', destacado: true, color: Colors.orange),
                
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

  Widget _buildDesglosInteresItem() {
    final diasTotales = _fechaPago.difference(_fechaInicio).inDays;
    final mesesCompletos = diasTotales ~/ 30;
    final diasRestantes = diasTotales % 30;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desglose del Interés:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange[900],
            ),
          ),
          const SizedBox(height: 8),
          if (mesesCompletos > 0)
            Text(
              '• $mesesCompletos ${mesesCompletos == 1 ? "mes" : "meses"} completo${mesesCompletos == 1 ? "" : "s"}: \$${((double.tryParse(_montoController.text) ?? 0) * (_interes / 100) * mesesCompletos).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 13, color: Colors.orange[900]),
            ),
          if (diasRestantes > 0)
            Text(
              '• $diasRestantes días adicionales: \$${((double.tryParse(_montoController.text) ?? 0) * (_interes / 100) * (diasRestantes / 30)).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 13, color: Colors.orange[900]),
            ),
          if (mesesCompletos == 0 && diasRestantes == 0)
            Text(
              '• Sin días transcurridos',
              style: TextStyle(fontSize: 13, color: Colors.orange[900]),
            ),
        ],
      ),
    );
  }

  Widget _buildReciboItem(String label, String valor, {bool destacado = false, Color? color}) {
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
              color: color ?? (destacado ? const Color(0xFF00BCD4) : Colors.black87),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: destacado ? 20 : 16,
              fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
              color: color ?? (destacado ? const Color(0xFF00BCD4) : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
