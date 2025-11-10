import 'package:flutter/material.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/models/movimiento_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _movimientoRepo = MovimientoRepository();

  bool _isLoading = true;
  int _totalPrestamos = 0;
  int _capitalTotal = 0;
  int _capitalTrabajando = 0;
  int _capitalLiberado = 0;
  int _gananciasNetas = 0;
  double _tipoCambioUSD = 17.0; // Tipo de cambio por defecto
  List<MovimientoModel> _prestamosActivos = [];
  List<MovimientoModel> _prestamosPagados = [];

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
    _obtenerTipoCambio();
  }

  Future<void> _obtenerTipoCambio() async {
    try {
      // Aquí podrías hacer una petición a una API de tipo de cambio
      // Por ahora usaremos un valor fijo de 17 MXN por USD
      // Puedes integrar una API como: https://api.exchangerate-api.com/v4/latest/USD
      setState(() {
        _tipoCambioUSD = 17.0;
      });
    } catch (e) {
      // Si falla, usar valor por defecto
      setState(() {
        _tipoCambioUSD = 17.0;
      });
    }
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _isLoading = true);

    try {
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

      int capitalTotal = 0;
      int capitalTrabajando = 0;
      int capitalLiberado = 0;
      int gananciasNetas = 0;

      // Capital Total = suma de todos los montos + intereses (de TODOS los préstamos)
      for (var prestamo in todos) {
        capitalTotal += (prestamo.monto + prestamo.interes).toInt();
      }

      // Capital Trabajando = suma de (monto + interes - abonos) solo de préstamos ACTIVOS
      for (var prestamo in activos) {
        capitalTrabajando += (prestamo.monto + prestamo.interes - prestamo.abonos).toInt();
      }

      // Capital Liberado = total de préstamos pagados (monto + interés) + abonos de activos
      for (var prestamo in pagados) {
        capitalLiberado += (prestamo.monto + prestamo.interes).toInt();
      }
      for (var prestamo in activos) {
        capitalLiberado += prestamo.abonos.toInt();
      }

      // Ganancias Netas = suma de TODOS los intereses
      for (var prestamo in todos) {
        gananciasNetas += prestamo.interes.toInt();
      }

      setState(() {
        _totalPrestamos = todos.length;
        _prestamosActivos = activos;
        _prestamosPagados = pagados;
        _capitalTotal = capitalTotal;
        _capitalTrabajando = capitalTrabajando;
        _capitalLiberado = capitalLiberado;
        _gananciasNetas = gananciasNetas;
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _cargarEstadisticas,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildKPICards(),
                  const SizedBox(height: 16),
                  const Text(
                    'Resumen Financiero',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Grid de 2 columnas para las primeras 3 gráficas
                  _buildGraficasGrid(),
                  const SizedBox(height: 24),
                  const Divider(thickness: 2),
                  const SizedBox(height: 16),
                  _buildResumenTexto(),
                ],
              ),
            ),
          );
  }

  Widget _buildGraficasGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildGraficaCapitalTotal()),
            const SizedBox(width: 12),
            Expanded(child: _buildGraficaCapitalTrabajando()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildGraficaCapitalLiberado()),
            const SizedBox(width: 12),
            Expanded(child: _buildGraficaGananciasNetas()),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICards() {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Préstamos',
            _totalPrestamos.toString(),
            Icons.receipt_long,
            const Color(0xFF00BCD4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Activos',
            _prestamosActivos.length.toString(),
            Icons.trending_up,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Pagados',
            _prestamosPagados.length.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficaCapitalTotal() {
    final porcentaje = _capitalTotal > 0 ? 100.0 : 0.0;
    
    return Column(
      children: [
        const Text(
          'Capital + Intereses',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: Colors.teal.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${porcentaje.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      _formatCurrency(_capitalTotal.toDouble()),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Todos los montos + intereses',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGraficaCapitalTrabajando() {
    final porcentaje = _capitalTotal > 0 ? (_capitalTrabajando / _capitalTotal) * 100 : 0.0;
    
    return Column(
      children: [
        const Text(
          'Capital Trabajando',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: porcentaje / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.green.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${porcentaje.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      _formatCurrency(_capitalTrabajando.toDouble()),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Activos (sin abonos)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGraficaCapitalLiberado() {
    final porcentaje = _capitalTotal > 0 ? (_capitalLiberado / _capitalTotal) * 100 : 0.0;
    
    return Column(
      children: [
        const Text(
          'Capital Liberado',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: porcentaje / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${porcentaje.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      _formatCurrency(_capitalLiberado.toDouble()),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pagados + abonos',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGraficaGananciasNetas() {
    final porcentaje = _capitalTotal > 0 ? (_gananciasNetas / _capitalTotal) * 100 : 0.0;
    
    return Column(
      children: [
        const Text(
          'Ganancias Netas',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: Colors.purple.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${porcentaje.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(_gananciasNetas.toDouble()),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Solo intereses',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildResumenTexto() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen Financiero',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // MXN
            const Text(
              'Montos en MXN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BCD4),
              ),
            ),
            const Divider(),
            _buildResumenRow('Capital Total', _formatCurrency(_capitalTotal.toDouble()), Colors.teal),
            _buildResumenRow('Capital Trabajando', _formatCurrency(_capitalTrabajando.toDouble()), Colors.green),
            _buildResumenRow('Capital Liberado', _formatCurrency(_capitalLiberado.toDouble()), Colors.orange),
            _buildResumenRow('Ganancias Netas', _formatCurrency(_gananciasNetas.toDouble()), Colors.purple),
            
            const SizedBox(height: 20),
            
            // USD
            Text(
              'Equivalente en USD (1 USD = \$${_tipoCambioUSD.toStringAsFixed(2)} MXN)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(),
            _buildResumenRow('Capital Total', _formatUSD(_capitalTotal / _tipoCambioUSD), Colors.teal),
            _buildResumenRow('Capital Trabajando', _formatUSD(_capitalTrabajando / _tipoCambioUSD), Colors.green),
            _buildResumenRow('Capital Liberado', _formatUSD(_capitalLiberado / _tipoCambioUSD), Colors.orange),
            _buildResumenRow('Ganancias Netas', _formatUSD(_gananciasNetas / _tipoCambioUSD), Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatUSD(double amount) {
    return '\$${amount.toStringAsFixed(2)} USD';
  }
}
