import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Clase auxiliar para mostrar información
class _InfoItem {
  final String label;
  final String valor;
  
  _InfoItem(this.label, this.valor);
}

class AdminProfilesPage extends StatefulWidget {
  const AdminProfilesPage({super.key});

  @override
  State<AdminProfilesPage> createState() => _AdminProfilesPageState();
}

class _AdminProfilesPageState extends State<AdminProfilesPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _perfiles = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarPerfiles();
  }

  Future<void> _cargarPerfiles() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('perfiles')
          .select();

      if (mounted) {
        setState(() {
          _perfiles = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfiles: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _perfilesFiltrados {
    if (_searchQuery.isEmpty) return _perfiles;
    
    return _perfiles.where((perfil) {
      final nombre = (perfil['nombre_completo'] ?? '').toString().toLowerCase();
      final rol = (perfil['rol'] ?? '').toString().toLowerCase();
      final telefono = (perfil['telefono'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return nombre.contains(query) || 
             rol.contains(query) || 
             telefono.contains(query);
    }).toList();
  }

  Color _getColorByRole(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return Colors.red;
      case 'moderador':
        return Colors.blue;
      case 'cliente':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconByRole(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return Icons.admin_panel_settings;
      case 'moderador':
        return Icons.supervisor_account;
      case 'cliente':
        return Icons.person;
      default:
        return Icons.account_circle;
    }
  }

  // Función removida - Los perfiles solo se consultan, no se crean desde aquí
  // ignore: unused_element
  Future<void> _mostrarDialogCrearPerfil() async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final apellidoPaternoController = TextEditingController();
    final apellidoMaternoController = TextEditingController();
    final telefonoController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String rolSeleccionado = 'cliente';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Perfil'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: apellidoPaternoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido Paterno *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El apellido paterno es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: apellidoMaternoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido Materno',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El teléfono es requerido';
                    }
                    if (value.trim().length < 10) {
                      return 'Ingresa un teléfono válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El email es requerido';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña *',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La contraseña es requerida';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol *',
                    prefixIcon: Icon(Icons.security),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'administrador',
                      child: Text('Administrador'),
                    ),
                    DropdownMenuItem(
                      value: 'moderador',
                      child: Text('Moderador'),
                    ),
                    DropdownMenuItem(
                      value: 'cliente',
                      child: Text('Cliente'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      rolSeleccionado = value;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(context);

              // Mostrar loading
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // 1. Crear usuario en Auth usando Admin API (sin confirmación de email)
                final authResponse = await _supabase.auth.admin.createUser(
                  AdminUserAttributes(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    emailConfirm: true, // Auto-confirmar email
                  ),
                );

                if (authResponse.user == null) {
                  throw Exception('Error al crear usuario en Auth');
                }

                // Pequeña espera para asegurar que el trigger se ejecute
                await Future.delayed(const Duration(milliseconds: 500));

                // 2. Verificar si el perfil fue creado por el trigger
                var perfilExistente = await _supabase
                    .from('perfiles')
                    .select()
                    .eq('id', authResponse.user!.id)
                    .maybeSingle();

                if (perfilExistente != null) {
                  // El trigger ya creó el perfil, solo actualizamos
                  await _supabase.from('perfiles').update({
                    'nombre': nombreController.text.trim(),
                    'apellido_paterno': apellidoPaternoController.text.trim(),
                    'apellido_materno': apellidoMaternoController.text.trim().isEmpty 
                        ? null 
                        : apellidoMaternoController.text.trim(),
                    'telefono': telefonoController.text.trim().isEmpty 
                        ? null 
                        : telefonoController.text.trim(),
                    'rol': rolSeleccionado,
                    'activo': true,
                  }).eq('id', authResponse.user!.id);
                } else {
                  // Crear perfil manualmente si el trigger falló
                  await _supabase.from('perfiles').insert({
                    'id': authResponse.user!.id,
                    'nombre': nombreController.text.trim(),
                    'apellido_paterno': apellidoPaternoController.text.trim(),
                    'apellido_materno': apellidoMaternoController.text.trim().isEmpty 
                        ? null 
                        : apellidoMaternoController.text.trim(),
                    'telefono': telefonoController.text.trim().isEmpty 
                        ? null 
                        : telefonoController.text.trim(),
                    'rol': rolSeleccionado,
                    'activo': true,
                  });
                }

                if (!mounted) return;
                Navigator.pop(context); // Cerrar loading

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Perfil creado exitosamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );

                // Recargar después de 2 segundos
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) _cargarPerfiles();
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Cerrar loading

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al crear perfil: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoVerPerfil(Map<String, dynamic> perfil) async {
    // Obtener el email y última sesión del usuario desde auth.users
    String emailActual = 'No disponible';
    String ultimaSesion = 'No disponible';
    String idUsuario = 'No disponible';
    String estadoEmail = 'No confirmado';
    String fechaCreacion = 'No disponible';
    
    try {
      final userResponse = await _supabase.auth.admin.getUserById(perfil['id']);
      if (userResponse.user != null) {
        emailActual = userResponse.user!.email ?? 'No disponible';
        idUsuario = userResponse.user!.id;
        ultimaSesion = userResponse.user!.lastSignInAt != null 
            ? _formatearFecha(DateTime.parse(userResponse.user!.lastSignInAt!))
            : 'Nunca';
        estadoEmail = userResponse.user!.emailConfirmedAt != null ? '✅ Confirmado' : '⚠️ No confirmado';
        fechaCreacion = _formatearFecha(DateTime.parse(userResponse.user!.createdAt));
      }
    } catch (e) {
      // Si no se puede obtener, continuamos con valores por defecto
      emailActual = 'Error al obtener';
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconByRole(perfil['rol'] ?? 'cliente'),
              color: _getColorByRole(perfil['rol'] ?? 'cliente'),
            ),
            const SizedBox(width: 12),
            const Text('Información del Perfil'),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Datos personales
                _buildSeccionInfo(
                  titulo: 'Datos Personales',
                  icono: Icons.person,
                  items: [
                    _InfoItem('Nombre', perfil['nombre'] ?? 'N/A'),
                    _InfoItem('Apellido Paterno', perfil['apellido_paterno'] ?? 'N/A'),
                    _InfoItem('Apellido Materno', perfil['apellido_materno'] ?? 'N/A'),
                    _InfoItem('Nombre Completo', perfil['nombre_completo'] ?? 'N/A'),
                    _InfoItem('Teléfono', perfil['telefono'] ?? 'Sin teléfono'),
                  ],
                ),
                const Divider(height: 32),
                
                // Información de cuenta
                _buildSeccionInfo(
                  titulo: 'Información de Cuenta',
                  icono: Icons.account_circle,
                  items: [
                    _InfoItem('Email', emailActual),
                    _InfoItem('Estado Email', estadoEmail),
                    _InfoItem('Contraseña', '••••••••  (Encriptada en BD)'),
                    _InfoItem('ID de Usuario', idUsuario),
                    _InfoItem('Rol', (perfil['rol'] ?? 'cliente').toUpperCase()),
                    _InfoItem(
                      'Estado',
                      perfil['activo'] == true ? '🟢 ACTIVO' : '🔴 INACTIVO',
                    ),
                    _InfoItem('Última Sesión', ultimaSesion),
                    _InfoItem('Cuenta Creada', fechaCreacion),
                  ],
                ),
                const Divider(height: 32),
                
                // Fechas
                _buildSeccionInfo(
                  titulo: 'Fechas',
                  icono: Icons.calendar_today,
                  items: [
                    _InfoItem(
                      'Creado',
                      perfil['creado'] != null
                          ? _formatearFecha(DateTime.parse(perfil['creado']))
                          : 'N/A',
                    ),
                    _InfoItem(
                      'Actualizado',
                      perfil['actualizado'] != null
                          ? _formatearFecha(DateTime.parse(perfil['actualizado']))
                          : 'N/A',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Nota informativa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Los usuarios pueden editar su información desde su perfil personal.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionInfo({
    required String titulo,
    required IconData icono,
    required List<_InfoItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      '${item.label}:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.valor,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmarDarDeBaja(Map<String, dynamic> perfil) async {
    // Verificar que no sea el usuario actual
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener el usuario actual'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Si intenta darse de baja a sí mismo
    if (perfil['id'] == currentUserId) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Operación No Permitida'),
          content: const Text('No puedes darte de baja a ti mismo.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    // Pedir contraseña para confirmar
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Dar de Baja Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de dar de baja a "${perfil['nombre_completo']}"?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'El perfil no se eliminará, solo se marcará como inactivo.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Por seguridad, ingresa tu contraseña para confirmar:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Ingresa tu contraseña',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text('Dar de Baja'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return;

    // Reautenticar al usuario
    try {
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail == null) throw Exception('No se pudo obtener el email del usuario');

      // Intentar reautenticar
      await _supabase.auth.signInWithPassword(
        email: userEmail,
        password: password,
      );

      // Si llegamos aquí, la contraseña es correcta
      await _supabase.from('perfiles').update({
        'activo': false,
      }).eq('id', perfil['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Perfil dado de baja'),
          backgroundColor: Colors.orange,
        ),
      );

      _cargarPerfiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Invalid')
                ? '❌ Contraseña incorrecta'
                : 'Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmarReactivar(Map<String, dynamic> perfil) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Reactivar Perfil'),
        content: Text(
          '¿Deseas reactivar el perfil de "${perfil['nombre_completo']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _supabase.from('perfiles').update({
        'activo': true,
      }).eq('id', perfil['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Perfil reactivado'),
          backgroundColor: Colors.green,
        ),
      );

      _cargarPerfiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mostrarDialogoDeuda(Map<String, dynamic> perfil) async {
    // Primero necesito obtener el id del cliente desde la tabla clientes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Buscar el cliente por usuario_id
      final clienteResponse = await _supabase
          .from('clientes')
          .select('id')
          .eq('usuario_id', perfil['id'])
          .maybeSingle();

      if (clienteResponse == null) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.error, color: Colors.orange, size: 60),
              title: const Text('Sin Información'),
              content: const Text('Este cliente no tiene préstamos registrados.'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final clienteId = clienteResponse['id'] as int;

      // Obtener deuda total
      final deudaResponse = await _supabase
          .from('movimientos')
          .select('saldo_pendiente')
          .eq('id_cliente', clienteId)
          .eq('estado_pagado', false)
          .eq('eliminado', false);

      double deudaTotal = 0;
      for (var mov in deudaResponse) {
        deudaTotal += (mov['saldo_pendiente'] as num?)?.toDouble() ?? 0;
      }

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
                  perfil['nombre_completo'] ?? 'Sin nombre',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Perfiles'),
        centerTitle: true,
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPerfiles,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar perfil',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${_perfilesFiltrados.length} perfil(es) encontrado(s)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Lista de perfiles
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _perfilesFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron perfiles',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarPerfiles,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _perfilesFiltrados.length,
                          itemBuilder: (context, index) {
                            final perfil = _perfilesFiltrados[index];
                            final activo = perfil['activo'] ?? false;
                            final rol = perfil['rol'] ?? 'cliente';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getColorByRole(rol),
                                  child: Icon(
                                    _getIconByRole(rol),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  perfil['nombre_completo'] ?? 'Sin nombre',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: activo
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.security,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rol.toUpperCase(),
                                          style: TextStyle(
                                            color: _getColorByRole(rol),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          perfil['telefono'] ?? 'Sin teléfono',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          activo
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 14,
                                          color: activo
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          activo ? 'ACTIVO' : 'INACTIVO',
                                          style: TextStyle(
                                            color: activo
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'ver':
                                        _mostrarDialogoVerPerfil(perfil);
                                        break;
                                      case 'deuda':
                                        _mostrarDialogoDeuda(perfil);
                                        break;
                                      case 'baja':
                                        _confirmarDarDeBaja(perfil);
                                        break;
                                      case 'reactivar':
                                        _confirmarReactivar(perfil);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) {
                                    final currentUserId = _supabase.auth.currentUser?.id;
                                    final isCurrentUser = perfil['id'] == currentUserId;
                                    final esCliente = rol.toLowerCase() == 'cliente';
                                    
                                    return [
                                      const PopupMenuItem(
                                        value: 'ver',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility, size: 20, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Ver Información'),
                                          ],
                                        ),
                                      ),
                                      if (esCliente && activo)
                                        const PopupMenuItem(
                                          value: 'deuda',
                                          child: Row(
                                            children: [
                                              Icon(Icons.account_balance_wallet, size: 20, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text('Visualizar Deuda'),
                                            ],
                                          ),
                                        ),
                                      if (activo && !isCurrentUser)
                                        const PopupMenuItem(
                                          value: 'baja',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_off,
                                                  size: 20, color: Colors.orange),
                                              SizedBox(width: 8),
                                              Text('Dar de Baja'),
                                            ],
                                          ),
                                        ),
                                      if (!activo)
                                        const PopupMenuItem(
                                          value: 'reactivar',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_add,
                                                  size: 20, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text('Reactivar'),
                                            ],
                                          ),
                                        ),
                                    ];
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      // Botón "Crear Perfil" eliminado - Solo consulta y dar de baja
    );
  }
}
