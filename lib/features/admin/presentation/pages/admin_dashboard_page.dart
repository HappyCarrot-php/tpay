import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/movimiento_model.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/repositories/perfil_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

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
    '¿Preparado para seguir?',
  ];

  bool _isLoading = true;
  int _totalPrestamos = 0;
  int _capitalTotal = 0;
  int _capitalTrabajando = 0;
  int _capitalLiberado = 0;
  int _gananciasNetas = 0;
  List<MovimientoModel> _prestamosActivos = [];
  List<MovimientoModel> _prestamosPagados = [];
  double _saldoPendienteActivos = 0;
  double _totalAbonosRecibidos = 0;
  double _promedioAbonosActivos = 0;
  double _promedioInteres = 0;
  double _montoPromedio = 0;
  double _prestamosPromedioMensual = 0;
  double _tasaRecuperacion = 0;
  double _tasaMora = 0;
  int _prestamosVencidos = 0;
  double _capitalVencido = 0;
  double _promedioDuracionDias = 0;
  double _porcentajePrestamosPagados = 0;
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
      final nombreFormateado = [
        apellido,
        nombre,
      ].where((parte) => parte.isNotEmpty).join(' ');
      final frase = _obtenerFraseAleatoria();

      if (!mounted) return;
      setState(() {
        _saludoBase = saludo;
        _nombreSaludo = nombreFormateado.isNotEmpty
            ? nombreFormateado
            : 'Administrador';
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

      double capitalTotal = 0;
      double capitalTrabajando = 0;
      double capitalLiberado = 0;
      double gananciasNetas = 0;
      double totalAbonosActivos = 0;
      double totalAbonosPagados = 0;
      double saldoPendienteActivos = 0;
      double capitalVencido = 0;
      int prestamosVencidos = 0;

      for (final prestamo in todos) {
        capitalTotal += prestamo.monto + prestamo.interes;
        gananciasNetas += prestamo.interes;
      }

      for (final prestamo in activos) {
        final totalPrestamo = prestamo.monto + prestamo.interes;
        capitalTrabajando += totalPrestamo - prestamo.abonos;
        saldoPendienteActivos += prestamo.saldoPendiente;
        totalAbonosActivos += prestamo.abonos;

        if (prestamo.estaVencido) {
          prestamosVencidos++;
          capitalVencido += prestamo.saldoPendiente;
        }
      }

      for (final prestamo in pagados) {
        capitalLiberado += prestamo.monto + prestamo.interes;
        totalAbonosPagados += prestamo.abonos;
      }

      capitalLiberado += totalAbonosActivos;

      final totalAbonosRecibidos = totalAbonosActivos + totalAbonosPagados;
      final promedioAbonosActivos = activos.isNotEmpty
          ? totalAbonosActivos / activos.length
          : 0.0;
      final tasaRecuperacion = capitalTotal > 0
          ? (capitalLiberado / capitalTotal) * 100
          : 0.0;
      final tasaMora = todos.isNotEmpty
          ? (prestamosVencidos / todos.length) * 100
          : 0.0;
      final promedioInteres = todos.isNotEmpty
          ? gananciasNetas / todos.length
          : 0.0;
      final montoPromedio = todos.isNotEmpty
          ? capitalTotal / todos.length
          : 0.0;

      DateTime? fechaMasAntigua;
      for (final prestamo in todos) {
        final inicio = prestamo.fechaInicio;
        if (fechaMasAntigua == null || inicio.isBefore(fechaMasAntigua)) {
          fechaMasAntigua = inicio;
        }
      }

      final diasOperando = fechaMasAntigua != null
          ? DateTime.now().difference(fechaMasAntigua).inDays
          : 0;
      final mesesOperando = diasOperando > 0 ? diasOperando / 30 : 1.0;
      final prestamosPromedioMensual = mesesOperando > 0
          ? todos.length / mesesOperando
          : todos.length.toDouble();

      final totalDiasPrestamos = todos.fold<int>(
        0,
        (acumulado, prestamo) => acumulado + prestamo.diasPrestamo,
      );
      final promedioDuracionDias = todos.isNotEmpty
          ? totalDiasPrestamos / todos.length
          : 0.0;

      final porcentajePrestamosPagados = todos.isNotEmpty
          ? (pagados.length / todos.length) * 100
          : 0.0;

      setState(() {
        _totalPrestamos = todos.length;
        _prestamosActivos = activos;
        _prestamosPagados = pagados;
        _capitalTotal = capitalTotal.round();
        _capitalTrabajando = capitalTrabajando.round();
        _capitalLiberado = capitalLiberado.round();
        _gananciasNetas = gananciasNetas.round();
        _saldoPendienteActivos = saldoPendienteActivos;
        _totalAbonosRecibidos = totalAbonosRecibidos;
        _promedioAbonosActivos = promedioAbonosActivos;
        _promedioInteres = promedioInteres;
        _montoPromedio = montoPromedio;
        _prestamosPromedioMensual = prestamosPromedioMensual;
        _tasaRecuperacion = tasaRecuperacion;
        _tasaMora = tasaMora;
        _prestamosVencidos = prestamosVencidos;
        _capitalVencido = capitalVencido;
        _promedioDuracionDias = promedioDuracionDias;
        _porcentajePrestamosPagados = porcentajePrestamosPagados;
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
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('dd MMM', 'es_MX').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              await Future.wait([_cargarEstadisticas(), _cargarSaludo()]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_saludoBase.isNotEmpty ? _saludoBase : _obtenerSaludoSegunHora(DateTime.now())}, ${_nombreSaludo.isNotEmpty ? _nombreSaludo : 'Administrador'}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fraseSaludo.isNotEmpty
                              ? _fraseSaludo
                              : '¿Cómo estás hoy?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildKPICards(),
                  const SizedBox(height: 16),
                  const Text(
                    'Resumen Financiero',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 24),
                  _buildInsightsSection(),
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
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.teal,
                    ),
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
          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildGraficaCapitalTrabajando() {
    final porcentaje = _capitalTotal > 0
        ? (_capitalTrabajando / _capitalTotal) * 100
        : 0.0;

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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
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
          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildGraficaCapitalLiberado() {
    final porcentaje = _capitalTotal > 0
        ? (_capitalLiberado / _capitalTotal) * 100
        : 0.0;

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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
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
          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildGraficaGananciasNetas() {
    final porcentaje = _capitalTotal > 0
        ? (_gananciasNetas / _capitalTotal) * 100
        : 0.0;

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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.purple,
                    ),
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
          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildResumenTexto() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark
        ? theme.colorScheme.surfaceVariant.withOpacity(0.35)
        : Colors.white;
    final Color borderColor = isDark
        ? theme.colorScheme.outlineVariant
        : Colors.transparent;
    final Color titleColor = isDark
        ? theme.colorScheme.onSurface
        : const Color(0xFF1A237E);
    final Color labelColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF546E7A);

    return Card(
      elevation: isDark ? 0 : 4,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: isDark ? 1 : 0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen Financiero',
              style:
                  theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ) ??
                  TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
            ),
            const SizedBox(height: 16),
            _buildResumenRow(
              'Capital Total',
              _formatCurrency(_capitalTotal.toDouble()),
              const Color(0xFF1565C0),
              labelColor: labelColor,
            ),
            _buildResumenRow(
              'Capital Trabajando',
              _formatCurrency(_capitalTrabajando.toDouble()),
              const Color(0xFF2E7D32),
              labelColor: labelColor,
            ),
            _buildResumenRow(
              'Capital Liberado',
              _formatCurrency(_capitalLiberado.toDouble()),
              const Color(0xFFE65100),
              labelColor: labelColor,
            ),
            _buildResumenRow(
              'Ganancias Netas',
              _formatCurrency(_gananciasNetas.toDouble()),
              const Color(0xFF6A1B9A),
              labelColor: labelColor,
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
    Color? labelColor,
  }) {
    final theme = Theme.of(context);
    final Color resolvedLabelColor = labelColor ?? const Color(0xFF546E7A);
    final TextStyle labelStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: resolvedLabelColor,
        ) ??
        TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: resolvedLabelColor,
        );
    final TextStyle valueStyle =
        theme.textTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ) ??
        TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(child: Text(label, style: labelStyle)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(value, style: valueStyle),
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color interesColor = isDark
        ? const Color(0xFFFFD54F)
        : const Color(0xFFFFB74D);
    final Color montoColor = isDark
        ? const Color(0xFF4DD0E1)
        : const Color(0xFF26C6DA);

    final indicatorRows = [
      [
        _IndicatorConfig(
          label: 'Tasa de Recuperación',
          value: '${_tasaRecuperacion.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: _tasaRecuperacion >= 70 ? Colors.green : Colors.orange,
        ),
        _IndicatorConfig(
          label: '% Préstamos Pagados',
          value: '${_porcentajePrestamosPagados.toStringAsFixed(1)}%',
          icon: Icons.task_alt,
          color: const Color(0xFF00ACC1),
        ),
      ],
      [
        _IndicatorConfig(
          label: 'Préstamos en Mora',
          value:
              '${_prestamosVencidos.toString()} (${_tasaMora.toStringAsFixed(1)}%)',
          icon: Icons.warning_amber,
          color: _tasaMora > 10 ? Colors.red : Colors.orange,
        ),
        _IndicatorConfig(
          label: 'Capital en Mora',
          value: _formatCurrency(_capitalVencido),
          icon: Icons.report,
          color: Colors.deepOrange,
        ),
      ],
      [
        _IndicatorConfig(
          label: 'Saldo por Cobrar',
          value: _formatCurrency(_saldoPendienteActivos),
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF1976D2),
        ),
        _IndicatorConfig(
          label: 'Total Abonos',
          value: _formatCurrency(_totalAbonosRecibidos),
          icon: Icons.payments,
          color: Colors.teal,
        ),
      ],
      [
        _IndicatorConfig(
          label: 'Préstamos/Mes',
          value: _prestamosPromedioMensual.toStringAsFixed(1),
          icon: Icons.calendar_month,
          color: Colors.indigo,
        ),
        _IndicatorConfig(
          label: 'Promedio Abonos Activos',
          value: _formatCurrency(_promedioAbonosActivos),
          icon: Icons.savings,
          color: Colors.purple,
        ),
      ],
      [
        _IndicatorConfig(
          label: 'Interés Promedio',
          value: _formatCurrency(_promedioInteres),
          icon: Icons.attach_money,
          color: interesColor,
        ),
        _IndicatorConfig(
          label: 'Monto Promedio',
          value: _formatCurrency(_montoPromedio),
          icon: Icons.stacked_line_chart,
          color: montoColor,
        ),
      ],
    ];

    return Column(
      children: [
        const Text(
          'Indicadores Clave',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < indicatorRows.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: _buildIndicadorCard(
                  context,
                  indicatorRows[i][0].label,
                  indicatorRows[i][0].value,
                  indicatorRows[i][0].icon,
                  indicatorRows[i][0].color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndicadorCard(
                  context,
                  indicatorRows[i][1].label,
                  indicatorRows[i][1].value,
                  indicatorRows[i][1].icon,
                  indicatorRows[i][1].color,
                ),
              ),
            ],
          ),
          if (i != indicatorRows.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildIndicadorCard(
    BuildContext context,
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    final theme = Theme.of(context);
    final proximos = List<MovimientoModel>.from(_prestamosActivos)
      ..sort((a, b) => a.fechaPago.compareTo(b.fechaPago));
    final upcoming = proximos.where((p) => !p.estadoPagado).take(4).toList();

    final capitalEnRiesgo = _prestamosActivos
        .where((loan) => loan.estaVencido)
        .fold<double>(0, (sum, loan) => sum + loan.saldoPendiente);

    final clientesMapa = <int, _ClientInsight>{};
    for (final prestamo in _prestamosActivos) {
      final insight = clientesMapa.putIfAbsent(
        prestamo.idCliente,
        () => _ClientInsight(
          name: prestamo.nombreCliente ?? 'Cliente ${prestamo.idCliente}',
        ),
      );
      insight.totalPendiente += prestamo.saldoPendiente;
      insight.prestamos += 1;
    }

    final topClientes = clientesMapa.values.toList()
      ..sort((a, b) => b.totalPendiente.compareTo(a.totalPendiente));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights del mes',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildInsightMetrics(capitalEnRiesgo),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildUpcomingLoansCard(upcoming),
        ] else ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay vencimientos próximos en la agenda.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (topClientes.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildTopClientsCard(topClientes.take(3).toList()),
        ],
      ],
    );
  }

  Widget _buildInsightMetrics(double capitalEnRiesgo) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildInsightPill(
          icon: Icons.restart_alt,
          label: 'Recuperación',
          value: '${_tasaRecuperacion.toStringAsFixed(1)}%',
          color: Colors.green,
        ),
        _buildInsightPill(
          icon: Icons.shield_outlined,
          label: 'Capital en riesgo',
          value: _formatCurrency(capitalEnRiesgo),
          color: theme.colorScheme.tertiary,
        ),
        _buildInsightPill(
          icon: Icons.warning_amber_outlined,
          label: 'Préstamos vencidos',
          value: '$_prestamosVencidos',
          color: Colors.orange,
        ),
        _buildInsightPill(
          icon: Icons.percent,
          label: 'Tasa de mora',
          value: '${_tasaMora.toStringAsFixed(1)}%',
          color: theme.colorScheme.error,
        ),
        _buildInsightPill(
          icon: Icons.timelapse,
          label: 'Duración promedio',
          value: '${_promedioDuracionDias.toStringAsFixed(0)} días',
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildInsightPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingLoansCard(List<MovimientoModel> loans) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Próximos vencimientos',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < loans.length; i++) ...[
              _buildUpcomingLoanTile(loans[i], theme),
              if (i != loans.length - 1) const Divider(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingLoanTile(MovimientoModel loan, ThemeData theme) {
    final statusColor = Color(loan.estadoColor);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.15),
        child: Icon(Icons.event_available, color: statusColor),
      ),
      title: Text(
        loan.nombreCliente ?? 'Cliente ${loan.idCliente}',
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        '${_formatShortDate(loan.fechaPago)} • ${_formatCurrency(loan.totalAPagar)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            loan.estadoTexto,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${loan.porcentajePagado.toStringAsFixed(0)}% pagado',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTopClientsCard(List<_ClientInsight> clients) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Clientes destacados', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < clients.length; i++) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondary.withOpacity(
                    0.15,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                ),
                title: Text(
                  clients[i].name,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Pendiente: ${_formatCurrency(clients[i].totalPendiente)}',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: Chip(
                  backgroundColor: theme.colorScheme.secondary.withOpacity(
                    0.15,
                  ),
                  label: Text(
                    '${clients[i].prestamos} préstamos',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (i != clients.length - 1) const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}

class _IndicatorConfig {
  const _IndicatorConfig({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ClientInsight {
  _ClientInsight({required this.name});

  final String name;
  double totalPendiente = 0;
  int prestamos = 0;
}
