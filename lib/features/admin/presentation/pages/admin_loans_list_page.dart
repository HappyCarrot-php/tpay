import 'dart:math';

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
  final MovimientoRepository _movimientoRepository = MovimientoRepository();
  final TextEditingController _busquedaController = TextEditingController();

  List<MovimientoModel> _todosLosPrestamos = [];
  List<MovimientoModel> _prestamosFiltrados = [];
  List<MovimientoModel> _prestamos = [];

  bool _cargando = true;

  String _filtroEstado = 'todos';
  String _tipoBusqueda = 'todos';
  String _ordenamiento = 'id_desc';

  int _paginaActual = 0;
  int _totalPaginasCache = 1;

  static const int _itemsPorPagina = 10;

  void mostrarMenuOrdenamiento() {
    if (!mounted) return;
    _mostrarMenuOrdenamiento(context);
  }

  @override
  void initState() {
    super.initState();
    _cargarPrestamos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPrestamos() async {
    setState(() => _cargando = true);
    try {
      final prestamos = await _movimientoRepository.obtenerMovimientos(
        filtro: FiltroEstadoPrestamo.todos,
        limite: 1000,
      );
      if (!mounted) return;
      setState(() {
        _todosLosPrestamos = prestamos;
        _paginaActual = 0;
        _cargando = false;
      });
      _aplicarFiltroYPaginacion();
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar préstamos: $e')),
      );
    }
  }

  List<MovimientoModel> _obtenerPrestamosFiltrados() {
    List<MovimientoModel> filtrados =
        _todosLosPrestamos.where((p) => !p.eliminado).toList();

    final textoBusqueda = _busquedaController.text.trim().toLowerCase();
    if (textoBusqueda.isNotEmpty) {
      switch (_tipoBusqueda) {
        case 'id_prestamo':
          final id = int.tryParse(textoBusqueda);
          if (id != null) {
            filtrados = filtrados.where((p) => p.id == id).toList();
          }
          break;
        case 'id_cliente':
          final idCliente = int.tryParse(textoBusqueda);
          if (idCliente != null) {
            filtrados =
                filtrados.where((p) => p.idCliente == idCliente).toList();
          }
          break;
        case 'nombre_cliente':
          filtrados = filtrados
              .where((p) =>
                  (p.nombreCliente ?? '').toLowerCase().contains(textoBusqueda))
              .toList();
          break;
        default:
          break;
      }
    }

    switch (_filtroEstado) {
      case 'pagado':
        filtrados = filtrados.where((p) => p.estadoPagado).toList();
        break;
      case 'no_pagado':
        filtrados = filtrados.where((p) => !p.estadoPagado).toList();
        break;
      default:
        break;
    }

    switch (_ordenamiento) {
      case 'id_asc':
        filtrados.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'monto_desc':
        filtrados.sort(
          (a, b) => _calcularTotal(b).compareTo(_calcularTotal(a)),
        );
        break;
      case 'monto_asc':
        filtrados.sort(
          (a, b) => _calcularTotal(a).compareTo(_calcularTotal(b)),
        );
        break;
      case 'fecha_proxima':
        final noPagados = filtrados
            .where((p) => !p.estadoPagado)
            .toList()
          ..sort((a, b) => a.fechaPago.compareTo(b.fechaPago));
        final pagados = filtrados
            .where((p) => p.estadoPagado)
            .toList()
          ..sort((a, b) => b.fechaPago.compareTo(a.fechaPago));
        filtrados = [...noPagados, ...pagados];
        break;
      case 'deuda_desc':
        final noPagadosDeudaDesc = filtrados
            .where((p) => !p.estadoPagado)
            .toList()
          ..sort(
            (a, b) => b.saldoPendiente.compareTo(a.saldoPendiente),
          );
        final pagadosDeudaDesc = filtrados
            .where((p) => p.estadoPagado)
            .toList()
          ..sort(
            (a, b) => b.saldoPendiente.compareTo(a.saldoPendiente),
          );
        filtrados = [...noPagadosDeudaDesc, ...pagadosDeudaDesc];
        break;
      case 'deuda_asc':
        final noPagadosDeudaAsc = filtrados
            .where((p) => !p.estadoPagado)
            .toList()
          ..sort(
            (a, b) => a.saldoPendiente.compareTo(b.saldoPendiente),
          );
        final pagadosDeudaAsc = filtrados
            .where((p) => p.estadoPagado)
            .toList()
          ..sort(
            (a, b) => a.saldoPendiente.compareTo(b.saldoPendiente),
          );
        filtrados = [...noPagadosDeudaAsc, ...pagadosDeudaAsc];
        break;
      case 'id_desc':
      default:
        filtrados.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    return filtrados;
  }

  void _recalcularPrestamos({int? pagina}) {
    final filtrados = _obtenerPrestamosFiltrados();
    final total = filtrados.length;
    final totalPaginas = max(1, (total / _itemsPorPagina).ceil());
    final paginaSeleccionada = total == 0
        ? 0
        : (pagina ?? _paginaActual).clamp(0, totalPaginas - 1);
    final inicio = paginaSeleccionada * _itemsPorPagina;
    final fin = total == 0 ? 0 : min(inicio + _itemsPorPagina, total);

    _prestamosFiltrados = filtrados;
    _totalPaginasCache = totalPaginas;
    _paginaActual = paginaSeleccionada;
    _prestamos = total == 0 ? [] : filtrados.sublist(inicio, fin);
  }

  void _aplicarFiltroYPaginacion() {
    setState(() {
      _recalcularPrestamos();
    });
  }

  int get _totalFiltrados => _prestamosFiltrados.length;

  int get _totalPaginas => _totalPaginasCache;

  void _cambiarPagina(int nuevaPagina) {
    setState(() {
      _recalcularPrestamos(pagina: nuevaPagina);
    });
  }

  void _cambiarFiltro(String nuevoFiltro) {
    setState(() {
      _filtroEstado = nuevoFiltro;
      _recalcularPrestamos(pagina: 0);
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
    final theme = Theme.of(context);
    final sheetColor = theme.colorScheme.surface;
    final handleColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.25);
    final titleStyle =
        theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                  Text('Ordenar préstamos', style: titleStyle),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = colorScheme.primary;
    final unselectedBackground = isDark
        ? Color.alphaBlend(colorScheme.primary.withAlpha(16), colorScheme.surfaceVariant)
        : Colors.grey.shade200;
    final optionBackground =
        isSelected ? selectedColor.withOpacity(isDark ? 0.22 : 0.12) : null;
    final iconBackground = isSelected ? selectedColor : unselectedBackground;
    final iconColor = isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;
    final titleColor = isSelected ? selectedColor : colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _ordenamiento = valor;
          _recalcularPrestamos(pagina: 0);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: optionBackground,
          border: Border(
            left: BorderSide(
              color: isSelected ? selectedColor : Colors.transparent,
              width: 4,
            ),
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
              child: Icon(icono, color: iconColor, size: 20),
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: selectedColor, size: 24),
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
      theme.scaffoldBackgroundColor,
    );
    final fieldFillColor = Color.alphaBlend(
      theme.colorScheme.primary.withAlpha(isDark ? 28 : 14),
      theme.colorScheme.surface,
    );
    final borderColor = theme.dividerColor.withAlpha(isDark ? 90 : 80);
    final loanCardBackground = isDark
        ? Color.alphaBlend(
            theme.colorScheme.primary.withAlpha(18),
            theme.colorScheme.surfaceVariant,
          )
        : const Color(0xFFE8F5E9);
    final loanTitleColor =
        isDark ? theme.colorScheme.primary : const Color(0xFF2E7D32);
    final loanSubtitleColor =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ??
            (isDark ? Colors.white70 : Colors.black87);
    final loanAmountColor = isDark ? theme.colorScheme.primary : Colors.black;
    final loanDetailsBackground = isDark
        ? Color.alphaBlend(
            theme.colorScheme.surfaceVariant.withAlpha(170),
            theme.colorScheme.surface,
          )
        : Colors.white;
    final emptyStateIconColor =
        theme.colorScheme.onSurfaceVariant.withOpacity(0.45);
    final emptyStateTextColor = theme.colorScheme.onSurfaceVariant;

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
    }

    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: searchBackground,
                    border: Border(
                      bottom: BorderSide(color: borderColor),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
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
                                DropdownMenuItem(
                                  value: 'todos',
                                  child: Text('Todos'),
                                ),
                                DropdownMenuItem(
                                  value: 'id_prestamo',
                                  child: Text('ID Préstamo'),
                                ),
                                DropdownMenuItem(
                                  value: 'id_cliente',
                                  child: Text('ID Cliente'),
                                ),
                                DropdownMenuItem(
                                  value: 'nombre_cliente',
                                  child: Text('Nombre Cliente'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _tipoBusqueda = value!;
                                  _busquedaController.clear();
                                  _recalcularPrestamos(pagina: 0);
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
                                DropdownMenuItem(
                                  value: 'todos',
                                  child: Text('Todos'),
                                ),
                                DropdownMenuItem(
                                  value: 'pagado',
                                  child: Text('Pagados'),
                                ),
                                DropdownMenuItem(
                                  value: 'no_pagado',
                                  child: Text('No Pagados'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  _cambiarFiltro(value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => _mostrarMenuOrdenamiento(context),
                              icon: const Icon(Icons.sort),
                              label: const Text('Ordenar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_tipoBusqueda != 'todos') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _busquedaController,
                          style: theme.textTheme.bodyMedium,
                          decoration: filterDecoration(
                            _tipoBusqueda == 'id_prestamo'
                                ? 'Ingrese ID del préstamo'
                                : _tipoBusqueda == 'id_cliente'
                                    ? 'Ingrese ID del cliente'
                                    : 'Ingrese nombre del cliente',
                            prefixIcon:
                                Icon(Icons.search, color: theme.colorScheme.primary),
                            suffixIcon: _busquedaController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: theme.colorScheme.primary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _busquedaController.clear();
                                        _recalcularPrestamos(pagina: 0);
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
                              _recalcularPrestamos(pagina: 0);
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: _prestamos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: emptyStateIconColor),
                              const SizedBox(height: 16),
                              Text(
                                'No hay préstamos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: emptyStateTextColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            if (_totalFiltrados > _itemsPorPagina)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Mostrando ${_paginaActual * _itemsPorPagina + (_totalFiltrados == 0 ? 0 : 1)}-${min((_paginaActual + 1) * _itemsPorPagina, _totalFiltrados)} de $_totalFiltrados',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _paginaActual > 0
                                              ? () =>
                                                  _cambiarPagina(_paginaActual - 1)
                                              : null,
                                          icon:
                                              const Icon(Icons.chevron_left),
                                        ),
                                        Text(
                                          'Página ${_paginaActual + 1} de $_totalPaginas',
                                          style:
                                              const TextStyle(fontSize: 14),
                                        ),
                                        IconButton(
                                          onPressed: _paginaActual <
                                                  _totalPaginas - 1
                                              ? () => _cambiarPagina(
                                                  _paginaActual + 1)
                                              : null,
                                          icon:
                                              const Icon(Icons.chevron_right),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _prestamos.length,
                                itemBuilder: (context, index) {
                                  final prestamo = _prestamos[index];
                                  final total = _calcularTotal(prestamo);
                                  final estado =
                                      _obtenerEstadoTexto(prestamo);

                                  return Card(
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    color: loanCardBackground,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Theme(
                                      data: theme.copyWith(
                                        dividerColor: Colors.transparent,
                                      ),
                                      child: ExpansionTile(
                                        tilePadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        title: Text(
                                          'Préstamo #${prestamo.id}',
                                          style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: loanTitleColor,
                                              ) ??
                                              TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: loanTitleColor,
                                              ),
                                        ),
                                        subtitle: Text(
                                          '${prestamo.nombreCliente ?? 'Cliente #${prestamo.idCliente}'} • ${_formatDate(prestamo.fechaPago)}',
                                          style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: loanSubtitleColor,
                                              ) ??
                                              TextStyle(
                                                fontSize: 14,
                                                color: loanSubtitleColor,
                                              ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatCurrency(total),
                                              style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: loanAmountColor,
                                                  ) ??
                                                  TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: loanAmountColor,
                                                  ),
                                            ),
                                            const SizedBox(width: 12),
                                            CircleAvatar(
                                              backgroundColor:
                                                  _getEstadoColor(estado),
                                              radius: 6,
                                            ),
                                          ],
                                        ),
                                        children: [
                                          Container(
                                            color: loanDetailsBackground,
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getEstadoColor(
                                                          estado,
                                                        ).withOpacity(
                                                          isDark ? 0.3 : 0.2,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        estado.toUpperCase(),
                                                        style: TextStyle(
                                                          color: _getEstadoColor(
                                                              estado),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                const Divider(),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: _buildInfoItem(
                                                        'Monto',
                                                        _formatCurrency(
                                                            prestamo.monto),
                                                        Icons.attach_money,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: _buildInfoItem(
                                                        'Interés',
                                                        _formatCurrency(
                                                            prestamo.interes),
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
                                                        _formatCurrency(
                                                            prestamo.abonos),
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
                                                        _formatCurrency(
                                                            prestamo
                                                                .saldoPendiente),
                                                        Icons
                                                            .account_balance_wallet,
                                                        color: prestamo
                                                                    .saldoPendiente >
                                                                0
                                                            ? Colors.orange
                                                            : Colors.green,
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
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 16,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Inicio: ${_formatDate(prestamo.fechaInicio)}',
                                                      style: theme.textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                            fontSize: 12,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ) ??
                                                          TextStyle(
                                                            fontSize: 12,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Icon(
                                                      Icons.event,
                                                      size: 16,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Venc: ${_formatDate(prestamo.fechaPago)}',
                                                      style: theme.textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                            fontSize: 12,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ) ??
                                                          TextStyle(
                                                            fontSize: 12,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                LoanActionButtons(
                                                  prestamo: prestamo,
                                                  onActionComplete: () async {
                                                    await Future.delayed(
                                                      const Duration(
                                                        milliseconds: 300,
                                                      ),
                                                    );
                                                    await _cargarPrestamos();
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
    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onSurfaceVariant;
    final resolvedIconColor = color ?? labelColor;
    final valueColor = color ?? theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: resolvedIconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: labelColor,
                  ) ??
                  TextStyle(
                    fontSize: 12,
                    color: labelColor,
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
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
