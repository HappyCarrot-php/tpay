import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/presentation/pages/loan_calendar_page.dart';
import '../../../admin/data/repositories/cliente_repository.dart';
import '../../../admin/data/models/movimiento_model.dart';
import '../../../admin/data/repositories/movimiento_repository.dart';
import '../../presentation/widgets/client_loan_action_buttons.dart';

class ClientCalendarPage extends StatefulWidget {
  const ClientCalendarPage({super.key});

  @override
  State<ClientCalendarPage> createState() => _ClientCalendarPageState();
}

class _ClientCalendarPageState extends State<ClientCalendarPage> {
  final _movimientoRepository = MovimientoRepository();
  final _clienteRepository = ClienteRepository();

  Future<List<MovimientoModel>> _loadLoans() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) {
      throw Exception('No se pudo identificar tu cuenta. Vuelve a iniciar sesión.');
    }

    final cliente = await _clienteRepository.buscarClientePorEmail(email);
    if (cliente == null) {
      throw Exception('No encontramos préstamos asociados a tu usuario.');
    }

    return _movimientoRepository.obtenerMovimientos(
      clienteId: cliente.id,
      filtro: FiltroEstadoPrestamo.todos,
      limite: 500,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoanCalendarPage(
      title: 'Calendario de Pagos',
      description:
          'Consulta tus fechas programadas de pago y revisa la información de cada préstamo.',
      emptyMessage: 'No tienes préstamos programados para este día.',
      showClientName: false,
      showSummary: false,
      loadLoans: _loadLoans,
      footerBuilder: (context, loan) => ClientLoanActionButtons(prestamo: loan),
    );
  }
}
