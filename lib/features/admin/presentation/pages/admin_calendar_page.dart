import 'package:flutter/material.dart';

import '../../../shared/presentation/pages/loan_calendar_page.dart';
import '../../data/repositories/movimiento_repository.dart';

class AdminCalendarPage extends StatelessWidget {
  const AdminCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final movimientoRepository = MovimientoRepository();

    return LoanCalendarPage(
      title: 'Calendario de Préstamos',
      description:
          'Visualiza todos los préstamos agendados y revisa sus detalles por fecha de pago.',
      emptyMessage: 'No hay préstamos programados para esta fecha.',
      showClientName: true,
      loadLoans: () => movimientoRepository.obtenerMovimientos(
        filtro: FiltroEstadoPrestamo.todos,
        limite: 1000,
      ),
    );
  }
}
