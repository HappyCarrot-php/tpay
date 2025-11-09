import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/interest_rate_selector.dart';

class LoanSimulatorPage extends StatefulWidget {
  const LoanSimulatorPage({super.key});

  @override
  State<LoanSimulatorPage> createState() => _LoanSimulatorPageState();
}

class _LoanSimulatorPageState extends State<LoanSimulatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _manualInterestController = TextEditingController();
  
  String _selectedInterestRate = '3';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaVencimiento = DateTime.now().add(const Duration(days: 30));
  
  double? _montoTotal;
  double? _interesCalculado;
  bool _mostrarResultado = false;

  @override
  void dispose() {
    _montoController.dispose();
    _manualInterestController.dispose();
    super.dispose();
  }

  void _calcularSimulacion() {
    if (_formKey.currentState!.validate()) {
      final monto = double.parse(_montoController.text);
      double tasaInteres;

      if (_selectedInterestRate == 'manual') {
        if (_manualInterestController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingrese la tasa de interés manual'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        tasaInteres = double.parse(_manualInterestController.text);
      } else {
        tasaInteres = double.parse(_selectedInterestRate);
      }

      final interes = monto * (tasaInteres / 100);
      final total = monto + interes;

      setState(() {
        _interesCalculado = interes;
        _montoTotal = total;
        _mostrarResultado = true;
      });
    }
  }

  void _limpiarSimulacion() {
    setState(() {
      _montoController.clear();
      _manualInterestController.clear();
      _selectedInterestRate = '3';
      _fechaInicio = DateTime.now();
      _fechaVencimiento = DateTime.now().add(const Duration(days: 30));
      _mostrarResultado = false;
      _montoTotal = null;
      _interesCalculado = null;
    });
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esFechaInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: esFechaInicio ? _fechaInicio : _fechaVencimiento,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('es', 'MX'),
    );

    if (picked != null) {
      setState(() {
        if (esFechaInicio) {
          _fechaInicio = picked;
          // Si la fecha de inicio es posterior a la de vencimiento, ajustar
          if (_fechaInicio.isAfter(_fechaVencimiento)) {
            _fechaVencimiento = _fechaInicio.add(const Duration(days: 30));
          }
        } else {
          _fechaVencimiento = picked;
        }
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Préstamo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _limpiarSimulacion,
            tooltip: 'Limpiar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de información
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Simula un préstamo sin guardarlo en la base de datos',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Monto
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto del préstamo',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'MXN',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el monto del préstamo';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null || monto <= 0) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Selector de interés modular
              InterestRateSelector(
                selectedRate: _selectedInterestRate,
                manualController: _manualInterestController,
                onRateChanged: (rate) {
                  setState(() {
                    _selectedInterestRate = rate;
                    _mostrarResultado = false;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Fechas
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => _seleccionarFecha(context, true),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fecha de inicio',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(_fechaInicio),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => _seleccionarFecha(context, false),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.event, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fecha de vencimiento',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(_fechaVencimiento),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botón calcular
              ElevatedButton.icon(
                onPressed: _calcularSimulacion,
                icon: const Icon(Icons.calculate),
                label: const Text('Calcular Simulación'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              // Resultados
              if (_mostrarResultado) ...[
                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 16),
                
                // Título de resultados
                const Text(
                  'Resultado de la Simulación',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Tarjeta de monto original
                _buildResultCard(
                  'Monto del Préstamo',
                  _formatCurrency(double.parse(_montoController.text)),
                  Colors.blue,
                  Icons.money,
                ),
                const SizedBox(height: 12),

                // Tarjeta de interés
                _buildResultCard(
                  'Interés (${_selectedInterestRate == 'manual' ? '${_manualInterestController.text}%' : '$_selectedInterestRate%'})',
                  _formatCurrency(_interesCalculado!),
                  Colors.orange,
                  Icons.percent,
                ),
                const SizedBox(height: 12),

                // Tarjeta de total a pagar
                _buildResultCard(
                  'Total a Pagar',
                  _formatCurrency(_montoTotal!),
                  Colors.green,
                  Icons.attach_money,
                  isHighlighted: true,
                ),
                const SizedBox(height: 24),

                // Información de fechas
                Card(
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDateInfo('Inicio', _fechaInicio),
                        const Divider(),
                        _buildDateInfo('Vencimiento', _fechaVencimiento),
                        const Divider(),
                        _buildDateInfo(
                          'Plazo',
                          null,
                          customText: '${_fechaVencimiento.difference(_fechaInicio).inDays} días',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    return Card(
      elevation: isHighlighted ? 8 : 2,
      color: isHighlighted ? color.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isHighlighted ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime? date, {String? customText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            customText ?? (date != null ? _formatDate(date) : ''),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
