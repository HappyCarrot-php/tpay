import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/movimiento_model.dart';
import '../../data/repositories/movimiento_repository.dart';

class AdminLoansListPage extends StatefulWidget {
  const AdminLoansListPage({super.key});

  @override
  State<AdminLoansListPage> createState() => _AdminLoansListPageState();
}

class _AdminLoansListPageState extends State<AdminLoansListPage> {
  final MovimientoRepository _movimientoRepository = MovimientoRepository();
  
  List<MovimientoModel> _todosLosPrestamos = [];
  List<MovimientoModel> _prestamos = [];
  bool _cargando = true;
  String _filtroEstado = 'todos';
  
  // Paginación
  int _paginaActual = 0;
  final int _itemsPorPagina = 10;
  
  @override
  void initState() {
    super.initState();
    _cargarPrestamos();
  }

  Future<void> _cargarPrestamos() async {
    setState(() => _cargando = true);
    
    try {
      final prestamos = await _movimientoRepository.obtenerMovimientos();
      setState(() {
        _todosLosPrestamos = prestamos;
        _aplicarFiltroYPaginacion();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar préstamos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _aplicarFiltroYPaginacion() {
    // Aplicar filtro
    List<MovimientoModel> filtrados = _todosLosPrestamos;
    if (_filtroEstado != 'todos') {
      if (_filtroEstado == 'activo') {
        filtrados = _todosLosPrestamos
            .where((p) => !p.estadoPagado && !p.eliminado)
            .toList();
      } else if (_filtroEstado == 'pagado') {
        filtrados = _todosLosPrestamos
            .where((p) => p.estadoPagado && !p.eliminado)
            .toList();
      } else if (_filtroEstado == 'mora') {
        // Mora: préstamos activos con fecha de pago vencida
        final hoy = DateTime.now();
        filtrados = _todosLosPrestamos
            .where((p) => !p.estadoPagado && !p.eliminado && p.fechaPago.isBefore(hoy))
            .toList();
      }
    }
    
    // Aplicar paginación
    final inicio = _paginaActual * _itemsPorPagina;
    final fin = (inicio + _itemsPorPagina).clamp(0, filtrados.length);
    
    _prestamos = filtrados.sublist(
      inicio.clamp(0, filtrados.length),
      fin,
    );
  }

  int get _totalPaginas {
    List<MovimientoModel> filtrados = _todosLosPrestamos;
    if (_filtroEstado != 'todos') {
      if (_filtroEstado == 'activo') {
        filtrados = _todosLosPrestamos
            .where((p) => !p.estadoPagado && !p.eliminado)
            .toList();
      } else if (_filtroEstado == 'pagado') {
        filtrados = _todosLosPrestamos
            .where((p) => p.estadoPagado && !p.eliminado)
            .toList();
      } else if (_filtroEstado == 'mora') {
        final hoy = DateTime.now();
        filtrados = _todosLosPrestamos
            .where((p) => !p.estadoPagado && !p.eliminado && p.fechaPago.isBefore(hoy))
            .toList();
      }
    }
    return (filtrados.length / _itemsPorPagina).ceil();
  }

  int get _totalFiltrados {
    List<MovimientoModel> filtrados = _todosLosPrestamos;
    if (_filtroEstado != 'todos') {
      if (_filtroEstado == 'activo') {
        filtrados = _todosLosPrestamos
            .where((p) => !p.estadoPagado && !p.eliminado)
            .toList();
      } else if (_filtroEstado == 'pagado') {
        filtrados = _todosLosPrestamos
            .where((p) => p.estadoPagado && !p.eliminado)
            .toList();
      } else if (_filtroEstado == 'mora') {
        final hoy = DateTime.now();
        filtrados = _todosLosPrestamos
            .where((p) => !p.estadoPagado && !p.eliminado && p.fechaPago.isBefore(hoy))
            .toList();
      }
    }
    return filtrados.length;
  }

  void _cambiarPagina(int nuevaPagina) {
    setState(() {
      _paginaActual = nuevaPagina;
      _aplicarFiltroYPaginacion();
    });
  }

  void _cambiarFiltro(String nuevoFiltro) {
    setState(() {
      _filtroEstado = nuevoFiltro;
      _paginaActual = 0; // Resetear a primera página
      _aplicarFiltroYPaginacion();
    });
  }
  
  String _obtenerEstadoTexto(MovimientoModel prestamo) {
    if (prestamo.eliminado) return 'eliminado';
    if (prestamo.estadoPagado) return 'pagado';
    
    final hoy = DateTime.now();
    if (prestamo.fechaPago.isBefore(hoy)) return 'mora';
    
    return 'activo';
  }

  double _calcularTotal(MovimientoModel prestamo) {
    return prestamo.monto + prestamo.interes;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Colors.blue;
      case 'pagado':
        return Colors.green;
      case 'mora':
        return Colors.red;
      case 'eliminado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _confirmarEliminarPrestamo(MovimientoModel prestamo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro de eliminar el préstamo de ${prestamo.nombreCliente ?? 'cliente'}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarPrestamo(prestamo.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarPrestamo(int prestamoId) async {
    try {
      await _movimientoRepository.eliminarPrestamo(prestamoId, 'Eliminado desde lista de préstamos');
      await _cargarPrestamos();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préstamo eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar préstamo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _verDetallesPrestamo(MovimientoModel prestamo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanDetailPage(prestamo: prestamo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préstamos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _cambiarFiltro,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: 'activo',
                child: Text('Activos'),
              ),
              const PopupMenuItem(
                value: 'pagado',
                child: Text('Pagados'),
              ),
              const PopupMenuItem(
                value: 'mora',
                child: Text('En mora'),
              ),
            ],
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _prestamos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay préstamos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Información de paginación
                if (_totalFiltrados > _itemsPorPagina)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mostrando ${_paginaActual * _itemsPorPagina + 1}-${((_paginaActual + 1) * _itemsPorPagina).clamp(0, _totalFiltrados)} de $_totalFiltrados',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _paginaActual > 0
                                  ? () => _cambiarPagina(_paginaActual - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                              'Página ${_paginaActual + 1} de $_totalPaginas',
                              style: const TextStyle(fontSize: 14),
                            ),
                            IconButton(
                              onPressed: _paginaActual < _totalPaginas - 1
                                  ? () => _cambiarPagina(_paginaActual + 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                
                // Lista de préstamos colapsados
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _prestamos.length,
                    itemBuilder: (context, index) {
                      final prestamo = _prestamos[index];
                      final total = _calcularTotal(prestamo);
                      final estado = _obtenerEstadoTexto(prestamo);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFFE8F5E9), // Verde muy claro
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              'Préstamo #${prestamo.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32), // Verde oscuro
                              ),
                            ),
                            subtitle: Text(
                              '${prestamo.nombreCliente ?? 'Cliente #${prestamo.idCliente}'} • ${_formatDate(prestamo.fechaInicio)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatCurrency(total),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  backgroundColor: _getEstadoColor(estado),
                                  radius: 6,
                                ),
                              ],
                            ),
                            children: [
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Estado
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getEstadoColor(estado).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        estado.toUpperCase(),
                                        style: TextStyle(
                                          color: _getEstadoColor(estado),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 16),

                                    // Información del préstamo
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoItem(
                                            'Monto',
                                            _formatCurrency(prestamo.monto),
                                            Icons.attach_money,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildInfoItem(
                                            'Interés',
                                            _formatCurrency(prestamo.interes),
                                            Icons.percent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoItem(
                                            'Total',
                                            _formatCurrency(total),
                                            Icons.calculate,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildInfoItem(
                                            'Abonos',
                                            _formatCurrency(prestamo.abonos),
                                            Icons.payments,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoItem(
                                            'Saldo',
                                            _formatCurrency(prestamo.saldoPendiente),
                                            Icons.account_balance_wallet,
                                            color: prestamo.saldoPendiente > 0 ? Colors.orange : Colors.green,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildInfoItem(
                                            'Días',
                                            '${prestamo.diasPrestamo} días',
                                            Icons.today,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Fechas
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Inicio: ${_formatDate(prestamo.fechaInicio)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.event, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Venc: ${_formatDate(prestamo.fechaPago)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Botones de acción
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _verDetallesPrestamo(prestamo),
                                          icon: const Icon(Icons.edit, size: 18),
                                          label: const Text('Editar'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _confirmarEliminarPrestamo(prestamo),
                                          icon: const Icon(Icons.delete, size: 18),
                                          label: const Text('Eliminar'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegar a crear préstamo
          Navigator.pushNamed(context, '/admin/loans/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Préstamo'),
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Página de detalles del préstamo (placeholder)
class LoanDetailPage extends StatelessWidget {
  final MovimientoModel prestamo;

  const LoanDetailPage({super.key, required this.prestamo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Préstamo'),
      ),
      body: Center(
        child: Text('Detalles del préstamo ID: ${prestamo.id}'),
      ),
    );
  }
}
