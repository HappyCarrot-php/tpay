import 'package:flutter/material.dart';

class AdminClientsPage extends StatefulWidget {
  const AdminClientsPage({super.key});

  @override
  State<AdminClientsPage> createState() => _AdminClientsPageState();
}

class _AdminClientsPageState extends State<AdminClientsPage> {
  // Simulación de clientes (vendrá de Supabase)
  final List<Map<String, dynamic>> _clientes = [
    {
      'id': '1',
      'nombre': 'Juan',
      'apellido_paterno': 'Pérez',
      'apellido_materno': 'García',
      'email': 'juan@example.com',
      'telefono': '5512345678',
      'prestamos_activos': 2,
    },
    {
      'id': '2',
      'nombre': 'María',
      'apellido_paterno': 'López',
      'apellido_materno': 'Martínez',
      'email': 'maria@example.com',
      'telefono': '5598765432',
      'prestamos_activos': 1,
    },
    {
      'id': '3',
      'nombre': 'Carlos',
      'apellido_paterno': 'Rodríguez',
      'apellido_materno': null,
      'email': 'carlos@example.com',
      'telefono': '5523456789',
      'prestamos_activos': 0,
    },
  ];

  String _busqueda = '';

  List<Map<String, dynamic>> get _clientesFiltrados {
    if (_busqueda.isEmpty) {
      return _clientes;
    }
    return _clientes.where((cliente) {
      final nombreCompleto = '${cliente['nombre']} ${cliente['apellido_paterno'] ?? ''} ${cliente['apellido_materno'] ?? ''}'
          .toLowerCase();
      return nombreCompleto.contains(_busqueda.toLowerCase()) ||
          (cliente['email'] ?? '').toLowerCase().contains(_busqueda.toLowerCase()) ||
          (cliente['telefono'] ?? '').contains(_busqueda);
    }).toList();
  }

  void _editarCliente(Map<String, dynamic> cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditClientPage(cliente: cliente),
      ),
    ).then((actualizado) {
      if (actualizado == true) {
        setState(() {
          // Recargar datos
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, email o teléfono...',
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
                          'No se encontraron clientes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final cliente = _clientesFiltrados[index];
                      final nombreCompleto =
                          '${cliente['nombre']} ${cliente['apellido_paterno'] ?? ''} ${cliente['apellido_materno'] ?? ''}'
                              .trim();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              cliente['nombre'][0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            nombreCompleto,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              if (cliente['email'] != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cliente['email'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                              if (cliente['telefono'] != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      cliente['telefono'],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${cliente['prestamos_activos']} préstamos activos',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: cliente['prestamos_activos'] > 0
                                          ? Colors.blue
                                          : Colors.grey,
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
        ],
      ),
    );
  }
}

class EditClientPage extends StatefulWidget {
  final Map<String, dynamic> cliente;

  const EditClientPage({super.key, required this.cliente});

  @override
  State<EditClientPage> createState() => _EditClientPageState();
}

class _EditClientPageState extends State<EditClientPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoPaternoController;
  late final TextEditingController _apellidoMaternoController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente['nombre']);
    _apellidoPaternoController = TextEditingController(
      text: widget.cliente['apellido_paterno'] ?? '',
    );
    _apellidoMaternoController = TextEditingController(
      text: widget.cliente['apellido_materno'] ?? '',
    );
    _emailController = TextEditingController(text: widget.cliente['email'] ?? '');
    _telefonoController = TextEditingController(text: widget.cliente['telefono'] ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _guardarCambios() {
    if (_formKey.currentState!.validate()) {
      // Aquí iría la lógica para actualizar en Supabase
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _confirmarEliminarCliente() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Está seguro de eliminar este cliente?\n\n'
          'Esta acción no se puede deshacer y eliminará también todos sus préstamos asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Aquí iría la lógica para eliminar en Supabase
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context, true); // Cerrar página de edición
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cliente eliminado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
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
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ID: ${widget.cliente['id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
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
              const SizedBox(height: 32),

              // Botón guardar
              ElevatedButton.icon(
                onPressed: _guardarCambios,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
