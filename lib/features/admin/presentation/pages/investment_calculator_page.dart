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
      double aportacionesAcumuladas = 0;
      double rendimientoAcumulado = 0;

      for (int anio = 1; anio <= plazoAnios; anio++) {
        final double capitalInicio = capitalActual;
        final double rendimiento = capitalActual * tasaAnual;
        rendimientoAcumulado += rendimiento;
        capitalActual += rendimiento;

        double aportacionAplicada = 0;
        if (_tieneAportaciones) {
          capitalActual += aportacionAnual;
          aportacionesAcumuladas += aportacionAnual;
          aportacionAplicada = aportacionAnual;
        }

        resultados.add({
          'anio': anio,
          'capital_inicio': capitalInicio,
          'rendimiento': rendimiento,
          'rendimiento_acumulado': rendimientoAcumulado,
          'aportacion': aportacionAplicada,
          'aportaciones_acumuladas': aportacionesAcumuladas,
          'total': capitalActual,
        });
      }

      setState(() {
        _resultadosPorAnio = resultados;
        _totalFinal = capitalActual;
        _rendimientoTotal = rendimientoAcumulado;
        _aportacionesTotal = aportacionesAcumuladas;
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
                      Icon(
                        Icons.trending_up,
                        color: Colors.blue[700],
                        size: 32,
                      ),
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
                  if (monto == null || monto < 0) {
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                _aportacionesTotal >= 0 ? 'Aportaciones Total' : 'Gastos Total',
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

  Widget _buildResumenRow(
    String label,
    String value,
    Color color, {
    bool isTotal = false,
  }) {
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
    final double capitalInicial = double.tryParse(_montoController.text) ?? 0;
    final double capitalPositivo = capitalInicial > 0 ? capitalInicial : 0;
    final double rendimientoPositivo = _rendimientoTotal > 0
        ? _rendimientoTotal
        : 0;
    final double aportacionesPositivas =
        (_tieneAportaciones && _aportacionesTotal > 0) ? _aportacionesTotal : 0;

    final double totalGraficable =
        capitalPositivo + rendimientoPositivo + aportacionesPositivas;

    if (totalGraficable <= 0) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sin datos para graficar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa capital, rendimiento o aportaciones positivas para visualizar la composición de tu inversión.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    if (_tieneAportaciones && _aportacionesTotal < 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Las aportaciones negativas (gastos) no se incluyen en la gráfica circular.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    int touchedIndex = -1;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.donut_large, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Composición',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                height: 220,
                width: 220,
                child: StatefulBuilder(
                  builder: (context, setChartState) {
                    return PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setChartState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                        ),
                        sections: _buildCompactSections(
                          capital: capitalPositivo,
                          rendimiento: rendimientoPositivo,
                          aportaciones: aportacionesPositivas,
                          total: totalGraficable,
                          touchedIndex: touchedIndex,
                        ),
                        centerSpaceRadius: 50,
                        sectionsSpace: 2,
                        borderData: FlBorderData(show: false),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildCompactLeyenda(
              capital: capitalPositivo,
              rendimiento: rendimientoPositivo,
              aportaciones: aportacionesPositivas,
              total: totalGraficable,
            ),
            if (_tieneAportaciones && _aportacionesTotal < 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Nota: Las aportaciones negativas (gastos) no se muestran en la gráfica.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildCompactSections({
    required double capital,
    required double rendimiento,
    required double aportaciones,
    required double total,
    required int touchedIndex,
  }) {
    final List<PieChartSectionData> sections = [];
    final segments = [
      {'value': capital, 'color': const Color(0xFF2196F3)},
      {'value': rendimiento, 'color': const Color(0xFF4CAF50)},
      {'value': aportaciones, 'color': const Color(0xFF9C27B0)},
    ];

    int sectionIndex = 0;
    for (final segment in segments) {
      final double value = segment['value'] as double;
      if (value <= 0) continue;
      final Color color = segment['color'] as Color;
      final bool isTouched = sectionIndex == touchedIndex;
      sections.add(
        PieChartSectionData(
          value: value,
          title: '${_percentage(value, total).round()}%',
          color: color,
          radius: isTouched ? 65 : 55,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      sectionIndex++;
    }

    return sections;
  }

  Widget _buildCompactLeyenda({
    required double capital,
    required double rendimiento,
    required double aportaciones,
    required double total,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (capital > 0) ...[
          _buildCompactLeyendaItem(
            'Capital',
            const Color(0xFF2196F3),
            capital,
            _percentage(capital, total),
          ),
          const SizedBox(height: 12),
        ],
        if (rendimiento > 0) ...[
          _buildCompactLeyendaItem(
            'Rendimiento',
            const Color(0xFF4CAF50),
            rendimiento,
            _percentage(rendimiento, total),
          ),
          const SizedBox(height: 12),
        ],
        if (aportaciones > 0)
          _buildCompactLeyendaItem(
            'Aportaciones',
            const Color(0xFF9C27B0),
            aportaciones,
            _percentage(aportaciones, total),
          ),
      ],
    );
  }

  Widget _buildCompactLeyendaItem(
    String label,
    Color color,
    double amount,
    double percentage,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatCurrency(amount),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  double _percentage(double value, double total) {
    if (total <= 0) {
      return 0;
    }
    return (value / total) * 100;
  }

  Widget _buildTablaAnual() {
    final bool muestraAportaciones = _tieneAportaciones;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.green.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.timeline,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Proyección Año por Año',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final resultado = _resultadosPorAnio[index];
                  final bool esUltimo = index == _resultadosPorAnio.length - 1;
                  final double capitalInicio =
                      (resultado['capital_inicio'] as double?) ?? 0;
                  final double rendimiento =
                      (resultado['rendimiento'] as double?) ?? 0;
                  final double rendimientoAcumulado =
                      (resultado['rendimiento_acumulado'] as double?) ?? 0;
                  final double aportacion =
                      (resultado['aportacion'] as double?) ?? 0;
                  final double aportacionesAcumuladas =
                      (resultado['aportaciones_acumuladas'] as double?) ?? 0;
                  final double total = (resultado['total'] as double?) ?? 0;

                  final bool aportacionTieneValor =
                      muestraAportaciones && aportacion != 0;
                  final bool aportacionesAcumTienenValor =
                      muestraAportaciones && aportacionesAcumuladas != 0;

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: esUltimo
                            ? const Color(0xFF26C6DA)
                            : Colors.grey.shade200,
                      ),
                      color: esUltimo ? const Color(0xFFE0F7FA) : Colors.white,
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Año ${resultado['anio']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                if (esUltimo) ...[
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFF00838F),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  _formatCurrency(total),
                                  style: TextStyle(
                                    color: const Color(0xFF006064),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildMetricPill(
                              icon: Icons.payments_outlined,
                              label: 'Capital inicial',
                              value: _formatCurrency(capitalInicio),
                              color: Colors.indigo,
                            ),
                            _buildMetricPill(
                              icon: Icons.trending_up,
                              label: 'Rendimiento',
                              value: _formatCurrency(rendimiento),
                              color: rendimiento >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            _buildMetricPill(
                              icon: Icons.auto_graph,
                              label: 'Rendimiento acum.',
                              value: _formatCurrency(rendimientoAcumulado),
                              color: Colors.teal,
                            ),
                            if (aportacionTieneValor)
                              _buildMetricPill(
                                icon: aportacion >= 0
                                    ? Icons.savings
                                    : Icons.money_off,
                                label: aportacion >= 0 ? 'Aportación' : 'Gasto',
                                value: _formatCurrency(aportacion),
                                color: aportacion >= 0
                                    ? Colors.deepPurple
                                    : Colors.red,
                              ),
                            if (aportacionesAcumTienenValor)
                              _buildMetricPill(
                                icon: aportacionesAcumuladas >= 0
                                    ? Icons.account_balance
                                    : Icons.receipt_long,
                                label: aportacionesAcumuladas >= 0
                                    ? 'Aportaciones acumuladas'
                                    : 'Gastos acumulados',
                                value: _formatCurrency(aportacionesAcumuladas),
                                color: aportacionesAcumuladas >= 0
                                    ? Colors.deepPurple
                                    : Colors.red,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: _resultadosPorAnio.length,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final Color background = color.withValues(alpha: 0.08);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
