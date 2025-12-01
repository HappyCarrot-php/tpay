import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models/movimiento_model.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/repositories/perfil_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _movimientoRepo = MovimientoRepository();
  final _perfilRepo = PerfilRepository();
  final Random _random = Random();

  static const List<String> _frasesSaludo = [
    '¿Cómo estás hoy?',
    '¿Qué tal tu día?',
    '¿Todo en orden?',
    '¿Listo para revisar los números?',
    '¿Preparado para seguir?'
  ];

  bool _isLoading = true;
  int _totalPrestamos = 0;
  int _capitalTotal = 0;
  int _capitalTrabajando = 0;
  int _capitalLiberado = 0;
  int _gananciasNetas = 0;
  List<MovimientoModel> _prestamosActivos = [];
  List<MovimientoModel> _prestamosPagados = [];
  String _saludoBase = '';
  String _nombreSaludo = '';
  String _fraseSaludo = '';

  @override
  void initState() {
    super.initState();
    _cargarSaludo();
    _cargarEstadisticas();
  }

  Future<void> _cargarSaludo() async {
    try {
      final perfil = await _perfilRepo.obtenerPerfilActual();
      final ahora = DateTime.now();
      final saludo = _obtenerSaludoSegunHora(ahora);
      final apellido = (perfil?.apellidoPaterno ?? '').trim();
      final nombre = (perfil?.nombre ?? '').trim();
      final nombreFormateado = [apellido, nombre]
          .where((parte) => parte.isNotEmpty)
          .join(' ');
      final frase = _obtenerFraseAleatoria();

      if (!mounted) return;
      setState(() {
        _saludoBase = saludo;
        _nombreSaludo = nombreFormateado.isNotEmpty ? nombreFormateado : 'Administrador';
        _fraseSaludo = frase;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saludoBase = _obtenerSaludoSegunHora(DateTime.now());
        _nombreSaludo = 'Administrador';
        _fraseSaludo = _obtenerFraseAleatoria();
      });
    }
  }

  String _obtenerSaludoSegunHora(DateTime fecha) {
    final hora = fecha.hour;
    if (hora >= 5 && hora < 12) {
      return 'Buenos días';
    } else if (hora >= 12 && hora < 19) {
      return 'Buenas tardes';
    }
    return 'Buenas noches';
  }

  String _obtenerFraseAleatoria() {
    if (_frasesSaludo.isEmpty) {
      return '¿Cómo estás hoy?';
    }
    final indice = _random.nextInt(_frasesSaludo.length);
    return _frasesSaludo[indice];
  }

  String get _textoSaludo {
    final saludo = _saludoBase.isNotEmpty
        ? _saludoBase
        : _obtenerSaludoSegunHora(DateTime.now());
    final nombre = _nombreSaludo.isNotEmpty ? _nombreSaludo : 'Administrador';
    final frase = _fraseSaludo.isNotEmpty ? _fraseSaludo : '¿Cómo estás hoy?';
    return '$saludo, $nombre, $frase';
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
            onRefresh: () async {
              await Future.wait([
                _cargarEstadisticas(),
                _cargarSaludo(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _textoSaludo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 24),
                  _buildGraficaBarrasComparativa(),
                  const SizedBox(height: 24),
                  _buildEstadisticasAdicionales(),
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
      color: Colors.white, // Fondo blanco
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
                color: Color(0xFF1A237E), // Título azul oscuro formal
              ),
            ),
            const SizedBox(height: 16),
            _buildResumenRow('Capital Total', _formatCurrency(_capitalTotal.toDouble()), const Color(0xFF1565C0)),
            _buildResumenRow('Capital Trabajando', _formatCurrency(_capitalTrabajando.toDouble()), const Color(0xFF2E7D32)),
            _buildResumenRow('Capital Liberado', _formatCurrency(_capitalLiberado.toDouble()), const Color(0xFFE65100)),
            _buildResumenRow('Ganancias Netas', _formatCurrency(_gananciasNetas.toDouble()), const Color(0xFF6A1B9A)),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF546E7A), // Gris azulado formal
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

  Widget _buildGraficaBarrasComparativa() {
    final maxValue = [
      _capitalTotal.toDouble(),
      _capitalTrabajando.toDouble(),
      _capitalLiberado.toDouble(),
    ].reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparativa General',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildBarra(
              'Capital Total',
              _capitalTotal.toDouble(),
              maxValue,
              const Color(0xFF1976D2),
            ),
            const SizedBox(height: 16),
            _buildBarra(
              'Capital Trabajando',
              _capitalTrabajando.toDouble(),
              maxValue,
              const Color(0xFF388E3C),
            ),
            const SizedBox(height: 16),
            _buildBarra(
              'Capital Liberado',
              _capitalLiberado.toDouble(),
              maxValue,
              const Color(0xFFF57C00),
            ),
            const SizedBox(height: 16),
            _buildBarra(
              'Préstamos Pagados',
              _prestamosPagados.length.toDouble(),
              _totalPrestamos.toDouble(),
              const Color(0xFF4CAF50),
              isCount: true,
            ),
            const SizedBox(height: 16),
            _buildBarra(
              'Préstamos Activos',
              _prestamosActivos.length.toDouble(),
              _totalPrestamos.toDouble(),
              const Color(0xFFFF9800),
              isCount: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarra(
    String label,
    double value,
    double maxValue,
    Color color, {
    bool isCount = false,
  }) {
    final porcentaje = maxValue > 0 ? (value / maxValue) : 0.0;
    final displayValue = isCount
        ? value.toInt().toString()
        : _formatCurrency(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: porcentaje,
            minHeight: 24,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasAdicionales() {
    final tasaRecuperacion = _capitalTotal > 0
        ? (_capitalLiberado / _capitalTotal) * 100
        : 0.0;
    final promedioAbonos = _prestamosActivos.isNotEmpty
        ? _capitalLiberado / _prestamosActivos.length
        : 0.0;
    final promedioInteres = _totalPrestamos > 0
        ? _gananciasNetas / _totalPrestamos
        : 0.0;
    
    // Calcular préstamos promedio mensual basado en TODOS los préstamos
    DateTime? fechaMasAntigua;
    for (var prestamo in _prestamosActivos) {
      if (fechaMasAntigua == null || prestamo.fechaInicio.isBefore(fechaMasAntigua)) {
        fechaMasAntigua = prestamo.fechaInicio;
      }
    }
    for (var prestamo in _prestamosPagados) {
      if (fechaMasAntigua == null || prestamo.fechaInicio.isBefore(fechaMasAntigua)) {
        fechaMasAntigua = prestamo.fechaInicio;
      }
    }
    
    final diasOperando = fechaMasAntigua != null
        ? DateTime.now().difference(fechaMasAntigua).inDays
        : 0;
    final mesesOperando = diasOperando > 0 ? diasOperando / 30 : 1;
    final prestamosPromedioMensual = mesesOperando > 0
        ? _totalPrestamos / mesesOperando
        : 0.0;
    
    // Calcular monto promedio de préstamo
    final montoPromedioPrestamo = _totalPrestamos > 0
        ? _capitalTotal / _totalPrestamos
        : 0.0;

    return Column(
      children: [
        const Text(
          'Indicadores Clave',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildIndicadorCard(
                'Tasa de Recuperación',
                '${tasaRecuperacion.toStringAsFixed(1)}%',
                Icons.trending_up,
                tasaRecuperacion >= 70 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIndicadorCard(
                'Total Préstamos',
                _totalPrestamos.toString(),
                Icons.receipt_long,
                const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildIndicadorCard(
                'Préstamos/Mes',
                prestamosPromedioMensual.toStringAsFixed(1),
                Icons.calendar_month,
                const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIndicadorCard(
                'Promedio Abonos',
                _formatCurrency(promedioAbonos),
                Icons.payment,
                const Color(0xFF388E3C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildIndicadorCard(
                'Interés Promedio',
                _formatCurrency(promedioInteres),
                Icons.attach_money,
                const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIndicadorCard(
                'Monto Promedio',
                _formatCurrency(montoPromedioPrestamo),
                Icons.account_balance_wallet,
                const Color(0xFFFF6F00),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicadorCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
