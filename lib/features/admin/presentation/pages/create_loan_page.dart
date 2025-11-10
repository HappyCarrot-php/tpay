import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/cliente_repository.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/models/cliente_model.dart';

class CreateLoanPage extends StatefulWidget {
  const CreateLoanPage({super.key});

  @override
  State<CreateLoanPage> createState() => _CreateLoanPageState();
}

class _CreateLoanPageState extends State<CreateLoanPage> {
  final _formKey = GlobalKey<FormState>();
  final _clienteRepo = ClienteRepository();
  final _movimientoRepo = MovimientoRepository();

  final _searchController = TextEditingController();
  final _montoController = TextEditingController();
  final _interesController = TextEditingController();
  final _notasController = TextEditingController();

  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();

  List<ClienteModel> _clientes = [];
  List<ClienteModel> _clientesFiltrados = [];
  ClienteModel? _clienteSeleccionado;
  bool _mostrarDropdown = false;
  bool _mostrarFormularioNuevo = false;
  bool _isLoading = false;
  bool _creandoPrestamo = false;

  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaPago = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _cargarClientes();
    _searchController.addListener(_filtrarClientes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _montoController.dispose();
    _interesController.dispose();
    _notasController.dispose();
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    setState(() => _isLoading = true);
    try {
      final clientes = await _clienteRepo.obtenerClientes();
      setState(() {
        _clientes = clientes;
        _clientesFiltrados = clientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filtrarClientes() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _clientesFiltrados = _clientes;
        _mostrarDropdown = false;
        _mostrarFormularioNuevo = false;
      });
      return;
    }

    setState(() {
      _clientesFiltrados = _clientes.where((cliente) {
        final nombreCompleto = cliente.nombreCompleto.toLowerCase();
        final id = cliente.id.toString();
        return nombreCompleto.contains(query) || id.contains(query);
      }).toList();
      _mostrarDropdown = _clientesFiltrados.isNotEmpty;

      if (_clientesFiltrados.isEmpty && query.length > 2) {
        _mostrarFormularioNuevo = true;
        if (!RegExp(r'^\d+$').hasMatch(query)) {
          final partes = query.trim().split(' ');
          if (partes.isNotEmpty) {
            _nombreController.text = partes[0];
            if (partes.length > 1) {
              _apellidoPaternoController.text = partes[1];
            }
            if (partes.length > 2) {
              _apellidoMaternoController.text = partes.sublist(2).join(' ');
            }
          }
        }
      } else {
        _mostrarFormularioNuevo = false;
      }
    });
  }

  void _seleccionarCliente(ClienteModel cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _searchController.text = cliente.displayText;
      _mostrarDropdown = false;
      _mostrarFormularioNuevo = false;
    });
  }

  Future<void> _crearNuevoCliente() async {
    if (_nombreController.text.trim().isEmpty || _apellidoPaternoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y apellido paterno son obligatorios'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final nuevoCliente = await _clienteRepo.crearClienteSimple(
        nombre: _nombreController.text.trim(),
        apellidoPaterno: _apellidoPaternoController.text.trim(),
        apellidoMaterno: _apellidoMaternoController.text.trim().isNotEmpty ? _apellidoMaternoController.text.trim() : null,
        telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      );

      setState(() {
        _clienteSeleccionado = nuevoCliente;
        _clientes.add(nuevoCliente);
        _searchController.text = nuevoCliente.displayText;
        _mostrarFormularioNuevo = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente creado exitosamente'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear cliente: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _guardarPrestamo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clienteSeleccionado == null && !_mostrarFormularioNuevo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona o crea un cliente'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_mostrarFormularioNuevo && _clienteSeleccionado == null) {
      await _crearNuevoCliente();
      if (_clienteSeleccionado == null) return;
    }

    setState(() => _creandoPrestamo = true);

    try {
      final monto = double.parse(_montoController.text);
      final interes = double.parse(_interesController.text);
      final notas = _notasController.text.trim();

      await _movimientoRepo.crearPrestamo(
        clienteId: _clienteSeleccionado!.id,
        monto: monto,
        interes: interes,
        fechaInicio: _fechaInicio,
        fechaPago: _fechaPago,
        notas: notas.isNotEmpty ? notas : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préstamo registrado exitosamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _creandoPrestamo = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar préstamo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'es_MX').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Préstamo'),
        backgroundColor: const Color(0xFF00BCD4),
      ),
      body: _isLoading && _clientes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildClienteSection(),
                    const SizedBox(height: 20),
                    _buildPrestamoSection(),
                    const SizedBox(height: 32),
                    _buildGuardarButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildClienteSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_search, color: Color(0xFF00BCD4)),
                SizedBox(width: 8),
                Text('Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSearchField(),
            if (_mostrarDropdown) _buildDropdown(),
            if (_clienteSeleccionado != null) _buildSelectedClienteCard(),
            if (_mostrarFormularioNuevo) _buildNuevoClienteForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Buscar por ID o Nombre',
        hintText: 'Escribe para buscar o crear nuevo cliente',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _clienteSeleccionado = null;
                    _mostrarFormularioNuevo = false;
                  });
                },
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDropdown() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _clientesFiltrados.length,
            itemBuilder: (context, index) {
              final cliente = _clientesFiltrados[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(child: Text(cliente.iniciales)),
                title: Text(cliente.nombreCompleto),
                subtitle: Text('ID: ${cliente.id}'),
                onTap: () => _seleccionarCliente(cliente),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedClienteCard() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_clienteSeleccionado!.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('ID: ${_clienteSeleccionado!.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNuevoClienteForm() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_add, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Crear Nuevo Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apellidoPaternoController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Apellido Paterno *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apellidoMaternoController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Apellido Materno (opcional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrestamoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_money, color: Color(0xFF00BCD4)),
                SizedBox(width: 8),
                Text('Datos del Préstamo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto *',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                final monto = double.tryParse(value);
                if (monto == null || monto <= 0) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _interesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Interés *',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                final interes = double.tryParse(value);
                if (interes == null || interes < 0) return 'Interés inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildDatePicker('Fecha de Inicio', _fechaInicio, (date) => setState(() => _fechaInicio = date), DateTime(2020), DateTime.now().add(const Duration(days: 365))),
            const SizedBox(height: 12),
            _buildDatePicker('Fecha de Pago', _fechaPago, (date) => setState(() => _fechaPago = date), _fechaInicio, DateTime.now().add(const Duration(days: 365 * 5))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Días del préstamo:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('${_fechaPago.difference(_fechaInicio).inDays} días', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notasController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Información adicional sobre el préstamo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime selectedDate, Function(DateTime) onDateSelected, DateTime firstDate, DateTime lastDate) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDate(selectedDate)),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardarButton() {
    return ElevatedButton.icon(
      onPressed: _creandoPrestamo ? null : _guardarPrestamo,
      icon: _creandoPrestamo
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save),
      label: Text(_creandoPrestamo ? 'Guardando...' : 'Guardar Préstamo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BCD4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
