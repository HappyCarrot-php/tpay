import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/cliente_repository.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/models/cliente_model.dart';

class AdminClientsPage extends StatefulWidget {
  const AdminClientsPage({super.key});

  @override
  State<AdminClientsPage> createState() => _AdminClientsPageState();
}

class _AdminClientsPageState extends State<AdminClientsPage> {
  final _clienteRepo = ClienteRepository();
  final _movimientoRepo = MovimientoRepository();

  List<ClienteModel> _clientes = [];
  Map<int, int> _prestamosActivosPorCliente = {};
  bool _isLoading = true;
  String _busqueda = '';
  bool _ordenAscendente = false; // Default: descendente (último primero)
  int _paginaActual = 0;
  final int _clientesPorPagina = 5;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() => _isLoading = true);
    try {
      final clientes = await _clienteRepo.obtenerClientes();
      
      // Obtener préstamos activos por cliente
      final prestamosActivos = await _movimientoRepo.obtenerMovimientos(
        filtro: FiltroEstadoPrestamo.activos,
        limite: 1000,
      );

      final Map<int, int> conteo = {};
      for (var prestamo in prestamosActivos) {
        conteo[prestamo.idCliente] = (conteo[prestamo.idCliente] ?? 0) + 1;
      }

      setState(() {
        _clientes = clientes;
        _prestamosActivosPorCliente = conteo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ClienteModel> get _clientesFiltrados {
    var filtrados = _busqueda.isEmpty 
      ? _clientes 
      : _clientes.where((cliente) {
          final nombreCompleto = cliente.nombreCompleto.toLowerCase();
          final id = cliente.id.toString();
          return nombreCompleto.contains(_busqueda.toLowerCase()) ||
              (cliente.email ?? '').toLowerCase().contains(_busqueda.toLowerCase()) ||
              (cliente.telefono ?? '').contains(_busqueda) ||
              id.contains(_busqueda);
        }).toList();
    
    // Ordenar según preferencia (default: descendente)
    filtrados.sort((a, b) => _ordenAscendente 
      ? a.id.compareTo(b.id) 
      : b.id.compareTo(a.id));
    
    return filtrados;
  }

  List<ClienteModel> get _clientesPaginados {
    final filtrados = _clientesFiltrados;
    final inicio = _paginaActual * _clientesPorPagina;
    final fin = (inicio + _clientesPorPagina).clamp(0, filtrados.length);
    return filtrados.sublist(inicio.clamp(0, filtrados.length), fin);
  }

  int get _totalPaginas {
    return (_clientesFiltrados.length / _clientesPorPagina).ceil();
  }

  Future<void> _mostrarDialogoDeuda(ClienteModel cliente) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Obtener deuda total del cliente
      final deudaTotal = await _clienteRepo.obtenerDeudaTotal(cliente.id);

      if (mounted) Navigator.pop(context); // Cerrar loading

      // Mostrar diálogo con la deuda
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Deuda Total',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  cliente.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Deuda Actual',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${deudaTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (deudaTotal == 0)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sin deudas pendientes',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Préstamos activos',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener deuda: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editarCliente(ClienteModel cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditClientPage(cliente: cliente),
      ),
    ).then((actualizado) {
      if (actualizado == true) {
        _cargarClientes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por ID, nombre, email o teléfono...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _busqueda = '';
                                  _paginaActual = 0;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _busqueda = value;
                        _paginaActual = 0; // Resetear paginación al buscar
                      });
                    },
                  ),
                ),

                // Contador de resultados y ordenamiento
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _busqueda.isNotEmpty
                            ? '${_clientesFiltrados.length} resultado(s)'
                            : '${_clientesFiltrados.length} cliente(s)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _ordenAscendente = !_ordenAscendente;
                            _paginaActual = 0;
                          });
                        },
                        icon: Icon(_ordenAscendente 
                          ? Icons.arrow_upward 
                          : Icons.arrow_downward),
                        label: Text(_ordenAscendente 
                          ? 'ID Ascendente' 
                          : 'ID Descendente'),
                      ),
                    ],
                  ),
                ),

                // Controles de paginación
                if (_clientesFiltrados.length > _clientesPorPagina)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Página ${_paginaActual + 1} de $_totalPaginas',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _paginaActual > 0
                                  ? () => setState(() => _paginaActual--)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            IconButton(
                              onPressed: _paginaActual < _totalPaginas - 1
                                  ? () => setState(() => _paginaActual++)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Lista de clientes
                Expanded(
                  child: _clientesFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _busqueda.isEmpty ? 'No hay clientes registrados' : 'No se encontraron clientes',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarClientes,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _clientesPaginados.length,
                            itemBuilder: (context, index) {
                              final cliente = _clientesPaginados[index];
                              final prestamosActivos = _prestamosActivosPorCliente[cliente.id] ?? 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF00BCD4),
                                    child: Text(
                                      cliente.iniciales,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    cliente.nombreCompleto,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.tag, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            'ID: ${cliente.id}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      if (cliente.email != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.email, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                cliente.email!,
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (cliente.telefono != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              cliente.telefono!,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.receipt_long, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$prestamosActivos préstamos activos',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: prestamosActivos > 0 ? Colors.blue : Colors.grey,
                                              fontWeight: prestamosActivos > 0 ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.account_balance_wallet, color: Colors.green),
                                        onPressed: () => _mostrarDialogoDeuda(cliente),
                                        tooltip: 'Visualizar Deuda',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editarCliente(cliente),
                                        tooltip: 'Editar',
                                      ),
                                    ],
                                  ),
                                  onTap: () => _editarCliente(cliente),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class EditClientPage extends StatefulWidget {
  final ClienteModel cliente;

  const EditClientPage({super.key, required this.cliente});

  @override
  State<EditClientPage> createState() => _EditClientPageState();
}

