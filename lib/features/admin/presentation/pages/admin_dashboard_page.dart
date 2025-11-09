import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/repositories/cliente_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _movimientoRepo = MovimientoRepository();
  final _clienteRepo = ClienteRepository();

  bool _isLoading = true;
  int _totalClientes = 0;
  int _prestamosActivos = 0;
  int _prestamosPagados = 0;
  double _montoPrestado = 0;
  double _montoRecuperado = 0;
  double _saldoPendiente = 0;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _isLoading = true);

    try {
      // Obtener todos los clientes
      final clientes = await _clienteRepo.obtenerClientes();
      
      // Obtener todos los préstamos
      final todos = await _movimientoRepo.obtenerMovimientos(
        filtro: FiltroEstadoPrestamo.todos,
        limite: 1000,
      );
      
      final activos = await _movimientoRepo.obtenerMovimientos(
        filtro: FiltroEstadoPrestamo.activos,
        limite: 1000,
      );
      
      final pagados = await _movimientoRepo.obtenerMovimientos(
        filtro: FiltroEstadoPrestamo.pagados,
        limite: 1000,
      );

      // Calcular totales
      double totalPrestado = 0;
      double totalRecuperado = 0;
      double totalPendiente = 0;

      for (var prestamo in todos) {
        totalPrestado += prestamo.totalAPagar;
        totalRecuperado += prestamo.abonos;
        totalPendiente += prestamo.saldoPendiente;
      }

      setState(() {
        _totalClientes = clientes.length;
        _prestamosActivos = activos.length;
        _prestamosPagados = pagados.length;
        _montoPrestado = totalPrestado;
        _montoRecuperado = totalRecuperado;
        _saldoPendiente = totalPendiente;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF00BCD4),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEstadisticas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarEstadisticas,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPIs Cards
                    _buildKPICards(),
                    const SizedBox(height: 24),

                    // Gráfica 1: Estado de Préstamos (Pie Chart)
                    _buildSectionTitle('Estado de Préstamos'),
                    _buildPrestamosChart(),
                    const SizedBox(height: 24),

                    // Gráfica 2: Montos (Bar Chart)
                    _buildSectionTitle('Resumen Financiero'),
                    _buildMontosChart(),
                    const SizedBox(height: 24),

                    // Gráfica 3: Recuperación (Gauge/Circular)
                    _buildSectionTitle('Tasa de Recuperación'),
                    _buildRecuperacionChart(),
                    const SizedBox(height: 24),

                    // Gráfica 4: Clientes Activos (Line Chart simulado)
                    _buildSectionTitle('Métricas de Clientes'),
                    _buildClientesMetrics(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPICards() {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Clientes',
            _totalClientes.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Activos',
            _prestamosActivos.toString(),
            Icons.trending_up,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Pagados',
            _prestamosPagados.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrestamosChart() {
    final total = _prestamosActivos + _prestamosPagados;
    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No hay datos para mostrar')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: _prestamosActivos.toDouble(),
                      title: '$_prestamosActivos',
                      color: Colors.orange,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: _prestamosPagados.toDouble(),
                      title: '$_prestamosPagados',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Activos', Colors.orange, _prestamosActivos),
                const SizedBox(width: 24),
                _buildLegendItem('Pagados', Colors.green, _prestamosPagados),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
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
        Text('$label ($value)'),
      ],
    );
  }

  Widget _buildMontosChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _montoPrestado * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Prestado', 'Recuperado', 'Pendiente'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              titles[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: _montoPrestado,
                          color: const Color(0xFF00BCD4),
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: _montoRecuperado,
                          color: Colors.green,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: _saldoPendiente,
                          color: Colors.red,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMontoSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildMontoSummary() {
    return Column(
      children: [
        _buildMontoRow('Total Prestado', _montoPrestado, const Color(0xFF00BCD4)),
        _buildMontoRow('Recuperado', _montoRecuperado, Colors.green),
        _buildMontoRow('Pendiente', _saldoPendiente, Colors.red),
      ],
    );
  }

  Widget _buildMontoRow(String label, double monto, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            _formatCurrency(monto),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecuperacionChart() {
    final tasaRecuperacion = _montoPrestado > 0
        ? (_montoRecuperado / _montoPrestado) * 100
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: tasaRecuperacion / 100,
                      strokeWidth: 20,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tasaRecuperacion >= 75
                            ? Colors.green
                            : tasaRecuperacion >= 50
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${tasaRecuperacion.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Recuperado',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      _formatCurrency(_montoRecuperado),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text('Recuperado', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      _formatCurrency(_saldoPendiente),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Text('Pendiente', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientesMetrics() {
    final promedioPrestamoPorCliente = _totalClientes > 0
        ? (_prestamosActivos + _prestamosPagados) / _totalClientes
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricRow(
              'Total de Clientes',
              _totalClientes.toString(),
              Icons.people,
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Promedio Préstamos/Cliente',
              promedioPrestamoPorCliente.toStringAsFixed(1),
              Icons.trending_up,
              Colors.purple,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Clientes con Deuda',
              _prestamosActivos.toString(),
              Icons.warning,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
