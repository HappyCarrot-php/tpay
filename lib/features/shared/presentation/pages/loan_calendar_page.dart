import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../admin/data/models/movimiento_model.dart';

class LoanCalendarPage extends StatelessWidget {
  const LoanCalendarPage({
    super.key,
    required this.title,
    required this.description,
    required this.emptyMessage,
    required this.loadLoans,
    this.showClientName = false,
    this.showSummary = true,
    this.footerBuilder,
  });

  final String title;
  final String description;
  final String emptyMessage;
  final Future<List<MovimientoModel>> Function() loadLoans;
  final bool showClientName;
  final bool showSummary;
  final Widget? Function(BuildContext context, MovimientoModel loan)? footerBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _LoanCalendarView(
        description: description,
        emptyMessage: emptyMessage,
        loadLoans: loadLoans,
        showClientName: showClientName,
        showSummary: showSummary,
        footerBuilder: footerBuilder,
      ),
    );
  }
}

class _LoanCalendarView extends StatefulWidget {
  const _LoanCalendarView({
    required this.description,
    required this.emptyMessage,
    required this.loadLoans,
    required this.showClientName,
    required this.showSummary,
    this.footerBuilder,
  });

  final String description;
  final String emptyMessage;
  final Future<List<MovimientoModel>> Function() loadLoans;
  final bool showClientName;
  final bool showSummary;
  final Widget? Function(BuildContext context, MovimientoModel loan)? footerBuilder;

  @override
  State<_LoanCalendarView> createState() => _LoanCalendarViewState();
}

