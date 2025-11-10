import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  final _perfilRepo = PerfilRepository();
  String _nombreCompleto = 'Cargando...';
  String _rol = 'cliente';

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    try {
      final perfil = await _perfilRepo.obtenerPerfilActual();
      if (mounted) {
        setState(() {
          _nombreCompleto = perfil?.nombreCompleto ?? 'Usuario';
          _rol = perfil?.rol ?? 'cliente';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nombreCompleto = 'Usuario';
          _rol = 'cliente';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 35,
                    color: Color(0xFF00BCD4),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Panel Administrador',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _nombreCompleto,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Dashboard
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin');
            },
          ),
          
          // Préstamos
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Préstamos'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/loans');
            },
          ),
          
          // Clientes
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Clientes'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/clients');
            },
          ),
          
          const Divider(),
          
          // Registrar Préstamo
          ListTile(
            leading: const Icon(Icons.add_circle, color: Color(0xFF00BCD4)),
            title: const Text('Registrar Préstamo'),
            subtitle: const Text('Crear nuevo préstamo'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/create-loan');
            },
          ),
          
          // Simulador de Préstamo
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('Simular Préstamo'),
            subtitle: const Text('Simular sin guardar'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/loan-simulator');
            },
          ),
          
          // Calcular Inversión
          ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.green),
            title: const Text('Calcular Inversión'),
            subtitle: const Text('Simulador de inversiones'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/investment-calculator');
            },
          ),
          
          // Calculadora
          ListTile(
            leading: const Icon(Icons.calculate, color: Colors.orange),
            title: const Text('Calculadora'),
            subtitle: const Text('Cálculos express'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/calculator');
            },
          ),
          
          const Divider(),
          
          // Actualizar BD (Solo para moderadores)
          if (_rol == 'moderador')
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.purple),
              title: const Text('Actualizar BD'),
              subtitle: const Text('Backup de base de datos'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/database-backup');
              },
            ),
          
          // Cerrar sesión
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              _confirmarCerrarSesion(context);
            },
          ),
          
          const Divider(),
          
          // Perfil (al final)
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/profile');
            },
          ),
        ],
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro de cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Cerrar diálogo de confirmación
              
              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                await AuthRepository().logout();
                if (context.mounted) {
                  Navigator.of(context).pop(); // Cerrar loading
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // Cerrar loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error al cerrar sesión: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
