import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/movimiento_model.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../widgets/loan_action_buttons.dart';

class AdminLoansListPage extends StatefulWidget {
  const AdminLoansListPage({super.key});

  @override
  State<AdminLoansListPage> createState() => AdminLoansListPageState();
}

class AdminLoansListPageState extends State<AdminLoansListPage> {
  
  // Método público para mostrar el menú de ordenamiento
  void mostrarMenuOrdenamiento() {
    if (mounted) {
      _mostrarMenuOrdenamiento(context);
    }
  }
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
      case 'deuda_desc':
        // Ordenar por deuda actual de mayor a menor, excluyendo pagados
        final noPagadosDeudaDesc = filtrados.where((p) => !p.estadoPagado).toList();
        final pagadosDeudaDesc = filtrados.where((p) => p.estadoPagado).toList();
        noPagadosDeudaDesc.sort((a, b) {
          return b.saldoPendiente.compareTo(a.saldoPendiente); // Mayor a menor
        });
        filtrados = [...noPagadosDeudaDesc, ...pagadosDeudaDesc];
        break;
      case 'deuda_asc':
        // Ordenar por deuda actual de menor a mayor, excluyendo pagados
        final noPagadosDeudaAsc = filtrados.where((p) => !p.estadoPagado).toList();
        final pagadosDeudaAsc = filtrados.where((p) => p.estadoPagado).toList();
        noPagadosDeudaAsc.sort((a, b) {
          return a.saldoPendiente.compareTo(b.saldoPendiente); // Menor a mayor
        });
        filtrados = [...noPagadosDeudaAsc, ...pagadosDeudaAsc];
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

  void _mostrarMenuOrdenamiento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Título
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sort, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Ordenar préstamos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Opciones
            _buildOpcionOrdenamiento(
              context,
              'id_desc',
              Icons.arrow_downward,
              'ID Descendente',
              'Más recientes primero',
            ),
            _buildOpcionOrdenamiento(
              context,
              'id_asc',
              Icons.arrow_upward,
              'ID Ascendente',
              'Más antiguos primero',
            ),
            _buildOpcionOrdenamiento(
              context,
              'monto_desc',
              Icons.trending_down,
              'Monto Mayor a Menor',
              'De mayor a menor cantidad',
            ),
            _buildOpcionOrdenamiento(
              context,
              'monto_asc',
              Icons.trending_up,
              'Monto Menor a Mayor',
              'De menor a mayor cantidad',
            ),
            _buildOpcionOrdenamiento(
              context,
              'fecha_proxima',
              Icons.calendar_today,
              'Fechas Próximas',
              'Próximos a vencer (sin pagados)',
            ),
            _buildOpcionOrdenamiento(
              context,
              'deuda_desc',
              Icons.money_off,
              'Deuda Mayor a Menor',
              'Deuda actual descendente (sin pagados)',
            ),
            _buildOpcionOrdenamiento(
              context,
              'deuda_asc',
              Icons.attach_money,
              'Deuda Menor a Mayor',
              'Deuda actual ascendente (sin pagados)',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionOrdenamiento(
    BuildContext context,
    String valor,
    IconData icono,
    String titulo,
    String descripcion,
  ) {
    final isSelected = _ordenamiento == valor;
    return InkWell(
      onTap: () {
        setState(() {
          _ordenamiento = valor;
          _paginaActual = 0;
          _aplicarFiltroYPaginacion();
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4).withOpacity(0.1) : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF00BCD4) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00BCD4)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icono,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF00BCD4) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00BCD4),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchBackground = Color.alphaBlend(
      theme.colorScheme.primary.withAlpha(isDark ? 18 : 10),
      theme.colorScheme.surface,
    );
    final fieldFillColor = Color.alphaBlend(
      theme.colorScheme.primary.withAlpha(isDark ? 32 : 18),
      theme.colorScheme.surface,
    );
    final borderColor = theme.dividerColor.withAlpha(isDark ? 70 : 110);

    InputDecoration filterDecoration(
      String label, {
      Widget? prefixIcon,
      Widget? suffixIcon,
    }) {
      final labelStyle = theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );
      return InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        floatingLabelStyle: labelStyle?.copyWith(fontWeight: FontWeight.w600),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fieldFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
    }

    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de búsqueda y filtros
                Container(
                  decoration: BoxDecoration(
                    color: searchBackground,
                    border: Border(
                      bottom: BorderSide(color: borderColor),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Dropdown de tipo de búsqueda y estado
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _tipoBusqueda,
                              decoration: filterDecoration('Buscar por'),
                              dropdownColor: fieldFillColor,
                              style: theme.textTheme.bodyMedium,
                              iconEnabledColor: theme.colorScheme.primary,
                              iconDisabledColor: theme.disabledColor,
                              borderRadius: BorderRadius.circular(12),
                              items: const [
                                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                                DropdownMenuItem(value: 'id_prestamo', child: Text('ID Préstamo')),
                                DropdownMenuItem(value: 'id_cliente', child: Text('ID Cliente')),
                                DropdownMenuItem(value: 'nombre_cliente', child: Text('Nombre Cliente')),
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
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _filtroEstado,
                              decoration: filterDecoration('Estado'),
                              dropdownColor: fieldFillColor,
                              style: theme.textTheme.bodyMedium,
                              iconEnabledColor: theme.colorScheme.primary,
                              iconDisabledColor: theme.disabledColor,
                              borderRadius: BorderRadius.circular(12),
                              items: const [
                                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                                DropdownMenuItem(value: 'pagado', child: Text('Pagados')),
                                DropdownMenuItem(value: 'no_pagado', child: Text('No Pagados')),
                              ],
                              onChanged: (value) {
                                _cambiarFiltro(value!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Campo de búsqueda
                      if (_tipoBusqueda != 'todos')
                        TextField(
                          controller: _busquedaController,
                          style: theme.textTheme.bodyMedium,
                          decoration: filterDecoration(
                            _tipoBusqueda == 'id_prestamo'
                                ? 'Ingrese ID del préstamo'
                                : _tipoBusqueda == 'id_cliente'
                                    ? 'Ingrese ID del cliente'
                                    : 'Ingrese nombre del cliente',
                            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                            suffixIcon: _busquedaController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: theme.colorScheme.primary),
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
                              '${prestamo.nombreCliente ?? 'Cliente #${prestamo.idCliente}'} • ${_formatDate(prestamo.fechaPago)}',
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
                                    // Estado (movido a la derecha)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
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
                                      ],
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
                                      onActionComplete: () async {
                                        await Future.delayed(const Duration(milliseconds: 300));
                                        await _cargarPrestamos();
                                        if (mounted) {
                                          setState(() {}); // Force refresh
                                        }
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
