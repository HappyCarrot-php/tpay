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
    int touchedIndex = -1;
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Composición del Total Final',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 280,
                child: StatefulBuilder(
                  builder: (context, setChartState) {
                    return PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setChartState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: _buildModernSections(capitalInicial, touchedIndex),
                        centerSpaceRadius: 60,
                        sectionsSpace: 3,
                        borderData: FlBorderData(show: false),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Leyenda mejorada
              _buildModernLeyenda(capitalInicial),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildModernSections(double capitalInicial, int touchedIndex) {
    final List<PieChartSectionData> sections = [];
    int index = 0;

    // Capital inicial
    final bool isCapitalTouched = index == touchedIndex;
    sections.add(
      PieChartSectionData(
        value: capitalInicial,
        title: isCapitalTouched 
            ? _formatCurrency(capitalInicial)
            : '${(capitalInicial / _totalFinal * 100).toStringAsFixed(1)}%',
        color: const Color(0xFF2196F3),
        radius: isCapitalTouched ? 130 : 110,
        titleStyle: TextStyle(
          fontSize: isCapitalTouched ? 14 : 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        badgeWidget: isCapitalTouched 
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF2196F3),
                  size: 24,
                ),
              )
            : null,
        badgePositionPercentageOffset: 0.8,
      ),
    );
    index++;

    // Rendimiento
    final bool isRendimientoTouched = index == touchedIndex;
    sections.add(
      PieChartSectionData(
        value: _rendimientoTotal,
        title: isRendimientoTouched
            ? _formatCurrency(_rendimientoTotal)
            : '${(_rendimientoTotal / _totalFinal * 100).toStringAsFixed(1)}%',
        color: const Color(0xFF4CAF50),
        radius: isRendimientoTouched ? 130 : 110,
        titleStyle: TextStyle(
          fontSize: isRendimientoTouched ? 14 : 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        badgeWidget: isRendimientoTouched
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              )
            : null,
        badgePositionPercentageOffset: 0.8,
      ),
    );
    index++;

    // Aportaciones (solo si son positivas)
    if (_tieneAportaciones && _aportacionesTotal > 0) {
      final bool isAportacionesTouched = index == touchedIndex;
      sections.add(
        PieChartSectionData(
          value: _aportacionesTotal,
          title: isAportacionesTouched
              ? _formatCurrency(_aportacionesTotal)
              : '${(_aportacionesTotal / _totalFinal * 100).toStringAsFixed(1)}%',
          color: const Color(0xFF9C27B0),
          radius: isAportacionesTouched ? 130 : 110,
          titleStyle: TextStyle(
            fontSize: isAportacionesTouched ? 14 : 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
          badgeWidget: isAportacionesTouched
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.savings,
                    color: Color(0xFF9C27B0),
                    size: 24,
                  ),
                )
              : null,
          badgePositionPercentageOffset: 0.8,
        ),
      );
    }

    return sections;
  }

  Widget _buildModernLeyenda(double capitalInicial) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildModernLeyendaItem(
            'Capital Inicial',
            const Color(0xFF2196F3),
            Icons.account_balance_wallet,
            capitalInicial,
            (capitalInicial / _totalFinal * 100),
          ),
          const SizedBox(height: 12),
          _buildModernLeyendaItem(
            'Rendimiento',
            const Color(0xFF4CAF50),
            Icons.trending_up,
            _rendimientoTotal,
            (_rendimientoTotal / _totalFinal * 100),
          ),
          if (_tieneAportaciones && _aportacionesTotal > 0) ...[
            const SizedBox(height: 12),
            _buildModernLeyendaItem(
              'Aportaciones',
              const Color(0xFF9C27B0),
              Icons.savings,
              _aportacionesTotal,
              (_aportacionesTotal / _totalFinal * 100),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernLeyendaItem(
    String label,
    Color color,
    IconData icon,
    double amount,
    double percentage,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrency(amount),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildTablaAnual() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.green.shade50.withOpacity(0.3),
            ],
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
                      Icons.table_chart,
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.blue.shade100.withOpacity(0.5),
                  ),
                  headingRowHeight: 56,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  columns: [
                    const DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Color(0xFF1976D2)),
                          SizedBox(width: 8),
                          Text(
                            'Año',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.account_balance_wallet, size: 16, color: Color(0xFF1976D2)),
                          SizedBox(width: 8),
                          Text(
                            'Total Acumulado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.trending_up, size: 16, color: Color(0xFF1976D2)),
                          SizedBox(width: 8),
                          Text(
                            'Rendimiento',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_tieneAportaciones)
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(
                              _aportacionesTotal >= 0 ? Icons.savings : Icons.money_off,
                              size: 16,
                              color: const Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _aportacionesTotal >= 0 ? 'Aportación' : 'Gasto',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  rows: _resultadosPorAnio.asMap().entries.map((entry) {
                    final index = entry.key;
                    final resultado = entry.value;
                    final isEvenRow = index % 2 == 0;
                    
                    return DataRow(
                      color: WidgetStateProperty.all(
                        isEvenRow 
                            ? Colors.grey.shade50 
                            : Colors.white,
                      ),
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${resultado['anio']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BCD4).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00BCD4).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _formatCurrency(resultado['total']),
                              style: const TextStyle(
                                color: Color(0xFF00838F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatCurrency(resultado['rendimiento']),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_tieneAportaciones)
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: (resultado['aportacion'] >= 0
                                        ? Colors.purple
                                        : Colors.red)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (resultado['aportacion'] >= 0
                                          ? Colors.purple
                                          : Colors.red)
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _formatCurrency(resultado['aportacion'].abs()),
                                style: TextStyle(
                                  color: resultado['aportacion'] >= 0
                                      ? Colors.purple.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
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
      ),
    );
  }
}
