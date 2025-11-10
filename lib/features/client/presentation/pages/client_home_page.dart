import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../admin/data/repositories/movimiento_repository.dart';
import '../../../admin/data/repositories/cliente_repository.dart';
import '../../../admin/data/models/movimiento_model.dart';
import '../widgets/client_loan_action_buttons.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      // Obtener email del usuario autenticado
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null) {
        throw Exception('No se pudo obtener el email del usuario');
      }

      // Buscar cliente por email
      final cliente = await _clienteRepo.buscarClientePorEmail(email);
      if (cliente == null) {
        throw Exception('No hay préstamos asociados a tu cuenta. Contacta al moderador.');
      }

      final clienteId = cliente.id;

      // Cargar préstamos del cliente
      final prestamos = await _movimientoRepo.obtenerMovimientos(
        clienteId: clienteId,
        filtro: _filtroActual,
      );

      // Cargar deuda total
      final deuda = await _clienteRepo.obtenerDeudaTotal(clienteId);

      setState(() {
        _prestamos = prestamos;
        _deudaTotal = deuda;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cambiarFiltro(FiltroEstadoPrestamo nuevoFiltro) {
    setState(() => _filtroActual = nuevoFiltro);
    _cargarDatos();
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
        backgroundColor: const Color(0xFF00BCD4),
      ),
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
                    color: Colors.grey[100],
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
                            padding: const EdgeInsets.all(8),
                            itemCount: _prestamos.length,
                            itemBuilder: (context, index) {
                              return _buildPrestamoCard(_prestamos[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDeudaTotalCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _deudaTotal > 0
              ? [Colors.red[400]!, Colors.red[600]!]
              : [Colors.green[400]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_deudaTotal > 0 ? Colors.red : Colors.green)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _deudaTotal > 0
                    ? Icons.account_balance_wallet
                    : Icons.check_circle,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              const Text(
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
            _deudaTotal > 0 ? 'Monto pendiente de pago' : 'Sin deuda activa',
            style: const TextStyle(
              color: Colors.white70,
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
        selectedColor: const Color(0xFF00BCD4),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPrestamoCard(MovimientoModel prestamo) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _mostrarDetalles(prestamo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: Color(prestamo.estadoColor),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Préstamo #${prestamo.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(prestamo.estadoColor).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(prestamo.estadoColor).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      prestamo.estadoTexto,
                      style: TextStyle(
                        color: Color(prestamo.estadoColor),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Monto y Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monto Prestado',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(prestamo.monto),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total a Pagar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(prestamo.totalAPagar),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00BCD4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progreso de pago
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso de Pago',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${prestamo.porcentajePagado.toInt()}%',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: prestamo.porcentajePagado / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        prestamo.estadoPagado
                            ? Colors.green
                            : const Color(0xFF00BCD4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Saldo pendiente y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Pendiente',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(prestamo.saldoPendiente),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: prestamo.estadoPagado
                              ? Colors.green
                              : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        prestamo.estaVencido ? 'Vencido' : 'Vence',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            prestamo.estaVencido
                                ? Icons.warning
                                : Icons.calendar_today,
                            size: 14,
                            color: prestamo.estaVencido
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(prestamo.fechaPago),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: prestamo.estaVencido
                                  ? Colors.red
                                  : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      if (prestamo.estaVencido)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${prestamo.diasVencido} días de retraso',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalles(MovimientoModel prestamo) {
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.grey[300],
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
                'Saldo Pendiente',
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
                  'Días de Retraso',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFF00BCD4).withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF00BCD4).withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? const Color(0xFF00BCD4).withOpacity(0.2)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isHighlighted ? const Color(0xFF00BCD4) : Colors.grey[600],
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
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isHighlighted ? 18 : 16,
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.w500,
                    color: valueColor ?? Colors.black87,
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
