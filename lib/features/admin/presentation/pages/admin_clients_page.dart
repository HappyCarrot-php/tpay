import 'package:flutter/material.dart';
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
    if (_busqueda.isEmpty) {
      return _clientes;
    }
    return _clientes.where((cliente) {
      final nombreCompleto = cliente.nombreCompleto.toLowerCase();
      final id = cliente.id.toString();
      return nombreCompleto.contains(_busqueda.toLowerCase()) ||
          (cliente.email ?? '').toLowerCase().contains(_busqueda.toLowerCase()) ||
          (cliente.telefono ?? '').contains(_busqueda) ||
          id.contains(_busqueda);
    }).toList();
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
                      });
                    },
                  ),
                ),

                // Contador de resultados
                if (_busqueda.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_clientesFiltrados.length} resultado(s) encontrado(s)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
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
                            itemCount: _clientesFiltrados.length,
                            itemBuilder: (context, index) {
                              final cliente = _clientesFiltrados[index];
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
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editarCliente(cliente),
                                    tooltip: 'Editar',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar desactivación'),
        content: const Text(
          '¿Está seguro de desactivar este cliente?\n\n'
          'El cliente no será eliminado permanentemente, solo se marcará como inactivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              try {
                await _clienteRepo.desactivarCliente(widget.cliente.id);
                if (mounted) {
                  Navigator.pop(context, true); // Cerrar página de edición
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cliente desactivado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al desactivar cliente: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
