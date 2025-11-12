import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/movimiento_model.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../widgets/loan_action_buttons.dart';

class AdminLoansListPage extends StatefulWidget {
  const AdminLoansListPage({super.key});

  @override
  State<AdminLoansListPage> createState() => _AdminLoansListPageState();
}

class _AdminLoansListPageState extends State<AdminLoansListPage> {
  final MovimientoRepository _movimientoRepository = MovimientoRepository();
  final TextEditingController _busquedaController = TextEditingController();
  
  List<MovimientoModel> _todosLosPrestamos = [];
  List<MovimientoModel> _prestamos = [];
  bool _cargando = true;
  
  // Filtros
  String _filtroEstado = 'todos'; // todos, pagado, no_pagado
  String _tipoBusqueda = 'todos'; // todos, id_prestamo, id_cliente, nombre_cliente
  String _ordenamiento = 'id_desc'; // id_desc, id_asc, monto_desc, monto_asc, fecha_proxima
  
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
    List<MovimientoModel> filtrados = _todosLosPrestamos.where((p) => !p.eliminado).toList();
    
    // Aplicar búsqueda según tipo
    final textoBusqueda = _busquedaController.text.trim().toLowerCase();
    if (textoBusqueda.isNotEmpty) {
      if (_tipoBusqueda == 'id_prestamo') {
        final id = int.tryParse(textoBusqueda);
        if (id != null) {
          filtrados = filtrados.where((p) => p.id == id).toList();
        }
      } else if (_tipoBusqueda == 'id_cliente') {
        final idCliente = int.tryParse(textoBusqueda);
        if (idCliente != null) {
          filtrados = filtrados.where((p) => p.idCliente == idCliente).toList();
        }
      } else if (_tipoBusqueda == 'nombre_cliente') {
        filtrados = filtrados.where((p) {
          final nombre = p.nombreCliente?.toLowerCase() ?? '';
          return nombre.contains(textoBusqueda);
        }).toList();
      }
    }
    
    // Aplicar filtro de estado de pago
    if (_filtroEstado == 'pagado') {
      filtrados = filtrados.where((p) => p.estadoPagado).toList();
    } else if (_filtroEstado == 'no_pagado') {
      filtrados = filtrados.where((p) => !p.estadoPagado).toList();
    }
    
    // Aplicar ordenamiento
    switch (_ordenamiento) {
      case 'id_asc':
        filtrados.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'id_desc':
        filtrados.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'monto_asc':
        filtrados.sort((a, b) => a.monto.compareTo(b.monto));
        break;
      case 'monto_desc':
        filtrados.sort((a, b) => b.monto.compareTo(a.monto));
        break;
      case 'fecha_proxima':
        // Ordenar por fecha próxima, excluyendo pagados
        final noPagados = filtrados.where((p) => !p.estadoPagado).toList();
        final pagados = filtrados.where((p) => p.estadoPagado).toList();
        noPagados.sort((a, b) => a.fechaPago.compareTo(b.fechaPago));
        filtrados = [...noPagados, ...pagados];
        break;
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
    List<MovimientoModel> filtrados = _todosLosPrestamos.where((p) => !p.eliminado).toList();
    
    // Aplicar búsqueda
    final textoBusqueda = _busquedaController.text.trim().toLowerCase();
    if (textoBusqueda.isNotEmpty) {
      if (_tipoBusqueda == 'id_prestamo') {
        final id = int.tryParse(textoBusqueda);
        if (id != null) {
          filtrados = filtrados.where((p) => p.id == id).toList();
        }
      } else if (_tipoBusqueda == 'id_cliente') {
        final idCliente = int.tryParse(textoBusqueda);
        if (idCliente != null) {
          filtrados = filtrados.where((p) => p.idCliente == idCliente).toList();
        }
      } else if (_tipoBusqueda == 'nombre_cliente') {
        filtrados = filtrados.where((p) {
          final nombre = p.nombreCliente?.toLowerCase() ?? '';
          return nombre.contains(textoBusqueda);
        }).toList();
      }
    }
    
    // Aplicar filtro de estado
    if (_filtroEstado == 'pagado') {
      filtrados = filtrados.where((p) => p.estadoPagado).toList();
    } else if (_filtroEstado == 'no_pagado') {
      filtrados = filtrados.where((p) => !p.estadoPagado).toList();
    }
    
    return (filtrados.length / _itemsPorPagina).ceil();
  }

