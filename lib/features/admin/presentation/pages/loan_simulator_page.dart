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
  double _calcularInteresMensual(
    double monto,
    double tasaMensual,
    DateTime fechaInicio,
    DateTime fechaPago,
  ) {
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
      final interesCalculado = _calcularInteresMensual(
        monto,
        tasaMensual,
        _fechaInicio,
        _fechaPago,
      );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simular Préstamo'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
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
              Card(
                color: colorScheme.primary.withAlpha(24),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este simulador NO guarda datos. Solo calcula un recibo de ejemplo.',
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ) ??
                              const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Monto del Préstamo',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
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
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  child: Text(
                    '${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),

              const SizedBox(height: 24),

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
                    prefixIcon: Icon(Icons.event, color: colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  child: Text(
                    '${_fechaPago.day}/${_fechaPago.month}/${_fechaPago.year}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              DropdownButtonFormField<double>(
                value: _interes,
                decoration: InputDecoration(
                  labelText: 'Tipo de Interés',
                  prefixIcon: Icon(Icons.percent, color: colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
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

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(32),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withAlpha(90)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Regla de cálculo: 30 días = 1 mes de interés. Días adicionales se calculan proporcionalmente.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _simular,
                icon: const Icon(Icons.calculate),
                label: const Text('Simular Préstamo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              if (_recalcular) ...[
                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 16),

                Text(
                  'RECIBO DE SIMULACIÓN',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '(No válido para transacciones reales)',
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.textTheme.bodySmall?.color?.withAlpha(170),
                      ) ??
                      const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                ),

                const SizedBox(height: 24),

                _buildReciboItem(
                  'Monto Prestado',
                  '\$${_montoController.text}',
                ),
                _buildReciboItem(
                  'Tasa de Interés',
                  '${_interes.toStringAsFixed(1)}% mensual',
                ),
                _buildReciboItem(
                  'Fecha de Inicio',
                  '${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}',
                ),
                _buildReciboItem(
                  'Fecha de Pago',
                  '${_fechaPago.day}/${_fechaPago.month}/${_fechaPago.year}',
                ),
                _buildReciboItem('Plazo', _obtenerPlazoDias()),
                const SizedBox(height: 8),
                _buildDesglosInteresItem(),
                const SizedBox(height: 8),
                _buildReciboItem(
                  'Interés Total',
                  '\$${_interesCalculado.toStringAsFixed(2)}',
                  destacado: true,
                  color: colorScheme.secondary,
                ),

                const Divider(thickness: 2, height: 32),

                _buildReciboItem(
                  'Total a Pagar',
                  '\$${_totalConInteres.toStringAsFixed(2)}',
                  destacado: true,
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withAlpha(26),
                    border: Border.all(
                      color: colorScheme.tertiary.withAlpha(90),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este es un cálculo estimado. No se ha guardado ningún dato en la base de datos.',
                          style: theme.textTheme.bodySmall,
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
    final theme = Theme.of(context);
    const accentColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desglose del Interés:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accentColor.shade700,
            ),
          ),
          const SizedBox(height: 8),
          if (mesesCompletos > 0)
            Text(
              '• $mesesCompletos ${mesesCompletos == 1 ? "mes" : "meses"} completo${mesesCompletos == 1 ? "" : "s"}: \$${((double.tryParse(_montoController.text) ?? 0) * (_interes / 100) * mesesCompletos).toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: accentColor.shade700,
              ),
            ),
          if (diasRestantes > 0)
            Text(
              '• $diasRestantes días adicionales: \$${((double.tryParse(_montoController.text) ?? 0) * (_interes / 100) * (diasRestantes / 30)).toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: accentColor.shade700,
              ),
            ),
          if (mesesCompletos == 0 && diasRestantes == 0)
            Text(
              '• Sin días transcurridos',
              style: theme.textTheme.bodySmall?.copyWith(
                color: accentColor.shade700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReciboItem(
    String label,
    String valor, {
    bool destacado = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final Color resolvedColor =
        color ??
        (destacado ? theme.colorScheme.primary : theme.colorScheme.onSurface);
    final Color secondaryColor = destacado
        ? resolvedColor
        : theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;

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
              color: destacado ? resolvedColor : secondaryColor,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: destacado ? 20 : 16,
              fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
              color: resolvedColor,
            ),
          ),
        ],
      ),
    );
  }
}
