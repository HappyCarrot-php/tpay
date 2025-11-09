import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/repositories/cliente_repository.dart';
import '../../data/models/movimiento_model.dart';
import '../widgets/loan_action_buttons.dart';

class AdminMovementsPage extends StatefulWidget {
  const AdminMovementsPage({super.key});

  @override
  State<AdminMovementsPage> createState() => _AdminMovementsPageState();
}

class _AdminMovementsPageState extends State<AdminMovementsPage> {
  final _searchController = TextEditingController();
  final _movimientoRepo = MovimientoRepository();
  final _clienteRepo = ClienteRepository();

  List<MovimientoModel> _movimientos = [];
  FiltroEstadoPrestamo _filtroActual = FiltroEstadoPrestamo.todos;
  bool _isLoading = false;
  bool _isSearching = false;
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  int _totalMovimientos = 0;

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);
    try {
      final movimientos = await _movimientoRepo.obtenerMovimientos(
        filtro: _filtroActual,
        limite: _itemsPerPage,
        offset: _currentPage * _itemsPerPage,
      );
      final total = await _movimientoRepo.contarMovimientos(filtro: _filtroActual);
      setState(() {
        _movimientos = movimientos;
        _totalMovimientos = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _buscarMovimientos(String query) async {
    if (query.trim().isEmpty) {
      _cargarMovimientos();
      return;
    }
    setState(() => _isSearching = true);
    try {
      final resultados = await _movimientoRepo.buscarMovimientos(query);
      setState(() {
        _movimientos = resultados;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _consultarDeudaCliente(int clienteId) async {
    try {
      final deuda = await _clienteRepo.obtenerDeudaTotal(clienteId);
      if (mounted) _mostrarDeudaDialog(clienteId, deuda);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cambiarFiltro(FiltroEstadoPrestamo nuevoFiltro) {
    setState(() {
      _filtroActual = nuevoFiltro;
      _currentPage = 0;
    });
    _cargarMovimientos();
  }

  void _cambiarPagina(int nuevaPagina) {
    setState(() => _currentPage = nuevaPagina);
    _cargarMovimientos();
  }

  int get _totalPaginas => (_totalMovimientos / _itemsPerPage).ceil();

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
        title: const Text('Movimientos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID, cliente o nombre...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _cargarMovimientos();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _buscarMovimientos,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    _buildFiltroChip('Todos', FiltroEstadoPrestamo.todos, Icons.list),
                    const SizedBox(width: 8),
                    _buildFiltroChip('Activos', FiltroEstadoPrestamo.activos, Icons.pending_actions),
                    const SizedBox(width: 8),
                    _buildFiltroChip('Pagados', FiltroEstadoPrestamo.pagados, Icons.check_circle),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _isLoading || _isSearching
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total: $_totalMovimientos préstamos', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (_totalPaginas > 0) Text('Página ${_currentPage + 1} de $_totalPaginas', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Expanded(
                  child: _movimientos.isEmpty
                      ? const Center(child: Text('No hay movimientos'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _movimientos.length,
                          itemBuilder: (context, index) => _buildMovimientoCard(_movimientos[index]),
                        ),
                ),
                if (_totalPaginas > 1) _buildPaginacion(),
              ],
            ),
    );
  }

  Widget _buildFiltroChip(String label, FiltroEstadoPrestamo filtro, IconData icon) {
    final isSelected = _filtroActual == filtro;
    return FilterChip(
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
    );
  }

  Widget _buildMovimientoCard(MovimientoModel mov) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(mov.estadoColor).withOpacity(0.2),
          child: Text('#${mov.id}', style: TextStyle(color: Color(mov.estadoColor), fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(mov.nombreCliente ?? 'Cliente #${mov.idCliente}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(mov.estadoColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(mov.estadoColor).withOpacity(0.3)),
              ),
              child: Text(mov.estadoTexto, style: TextStyle(color: Color(mov.estadoColor), fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Monto: ${_formatCurrency(mov.monto)}'),
            Text('Saldo: ${_formatCurrency(mov.saldoPendiente)}', style: TextStyle(color: mov.estadoPagado ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            Text('Vence: ${_formatDate(mov.fechaPago)}', style: TextStyle(color: mov.estaVencido ? Colors.red : Colors.grey[600])),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_formatCurrency(mov.totalAPagar), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${mov.porcentajePagado.toInt()}% pagado', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
        onTap: () => _mostrarDetalles(mov),
      ),
    );
  }

  Widget _buildPaginacion() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 0 ? () => _cambiarPagina(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Anterior'),
          ),
          Text('${_currentPage + 1} / $_totalPaginas'),
          ElevatedButton.icon(
            onPressed: _currentPage < _totalPaginas - 1 ? () => _cambiarPagina(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Siguiente'),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }

  void _mostrarDetalles(MovimientoModel mov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Detalles del Préstamo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              _buildDetalleRow('ID', '#${mov.id}'),
              _buildDetalleRow('Cliente', '${mov.nombreCliente} (#${mov.idCliente})'),
              _buildDetalleRow('Monto', _formatCurrency(mov.monto)),
              _buildDetalleRow('Interés', _formatCurrency(mov.interes)),
              _buildDetalleRow('Total', _formatCurrency(mov.totalAPagar)),
              _buildDetalleRow('Abonos', _formatCurrency(mov.abonos)),
              _buildDetalleRow('Saldo', _formatCurrency(mov.saldoPendiente), isHighlighted: true),
              _buildDetalleRow('Inicio', _formatDate(mov.fechaInicio)),
              _buildDetalleRow('Vence', _formatDate(mov.fechaPago)),
              _buildDetalleRow('Días', '${mov.diasPrestamo}'),
              _buildDetalleRow('Estado', mov.estadoTexto),
              if (mov.estaVencido) _buildDetalleRow('Vencido', '${mov.diasVencido} días', valueColor: Colors.red),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Acciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LoanActionButtons(
                prestamo: mov,
                onActionComplete: () {
                  Navigator.pop(context);
                  _cargarMovimientos();
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _consultarDeudaCliente(mov.idCliente);
                },
                icon: const Icon(Icons.info),
                label: const Text('Ver Deuda Total del Cliente'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value, {bool isHighlighted = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
          Text(value, style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal, fontSize: isHighlighted ? 18 : 16, color: valueColor)),
        ],
      ),
    );
  }

  void _mostrarDeudaDialog(int clienteId, double deuda) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Color(0xFF00BCD4)),
            SizedBox(width: 8),
            Text('Deuda Total'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cliente #$clienteId', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            Text(_formatCurrency(deuda), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: deuda > 0 ? Colors.red : Colors.green)),
            const SizedBox(height: 8),
            Text(deuda > 0 ? 'Monto pendiente' : 'Sin deuda', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}