  int get _totalFiltrados {
    List<MovimientoModel> filtrados = _todosLosPrestamos.where((p) => !p.eliminado).toList();
    
    // Aplicar búsqueda
    final textoBusqueda = _busquedaController.text.trim().toLowerCase();
    if (textoBusqueda.isNotEmpty) {
      if (_tipoBusqueda == 'id_prestamo') {
        final id = int.tryParse(textoBusqueda);
        if (id != null) {
          filtrados = filtrados.where((p) => p.id == id).toList();
        }
      } else if (_tipoBusqueda == 'id_cliente') {
        final idCliente = int.tryParse(textoBusqueda);
        if (idCliente != null) {
          filtrados = filtrados.where((p) => p.idCliente == idCliente).toList();
        }
      } else if (_tipoBusqueda == 'nombre_cliente') {
        filtrados = filtrados.where((p) {
          final nombre = p.nombreCliente?.toLowerCase() ?? '';
          return nombre.contains(textoBusqueda);
        }).toList();
      }
    }
    
    // Aplicar filtro de estado
    if (_filtroEstado == 'pagado') {
      filtrados = filtrados.where((p) => p.estadoPagado).toList();
    } else if (_filtroEstado == 'no_pagado') {
      filtrados = filtrados.where((p) => !p.estadoPagado).toList();
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de filtros compacta
                Container(
                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      // Primera fila: 3 dropdowns en línea
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _tipoBusqueda,
                              decoration: const InputDecoration(
                                labelText: 'Buscar',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                              items: const [
                                DropdownMenuItem(value: 'todos', child: Text('Todos', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'id_prestamo', child: Text('ID Préstamo', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'id_cliente', child: Text('ID Cliente', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'nombre_cliente', child: Text('Nombre', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _tipoBusqueda = value!;
                                  _busquedaController.clear();
                                  _paginaActual = 0;
                                  _aplicarFiltroYPaginacion();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filtroEstado,
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                              items: const [
                                DropdownMenuItem(value: 'todos', child: Text('Todos', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'pagado', child: Text('Pagados', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'no_pagado', child: Text('No Pagados', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (value) {
                                _cambiarFiltro(value!);
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _ordenamiento,
                              decoration: const InputDecoration(
                                labelText: 'Ordenar',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                              items: const [
                                DropdownMenuItem(value: 'id_desc', child: Text('+ Recientes', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'id_asc', child: Text('+ Antiguos', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'monto_desc', child: Text('💰 Mayor', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'monto_asc', child: Text('💰 Menor', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'fecha_proxima', child: Text('📅 Próximos', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _ordenamiento = value!;
                                  _paginaActual = 0;
                                  _aplicarFiltroYPaginacion();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      // Campo de búsqueda (solo si es necesario)
                      if (_tipoBusqueda != 'todos') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _busquedaController,
                          decoration: InputDecoration(
                            labelText: _tipoBusqueda == 'id_prestamo'
                                ? 'ID del préstamo'
                                : _tipoBusqueda == 'id_cliente'
                                    ? 'ID del cliente'
                                    : 'Nombre del cliente',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                            suffixIcon: _busquedaController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _busquedaController.clear();
                                        _paginaActual = 0;
                                        _aplicarFiltroYPaginacion();
                                      });
                                    },
                                  )
                                : null,
                          ),
                          style: const TextStyle(fontSize: 14),
                          keyboardType: _tipoBusqueda.contains('id')
                              ? TextInputType.number
                              : TextInputType.text,
                          onChanged: (value) {
                            setState(() {
                              _paginaActual = 0;
                              _aplicarFiltroYPaginacion();
                            });
                          },
                        ),
                      ],
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
                                            'Deuda Actual',
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
                                    LoanActionButtons(
                                      prestamo: prestamo,
                                      onActionComplete: () {
                                        _cargarPrestamos();
                                      },
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
                ),
              ],
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
