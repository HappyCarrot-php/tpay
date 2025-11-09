import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class ClientSearchOption {
  final String? id;
  final String displayName;
  final bool isExisting;
  
  ClientSearchOption({
    this.id,
    required this.displayName,
    this.isExisting = true,
  });
}

class CreateLoanPage extends StatefulWidget {
  const CreateLoanPage({super.key});

  @override
  State<CreateLoanPage> createState() => _CreateLoanPageState();
}

class _CreateLoanPageState extends State<CreateLoanPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _interesController = TextEditingController();
  
  // Controladores para datos del cliente
  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  String _buscarPor = 'id'; // 'id' o 'nombre'
  ClientSearchOption? _clienteSeleccionado;
  bool _mostrarFormularioCliente = false;
  bool _clienteExiste = false;
  
  DateTime? _fechaVencimiento;

  // Simulación de lista de clientes existentes (esto vendrá de Supabase)
  final List<Map<String, dynamic>> _clientesExistentes = [
    {
      'id': '1',
      'nombre': 'Juan',
      'apellido_paterno': 'Pérez',
      'apellido_materno': 'García',
      'email': 'juan@example.com',
      'telefono': '5512345678',
    },
    {
      'id': '2',
      'nombre': 'María',
      'apellido_paterno': 'López',
      'apellido_materno': 'Martínez',
      'email': 'maria@example.com',
      'telefono': '5598765432',
    },
    {
      'id': '3',
      'nombre': 'Carlos',
      'apellido_paterno': 'Rodríguez',
      'apellido_materno': null,
      'email': 'carlos@example.com',
      'telefono': '5523456789',
    },
  ];

  @override
  void dispose() {
    _montoController.dispose();
    _interesController.dispose();
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _buscarClientePorId(String? clienteId) {
    if (clienteId == null || clienteId.isEmpty) {
      setState(() {
        _clienteExiste = false;
        _mostrarFormularioCliente = false;
        _limpiarFormularioCliente();
      });
      return;
    }

    // Buscar en la lista de clientes existentes
    final cliente = _clientesExistentes.firstWhere(
      (c) => c['id'] == clienteId,
      orElse: () => {},
    );

    if (cliente.isNotEmpty) {
      setState(() {
        _clienteExiste = true;
        _mostrarFormularioCliente = false;
        _nombreController.text = cliente['nombre'] ?? '';
        _apellidoPaternoController.text = cliente['apellido_paterno'] ?? '';
        _apellidoMaternoController.text = cliente['apellido_materno'] ?? '';
        _emailController.text = cliente['email'] ?? '';
        _telefonoController.text = cliente['telefono'] ?? '';
      });
    } else {
      setState(() {
        _clienteExiste = false;
        _mostrarFormularioCliente = true;
        _limpiarFormularioCliente();
      });
      _mostrarDialogoClienteNoExiste();
    }
  }

  void _buscarClientePorNombre(String? nombre) {
    if (nombre == null || nombre.isEmpty) {
      setState(() {
        _clienteExiste = false;
        _mostrarFormularioCliente = false;
        _limpiarFormularioCliente();
      });
      return;
    }

    // Buscar en la lista de clientes existentes
    final cliente = _clientesExistentes.firstWhere(
      (c) => '${c['nombre']} ${c['apellido_paterno'] ?? ''}'.toLowerCase().trim() 
          == nombre.toLowerCase().trim(),
      orElse: () => {},
    );

    if (cliente.isNotEmpty) {
      setState(() {
        _clienteExiste = true;
        _mostrarFormularioCliente = false;
        _clienteSeleccionado = ClientSearchOption(
          id: cliente['id'],
          displayName: nombre,
          isExisting: true,
        );
        _nombreController.text = cliente['nombre'] ?? '';
        _apellidoPaternoController.text = cliente['apellido_paterno'] ?? '';
        _apellidoMaternoController.text = cliente['apellido_materno'] ?? '';
        _emailController.text = cliente['email'] ?? '';
        _telefonoController.text = cliente['telefono'] ?? '';
      });
    } else {
      setState(() {
        _clienteExiste = false;
        _mostrarFormularioCliente = true;
        _nombreController.text = nombre;
        _apellidoPaternoController.clear();
        _apellidoMaternoController.clear();
        _emailController.clear();
        _telefonoController.clear();
      });
    }
  }

  void _limpiarFormularioCliente() {
    _nombreController.clear();
    _apellidoPaternoController.clear();
    _apellidoMaternoController.clear();
    _emailController.clear();
    _telefonoController.clear();
  }

  void _mostrarDialogoClienteNoExiste() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cliente no encontrado'),
        content: const Text(
          'El cliente con este ID no existe. Por favor, complete el formulario para registrarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('es', 'MX'),
    );

    if (picked != null) {
      setState(() {
        _fechaVencimiento = picked;
      });
    }
  }

  void _guardarPrestamo() {
    if (_formKey.currentState!.validate()) {
      // Aquí iría la lógica para guardar en Supabase
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préstamo registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Préstamo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de tipo de búsqueda
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buscar cliente por:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('ID'),
                              value: 'id',
                              groupValue: _buscarPor,
                              onChanged: (value) {
                                setState(() {
                                  _buscarPor = value!;
                                  _clienteSeleccionado = null;
                                  _clienteExiste = false;
                                  _mostrarFormularioCliente = false;
                                  _limpiarFormularioCliente();
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Nombre'),
                              value: 'nombre',
                              groupValue: _buscarPor,
                              onChanged: (value) {
                                setState(() {
                                  _buscarPor = value!;
                                  _clienteSeleccionado = null;
                                  _clienteExiste = false;
                                  _mostrarFormularioCliente = false;
                                  _limpiarFormularioCliente();
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Campo de búsqueda
              if (_buscarPor == 'id')
                DropdownSearch<String>(
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Buscar ID...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  items: _clientesExistentes.map((c) => c['id'] as String).toList(),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'ID del Cliente',
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  onChanged: _buscarClientePorId,
                )
              else
                DropdownSearch<String>(
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Buscar nombre...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  items: _clientesExistentes
                      .map((c) => '${c['nombre']} ${c['apellido_paterno'] ?? ''}'.trim())
                      .toList(),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Nombre del Cliente',
                      prefixIcon: Icon(Icons.person_search),
                      hintText: 'Escriba el nombre o seleccione de la lista',
                    ),
                  ),
                  onChanged: _buscarClientePorNombre,
                ),
              
              // Indicador si el cliente existe
              if (_clienteExiste)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Cliente encontrado en el sistema',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Formulario del cliente (solo si no existe o si se quiere ver/editar)
              if (_mostrarFormularioCliente || _clienteExiste) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Datos del Cliente',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_clienteExiste)
                              Chip(
                                label: const Text(
                                  'Cliente existente',
                                  style: TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.green[100],
                              )
                            else
                              Chip(
                                label: const Text(
                                  'Cliente nuevo',
                                  style: TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.orange[100],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
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
                        
                        // Apellido Paterno (opcional)
                        TextFormField(
                          controller: _apellidoPaternoController,
                          decoration: const InputDecoration(
                            labelText: 'Apellido Paterno (opcional)',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Apellido Materno (opcional)
                        TextFormField(
                          controller: _apellidoMaternoController,
                          decoration: const InputDecoration(
                            labelText: 'Apellido Materno (opcional)',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Email (opcional)
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email (opcional)',
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
                        
                        // Teléfono (opcional)
                        TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono (opcional)',
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
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(thickness: 2),
              const SizedBox(height: 20),

              // Datos del préstamo
              const Text(
                'Datos del Préstamo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Monto
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'MXN',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El monto es requerido';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null || monto <= 0) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interés
              TextFormField(
                controller: _interesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Interés',
                  prefixIcon: Icon(Icons.percent),
                  suffixText: '%',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El interés es requerido';
                  }
                  final interes = double.tryParse(value);
                  if (interes == null || interes < 0) {
                    return 'Ingrese un interés válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha de vencimiento
              Card(
                child: InkWell(
                  onTap: () => _seleccionarFecha(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fecha de vencimiento (opcional)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fechaVencimiento != null
                                    ? '${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}'
                                    : 'Seleccionar fecha',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botón guardar
              ElevatedButton.icon(
                onPressed: _guardarPrestamo,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Préstamo'),
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
