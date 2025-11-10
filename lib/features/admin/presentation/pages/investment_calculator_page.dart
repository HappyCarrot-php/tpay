import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class InvestmentCalculatorPage extends StatefulWidget {
  const InvestmentCalculatorPage({super.key});

  @override
  State<InvestmentCalculatorPage> createState() =>
      _InvestmentCalculatorPageState();
}

class _InvestmentCalculatorPageState extends State<InvestmentCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _tasaController = TextEditingController();
  final _plazoController = TextEditingController();
  final _aportacionesController = TextEditingController();

  bool _tieneAportaciones = false;
  List<Map<String, dynamic>> _resultadosPorAnio = [];
  double _totalFinal = 0;
  double _rendimientoTotal = 0;
  double _aportacionesTotal = 0;
  bool _mostrarResultados = false;

  @override
  void dispose() {
    _montoController.dispose();
    _tasaController.dispose();
    _plazoController.dispose();
    _aportacionesController.dispose();
    super.dispose();
  }

  void _calcularInversion() {
    if (_formKey.currentState!.validate()) {
      final double capitalInicial = double.parse(_montoController.text);
      final double tasaAnual = double.parse(_tasaController.text) / 100;
      final int plazoAnios = int.parse(_plazoController.text);
      final double aportacionAnual = _tieneAportaciones
          ? double.parse(_aportacionesController.text)
          : 0;

      List<Map<String, dynamic>> resultados = [];
      double capitalActual = capitalInicial;
      double totalAportaciones = 0;
      double totalRendimiento = 0;

      for (int anio = 1; anio <= plazoAnios; anio++) {
        // Calcular rendimiento del año
        final double rendimiento = capitalActual * tasaAnual;
        totalRendimiento += rendimiento;

        // Sumar rendimiento al capital
        capitalActual += rendimiento;

        // Agregar aportación (puede ser negativa para gastos)
        if (_tieneAportaciones) {
          capitalActual += aportacionAnual;
          totalAportaciones += aportacionAnual;
        }

        resultados.add({
          'anio': anio,
          'rendimiento': rendimiento,
          'aportacion': aportacionAnual,
          'total': capitalActual,
        });
      }

      setState(() {
        _resultadosPorAnio = resultados;
        _totalFinal = capitalActual;
        _rendimientoTotal = totalRendimiento;
        _aportacionesTotal = totalAportaciones;
        _mostrarResultados = true;
      });
    }
  }

  void _limpiar() {
    setState(() {
      _montoController.clear();
      _tasaController.clear();
      _plazoController.clear();
      _aportacionesController.clear();
      _tieneAportaciones = false;
      _resultadosPorAnio = [];
      _mostrarResultados = false;
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calcular Inversión'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _limpiar,
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
              // Card informativo
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.blue[700], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Simula el crecimiento de tu inversión a largo plazo',
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

              // Monto inicial
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capital Inicial',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'MXN',
                  helperText: 'Monto inicial de la inversión',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el capital inicial';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null || monto <= 0) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tasa de interés anual
              TextFormField(
                controller: _tasaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tasa de Interés Anual',
                  prefixIcon: Icon(Icons.percent),
                  suffixText: '%',
                  helperText: 'Rendimiento anual esperado',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la tasa de interés';
                  }
                  final tasa = double.tryParse(value);
                  if (tasa == null || tasa < 0) {
                    return 'Ingrese una tasa válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Plazo en años
              TextFormField(
                controller: _plazoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Plazo',
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixText: 'años',
                  helperText: 'Duración de la inversión',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el plazo';
                  }
                  final plazo = int.tryParse(value);
                  if (plazo == null || plazo <= 0 || plazo > 50) {
                    return 'Ingrese un plazo válido (1-50 años)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Switch para aportaciones
              SwitchListTile(
                title: const Text('¿Hay aportaciones anuales?'),
                subtitle: Text(
                  _tieneAportaciones
                      ? 'Puede ser positivo (ahorro) o negativo (gastos)'
                      : 'Sin aportaciones adicionales',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: _tieneAportaciones,
                onChanged: (value) {
                  setState(() {
                    _tieneAportaciones = value;
                    if (!value) {
                      _aportacionesController.clear();
                    }
                  });
                },
              ),

              // Campo de aportaciones anuales
              if (_tieneAportaciones)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextFormField(
                    controller: _aportacionesController,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Aportaciones Anuales',
                      prefixIcon: Icon(Icons.savings),
                      suffixText: 'MXN',
                      helperText:
                          'Positivo = ahorro, Negativo = gastos mensuales/anuales',
                    ),
                    validator: (value) {
                      if (_tieneAportaciones &&
                          (value == null || value.isEmpty)) {
                        return 'Ingrese las aportaciones anuales';
                      }
                      if (value != null && value.isNotEmpty) {
                        final aportacion = double.tryParse(value);
                        if (aportacion == null) {
                          return 'Ingrese un monto válido';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 32),

              // Botón calcular
              ElevatedButton.icon(
                onPressed: _calcularInversion,
                icon: const Icon(Icons.calculate),
                label: const Text('Calcular Inversión'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Resultados
              if (_mostrarResultados) ...[
                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 16),

                // Resumen
                _buildResumenCard(),
                const SizedBox(height: 24),

                // Gráfica circular
                _buildGraficaCircular(),
                const SizedBox(height: 24),

                // Tabla año por año
                _buildTablaAnual(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenCard() {
    final double capitalInicial = double.parse(_montoController.text);

    return Card(
      elevation: 4,
      color: const Color(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Resumen de Inversión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildResumenRow(
              'Capital Inicial',
              _formatCurrency(capitalInicial),
              Colors.blue,
            ),
            const Divider(),
            _buildResumenRow(
              'Rendimiento Total',
              _formatCurrency(_rendimientoTotal),
              Colors.green,
            ),
            if (_tieneAportaciones && _aportacionesTotal != 0) ...[
              const Divider(),
              _buildResumenRow(
                _aportacionesTotal >= 0
                    ? 'Aportaciones Total'
                    : 'Gastos Total',
                _formatCurrency(_aportacionesTotal.abs()),
                _aportacionesTotal >= 0 ? Colors.purple : Colors.red,
              ),
            ],
            const Divider(thickness: 2),
            const SizedBox(height: 8),
            _buildResumenRow(
              'Total Final',
              _formatCurrency(_totalFinal),
              const Color(0xFF00BCD4),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenRow(String label, String value, Color color,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficaCircular() {
    final double capitalInicial = double.parse(_montoController.text);
    final List<PieChartSectionData> sections = [];

    // Capital inicial
    sections.add(
      PieChartSectionData(
        value: capitalInicial,
        title: 'Capital\nInicial',
        color: Colors.blue,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    // Rendimiento
    sections.add(
      PieChartSectionData(
        value: _rendimientoTotal,
        title: 'Rendi-\nmiento',
        color: Colors.green,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    // Aportaciones (solo si son positivas)
    if (_tieneAportaciones && _aportacionesTotal > 0) {
      sections.add(
        PieChartSectionData(
          value: _aportacionesTotal,
          title: 'Aporta-\nciones',
          color: Colors.purple,
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Composición del Total Final',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Leyenda
            _buildLeyenda(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyenda() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLeyendaItem('Capital Inicial', Colors.blue),
        _buildLeyendaItem('Rendimiento', Colors.green),
        if (_tieneAportaciones && _aportacionesTotal > 0)
          _buildLeyendaItem('Aportaciones', Colors.purple),
      ],
    );
  }

  Widget _buildLeyendaItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTablaAnual() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proyección Año por Año',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFE3F2FD),
                ),
                columns: [
                  const DataColumn(
                    label: Text(
                      'Año',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'Rendimiento',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_tieneAportaciones)
                    DataColumn(
                      label: Text(
                        _aportacionesTotal >= 0 ? 'Aportación' : 'Gasto',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  const DataColumn(
                    label: Text(
                      'Total Acumulado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _resultadosPorAnio.map((resultado) {
                  return DataRow(
                    cells: [
                      DataCell(Text('${resultado['anio']}')),
                      DataCell(
                        Text(
                          _formatCurrency(resultado['rendimiento']),
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                      if (_tieneAportaciones)
                        DataCell(
                          Text(
                            _formatCurrency(resultado['aportacion'].abs()),
                            style: TextStyle(
                              color: resultado['aportacion'] >= 0
                                  ? Colors.purple
                                  : Colors.red,
                            ),
                          ),
                        ),
                      DataCell(
                        Text(
                          _formatCurrency(resultado['total']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00BCD4),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