class _LoanCalendarViewState extends State<_LoanCalendarView> {
  final Map<DateTime, List<MovimientoModel>> _events = {};
  final DateTime _firstDay = DateTime(DateTime.now().year - 1);
  final DateTime _lastDay = DateTime(DateTime.now().year + 2, 12, 31);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalizeDate(DateTime.now());
    _fetchLoans();
  }

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> _fetchLoans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loans = await widget.loadLoans();
      final grouped = <DateTime, List<MovimientoModel>>{};

      for (final loan in loans) {
        final key = _normalizeDate(loan.fechaPago);
        grouped.putIfAbsent(key, () => <MovimientoModel>[]).add(loan);
      }

      setState(() {
        _events
          ..clear()
          ..addAll(grouped);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MovimientoModel> _loansForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? const [];
  }

  List<MovimientoModel> _loansForMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    final results = <MovimientoModel>[];
    for (final entry in _events.entries) {
      if (entry.key.year == normalized.year && entry.key.month == normalized.month) {
        results.addAll(entry.value);
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDay = _selectedDay ?? _normalizeDate(DateTime.now());
    final selectedLoans = _loansForDay(selectedDay);
    final monthLoans = _loansForMonth(_focusedDay);

    return RefreshIndicator(
      onRefresh: _fetchLoans,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.showSummary) ...[
            _buildSummaryChips(context, monthLoans),
            const SizedBox(height: 16),
          ],
          _buildCalendarCard(theme, selectedDay),
          const SizedBox(height: 24),
          Text(
            'Préstamos para ${_formatDate(selectedDay)}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(),
            ))
          else if (_errorMessage != null)
            _buildErrorState(context)
          else if (selectedLoans.isEmpty)
            _buildEmptyState(context)
          else
            ...selectedLoans.map((loan) => _buildLoanCard(context, loan)).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryChips(BuildContext context, List<MovimientoModel> monthLoans) {
    final theme = Theme.of(context);
    final totalMonthLoans = monthLoans.length;
    final totalExpected = monthLoans.fold<double>(0, (sum, loan) => sum + loan.totalAPagar);
    final totalPending = monthLoans.fold<double>(0, (sum, loan) => sum + loan.saldoPendiente);
    final paidLoans = monthLoans.where((loan) => loan.estadoPagado).length;

    Widget buildMetric({
      required IconData icon,
      required String label,
      required String value,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        buildMetric(
          icon: Icons.event_note,
          label: 'Préstamos del mes',
          value: totalMonthLoans.toString(),
          color: Theme.of(context).colorScheme.primary,
        ),
        buildMetric(
          icon: Icons.payments,
          label: 'Total esperado',
          value: _formatCurrency(totalExpected),
          color: Theme.of(context).colorScheme.secondary,
        ),
        buildMetric(
          icon: Icons.pending_actions,
          label: 'Pendiente',
          value: _formatCurrency(totalPending),
          color: Theme.of(context).colorScheme.tertiary,
        ),
        buildMetric(
          icon: Icons.verified_outlined,
          label: 'Pagados',
          value: paidLoans.toString(),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildCalendarCard(ThemeData theme, DateTime selectedDay) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TableCalendar<MovimientoModel>(
          focusedDay: _focusedDay,
          firstDay: _firstDay,
          lastDay: _lastDay,
          currentDay: DateTime.now(),
          locale: 'es_MX',
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = _normalizeDate(selected);
              _focusedDay = focused;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = focusedDay);
          },
          eventLoader: _loansForDay,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleLarge!,
            leftChevronIcon: const Icon(Icons.chevron_left),
            rightChevronIcon: const Icon(Icons.chevron_right),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
            weekendStyle: TextStyle(fontWeight: FontWeight.w600),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            markersAlignment: Alignment.bottomRight,
            markersOffset: const PositionedOffset(bottom: 6, end: 6),
            markersMaxCount: 3,
            outsideDaysVisible: false,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'No se pudieron cargar los préstamos',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _fetchLoans,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            widget.emptyMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, MovimientoModel loan) {
    final theme = Theme.of(context);
    final accent = Color(loan.estadoColor);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '#${loan.id}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Préstamo ${loan.id}',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (widget.showClientName && (loan.nombreCliente?.isNotEmpty ?? false))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            loan.nombreCliente!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loan.estadoTexto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLoanInfoTile(
                    context,
                    label: 'Total a pagar',
                    value: _formatCurrency(loan.totalAPagar),
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLoanInfoTile(
                    context,
                    label: 'Saldo pendiente',
                    value: _formatCurrency(loan.saldoPendiente),
                    icon: Icons.account_balance_wallet_outlined,
                    valueColor: loan.estadoPagado ? Colors.green : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLoanInfoTile(
                    context,
                    label: 'Progreso',
                    value: '${loan.porcentajePagado.toStringAsFixed(1)}%',
                    icon: Icons.task_alt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLoanInfoTile(
                    context,
                    label: 'Vence',
                    value: _formatDate(loan.fechaPago),
                    icon: Icons.event,
                    valueColor: loan.estaVencido ? Colors.red : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showLoanDetails(context, loan),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver detalle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanInfoTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
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

  void _showLoanDetails(BuildContext context, MovimientoModel loan) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        builder: (context, controller) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Préstamo #${loan.id}',
                      style: theme.textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  loan.estadoTexto,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Color(loan.estadoColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.showClientName && (loan.nombreCliente?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Cliente: ${loan.nombreCliente!}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 24),
                _buildDetailTile(
                  context,
                  label: 'Monto prestado',
                  value: _formatCurrency(loan.monto),
                  icon: Icons.attach_money,
                ),
                _buildDetailTile(
                  context,
                  label: 'Interés generado',
                  value: _formatCurrency(loan.interes),
                  icon: Icons.percent,
                ),
                _buildDetailTile(
                  context,
                  label: 'Total a pagar',
                  value: _formatCurrency(loan.totalAPagar),
                  icon: Icons.payments,
                  highlight: true,
                ),
                _buildDetailTile(
                  context,
                  label: 'Abonos realizados',
                  value: _formatCurrency(loan.abonos),
                  icon: Icons.account_balance_wallet,
                ),
                _buildDetailTile(
                  context,
                  label: 'Saldo pendiente',
                  value: _formatCurrency(loan.saldoPendiente),
                  icon: Icons.savings,
                  valueColor: loan.estadoPagado ? Colors.green : null,
                ),
                const SizedBox(height: 20),
                _buildDetailTile(
                  context,
                  label: 'Fecha de inicio',
                  value: _formatDate(loan.fechaInicio),
                  icon: Icons.calendar_today,
                ),
                _buildDetailTile(
                  context,
                  label: 'Fecha programada',
                  value: _formatDate(loan.fechaPago),
                  icon: Icons.event,
                  valueColor: loan.estaVencido ? Colors.red : null,
                ),
                if (loan.estaVencido)
                  _buildDetailTile(
                    context,
                    label: 'Días en mora',
                    value: '${loan.diasVencido} días',
                    icon: Icons.warning,
                    valueColor: Colors.red,
                  ),
                if (loan.notas != null && loan.notas!.isNotEmpty)
                  _buildDetailTile(
                    context,
                    label: 'Notas',
                    value: loan.notas!,
                    icon: Icons.sticky_note_2_outlined,
                  ),
                if (widget.footerBuilder != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: widget.footerBuilder!(context, loan),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final baseColor = highlight ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primary.withOpacity(0.12)
            : theme.colorScheme.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? theme.colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: highlight
                  ? theme.colorScheme.primary.withOpacity(0.25)
                  : theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: highlight ? baseColor : theme.colorScheme.primary),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: valueColor ?? baseColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day.toString().padLeft(2, '0')} de ${months[date.month - 1]} de ${date.year}';
  }
}
