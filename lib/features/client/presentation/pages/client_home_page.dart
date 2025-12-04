import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../admin/data/repositories/movimiento_repository.dart';
import '../../../admin/data/repositories/cliente_repository.dart';
import '../../../admin/data/models/movimiento_model.dart';
import '../widgets/client_loan_action_buttons.dart';
import '../widgets/client_drawer.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final _movimientoRepo = MovimientoRepository();
  final _clienteRepo = ClienteRepository();

  List<MovimientoModel> _prestamos = [];
  FiltroEstadoPrestamo _filtroActual = FiltroEstadoPrestamo.todos;
  bool _isLoading = false;
  double _deudaTotal = 0;
  int _paginaActual = 0;
  final int _prestamosPorPagina = 5;
  final Set<int> _expandedLoans = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null) {
        throw Exception('No se pudo obtener el email del usuario');
      }

      final cliente = await _clienteRepo.buscarClientePorEmail(email);
      if (cliente == null) {
        throw Exception('No hay préstamos asociados a tu cuenta. Contacta al moderador.');
      }

      final prestamos = await _movimientoRepo.obtenerMovimientos(
        clienteId: cliente.id,
        filtro: _filtroActual,
      );

      final deuda = await _clienteRepo.obtenerDeudaTotal(cliente.id);

      setState(() {
        _prestamos = prestamos;
        _deudaTotal = deuda;
        _paginaActual = 0;
        _expandedLoans.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _cambiarFiltro(FiltroEstadoPrestamo nuevoFiltro) {
    setState(() {
      _filtroActual = nuevoFiltro;
      _paginaActual = 0;
    });
    _cargarDatos();
  }

  List<MovimientoModel> get _prestamosPaginados {
    final inicio = _paginaActual * _prestamosPorPagina;
    final fin = (inicio + _prestamosPorPagina).clamp(0, _prestamos.length).toInt();
    final inicioAjustado = inicio.clamp(0, _prestamos.length).toInt();
    return _prestamos.sublist(inicioAjustado, fin);
  }

  int get _totalPaginas => (_prestamos.length / _prestamosPorPagina).ceil();

  void _irPaginaAnterior() {
    if (_paginaActual > 0) {
      setState(() => _paginaActual--);
    }
  }

  void _irPaginaSiguiente() {
    if (_paginaActual < _totalPaginas - 1) {
      setState(() => _paginaActual++);
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'es_MX').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Préstamos'),
      ),
      drawer: const ClientDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: Column(
                children: [
                  // Card de deuda total
                  _buildDeudaTotalCard(),

                  // Filtros
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        _buildFiltroChip(
                          'Todos',
                          FiltroEstadoPrestamo.todos,
                          Icons.list,
                        ),
                        const SizedBox(width: 8),
                        _buildFiltroChip(
                          'Activos',
                          FiltroEstadoPrestamo.activos,
                          Icons.pending_actions,
                        ),
                        const SizedBox(width: 8),
                        _buildFiltroChip(
                          'Pagados',
                          FiltroEstadoPrestamo.pagados,
                          Icons.check_circle,
                        ),
                      ],
                    ),
                  ),

                  // Info header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant
                          .withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${_prestamos.length} préstamos',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _filtroActual == FiltroEstadoPrestamo.todos
                              ? 'Todos'
                              : _filtroActual == FiltroEstadoPrestamo.activos
                                  ? 'Activos'
                                  : 'Pagados',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista de préstamos
                  Expanded(
                    child: _prestamos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay préstamos para mostrar',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _prestamosPaginados.length,
                            itemBuilder: (context, index) {
                              return _buildPrestamoTile(_prestamosPaginados[index]);
                            },
                          ),
                  ),

                  // Controles de paginación
                  if (_prestamos.length > _prestamosPorPagina)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant
                            .withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).dividerColor.withOpacity(0.4),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botón anterior
                          ElevatedButton.icon(
                            onPressed: _paginaActual > 0 ? _irPaginaAnterior : null,
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Anterior'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              disabledBackgroundColor: Theme.of(context).disabledColor.withOpacity(0.2),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),

                          // Indicador de página
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
                              ),
                            ),
                            child: Text(
                              'Página ${_paginaActual + 1} de $_totalPaginas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),

                          // Botón siguiente
                          ElevatedButton.icon(
                            onPressed: _paginaActual < _totalPaginas - 1
                                ? _irPaginaSiguiente
                                : null,
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('Siguiente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              disabledBackgroundColor: Theme.of(context).disabledColor.withOpacity(0.2),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  Widget _buildDeudaTotalCard() {
    final theme = Theme.of(context);
    final hasDebt = _deudaTotal > 0;
    final startColor = hasDebt
        ? theme.colorScheme.error.withOpacity(0.85)
        : Colors.tealAccent.shade400.withOpacity(theme.brightness == Brightness.dark ? 0.7 : 0.9);
    final endColor = hasDebt
        ? theme.colorScheme.error
        : Colors.teal.shade600;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: endColor.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasDebt
                    ? Icons.account_balance_wallet
                    : Icons.check_circle,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Deuda Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(_deudaTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasDebt ? 'Monto pendiente de pago' : 'Sin deuda activa',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(
    String label,
    FiltroEstadoPrestamo filtro,
    IconData icon,
  ) {
    final isSelected = _filtroActual == filtro;
    final theme = Theme.of(context);
    return Expanded(
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) => _cambiarFiltro(filtro),
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(
          theme.brightness == Brightness.dark ? 0.35 : 0.9,
        ),
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: theme.colorScheme.onPrimary,
        showCheckmark: false,
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.25),
        ),
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPrestamoTile(MovimientoModel prestamo) {
    final theme = Theme.of(context);
    final statusColor = Color(prestamo.estadoColor);
    final isExpanded = _expandedLoans.contains(prestamo.id);
    final progreso = prestamo.totalAPagar == 0
        ? 0.0
        : (prestamo.abonos / prestamo.totalAPagar).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<int>(prestamo.id),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedLoans.add(prestamo.id);
              } else {
                _expandedLoans.remove(prestamo.id);
              }
            });
          },
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '#${prestamo.id}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Préstamo ${prestamo.id}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prestamo.estadoTexto,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(prestamo.totalAPagar),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(prestamo.fechaPago),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _buildMiniChip(
                  icon: Icons.monetization_on_outlined,
                  label: 'Monto ${_formatCurrency(prestamo.monto)}',
                  color: theme.colorScheme.primary,
                ),
                _buildMiniChip(
                  icon: Icons.wallet_outlined,
                  label: 'Pendiente ${_formatCurrency(prestamo.saldoPendiente)}',
                  color: prestamo.estadoPagado ? Colors.green : theme.colorScheme.secondary,
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progreso,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${prestamo.porcentajePagado.toStringAsFixed(1)}% pagado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLoanInfoRow(
                    icon: Icons.account_balance_wallet,
                    label: 'Abonos realizados',
                    value: _formatCurrency(prestamo.abonos),
                  ),
                  _buildLoanInfoRow(
                    icon: Icons.attach_money,
                    label: 'Interés generado',
                    value: _formatCurrency(prestamo.interes),
                  ),
                  _buildLoanInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha de inicio',
                    value: _formatDate(prestamo.fechaInicio),
                  ),
                  _buildLoanInfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Plazo',
                    value: '${prestamo.diasPrestamo} días',
                  ),
                  if (prestamo.estaVencido)
                    _buildLoanInfoRow(
                      icon: Icons.warning_amber_rounded,
                      label: 'En mora',
                      value: '${prestamo.diasVencido} días atrasado',
                      valueColor: Colors.red,
                    ),
                  const SizedBox(height: 16),
                  ClientLoanActionButtons(prestamo: prestamo),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _mostrarDetalles(prestamo),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Detalles completos'),
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

  Widget _buildMiniChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: valueColor ?? theme.textTheme.titleSmall?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalles(MovimientoModel prestamo) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalles del Préstamo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Detalles
              _buildDetalleItem(
                'ID Préstamo',
                '#${prestamo.id}',
                Icons.tag,
              ),
              _buildDetalleItem(
                'Monto Prestado',
                _formatCurrency(prestamo.monto),
                Icons.monetization_on,
              ),
              _buildDetalleItem(
                'Interés',
                _formatCurrency(prestamo.interes),
                Icons.percent,
              ),
              _buildDetalleItem(
                'Total a Pagar',
                _formatCurrency(prestamo.totalAPagar),
                Icons.account_balance,
                isHighlighted: true,
              ),
              _buildDetalleItem(
                'Abonos Realizados',
                _formatCurrency(prestamo.abonos),
                Icons.payments,
              ),
              _buildDetalleItem(
                'Pendiente',
                _formatCurrency(prestamo.saldoPendiente),
                Icons.wallet,
                valueColor: prestamo.estadoPagado ? Colors.green : Colors.red,
              ),
              const Divider(height: 32),
              _buildDetalleItem(
                'Fecha de Inicio',
                _formatDate(prestamo.fechaInicio),
                Icons.calendar_today,
              ),
              _buildDetalleItem(
                'Fecha de Vencimiento',
                _formatDate(prestamo.fechaPago),
                Icons.event,
                valueColor: prestamo.estaVencido ? Colors.red : null,
              ),
              _buildDetalleItem(
                'Plazo',
                '${prestamo.diasPrestamo} días',
                Icons.timer,
              ),
              _buildDetalleItem(
                'Estado',
                prestamo.estadoTexto,
                Icons.info,
                valueColor: Color(prestamo.estadoColor),
              ),
              if (prestamo.estaVencido)
                _buildDetalleItem(
                  'MORA',
                  '${prestamo.diasVencido} días',
                  Icons.warning,
                  valueColor: Colors.red,
                ),
              const Divider(height: 32),
              const SizedBox(height: 8),
              ClientLoanActionButtons(prestamo: prestamo),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleItem(
    String label,
    String value,
    IconData icon, {
    bool isHighlighted = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.primary;
    final backgroundColor = isHighlighted
        ? highlightColor.withOpacity(0.12)
        : theme.colorScheme.surfaceVariant.withOpacity(0.25);
    final borderColor = isHighlighted
        ? highlightColor.withOpacity(0.3)
        : theme.dividerColor.withOpacity(0.4);
    final iconBackground = isHighlighted
        ? highlightColor.withOpacity(0.2)
        : theme.colorScheme.primary.withOpacity(0.15);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isHighlighted ? highlightColor : theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isHighlighted ? 18 : 16,
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.w500,
                    color: valueColor ?? (isHighlighted
                        ? highlightColor
                        : theme.textTheme.titleMedium?.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