class _EditClientPageState extends State<EditClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _clienteRepo = ClienteRepository();
  
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoPaternoController;
  late final TextEditingController _apellidoMaternoController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _rfcController;
  late final TextEditingController _curpController;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente.nombre);
    _apellidoPaternoController = TextEditingController(text: widget.cliente.apellidoPaterno);
    _apellidoMaternoController = TextEditingController(text: widget.cliente.apellidoMaterno ?? '');
    _emailController = TextEditingController(text: widget.cliente.email ?? '');
    _telefonoController = TextEditingController(text: widget.cliente.telefono ?? '');
    _rfcController = TextEditingController(text: widget.cliente.rfc ?? '');
    _curpController = TextEditingController(text: widget.cliente.curp ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _rfcController.dispose();
    _curpController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final nombre = _nombreController.text.trim();
      final apellidoPaterno = _apellidoPaternoController.text.trim();
      final apellidoMaterno = _apellidoMaternoController.text.trim().isNotEmpty 
          ? _apellidoMaternoController.text.trim() 
          : null;
      
      // Generar nombreCompleto
      final nombreCompleto = apellidoMaterno != null
          ? '$nombre $apellidoPaterno $apellidoMaterno'
          : '$nombre $apellidoPaterno';

      final clienteActualizado = ClienteModel(
        id: widget.cliente.id,
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        nombreCompleto: nombreCompleto,
        email: _emailController.text.trim().isNotEmpty 
            ? _emailController.text.trim() 
            : null,
        telefono: _telefonoController.text.trim().isNotEmpty 
            ? _telefonoController.text.trim() 
            : null,
        rfc: _rfcController.text.trim().isNotEmpty 
            ? _rfcController.text.trim() 
            : null,
        curp: _curpController.text.trim().isNotEmpty 
            ? _curpController.text.trim() 
            : null,
        activo: widget.cliente.activo,
        creado: widget.cliente.creado,
        actualizado: DateTime.now(),
      );

      await _clienteRepo.actualizarCliente(clienteActualizado);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmarEliminarCliente() {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Desactivación'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Está seguro de desactivar este cliente?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Cliente: ${widget.cliente.nombreCompleto}'),
              const SizedBox(height: 16),
              const Text(
                'El cliente no será eliminado permanentemente, solo se marcará como inactivo.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña de moderador *',
                  hintText: 'Confirma tu identidad',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es obligatoria';
                  }
                  if (value.length < 6) {
                    return 'Contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final password = passwordController.text;
                final dialogContext = context;
                
                Navigator.of(dialogContext).pop(); // Cerrar diálogo del formulario
                
                // Mostrar indicador de carga
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text('Desactivando cliente...'),
                      ],
                    ),
                  ),
                );
                
                try {
                  // Verificar contraseña
                  final supabase = Supabase.instance.client;
                  final email = supabase.auth.currentUser?.email;
                  
                  if (email == null) {
                    throw Exception('No se pudo obtener el email del usuario');
                  }
                  
                  // Re-autenticar
                  await supabase.auth.signInWithPassword(
                    email: email,
                    password: password,
                  );
                  
                  // Desactivar cliente
                  await _clienteRepo.desactivarCliente(widget.cliente.id);
                  
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); // Cerrar loading
                    Navigator.of(dialogContext).pop(true); // Cerrar página de edición
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Cliente desactivado exitosamente'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); // Cerrar loading
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().contains('Invalid')
                            ? '❌ Contraseña incorrecta'
                            : '❌ Error: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmarEliminarCliente,
            tooltip: 'Eliminar cliente',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            'ID: ${widget.cliente.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cliente: ${widget.cliente.nombreCompleto}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nombre (requerido)
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Apellido Paterno
              TextFormField(
                controller: _apellidoPaternoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido Paterno',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Apellido Materno
              TextFormField(
                controller: _apellidoMaternoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido Materno',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Ingrese un email válido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
                  counterText: '',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 10) {
                      return 'Ingrese un número válido (10 dígitos)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // RFC
              TextFormField(
                controller: _rfcController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 13,
                decoration: const InputDecoration(
                  labelText: 'RFC (opcional)',
                  prefixIcon: Icon(Icons.badge),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),

              // CURP
              TextFormField(
                controller: _curpController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 18,
                decoration: const InputDecoration(
                  labelText: 'CURP (opcional)',
                  prefixIcon: Icon(Icons.fingerprint),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 32),

              // Botón guardar
              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardarCambios,
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando...' : 'Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
