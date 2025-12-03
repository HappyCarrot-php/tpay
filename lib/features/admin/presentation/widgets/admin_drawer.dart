import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/perfil_repository.dart';
import '../../../../core/settings/app_settings.dart';

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

  Future<void> _handleSignOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas salir del panel administrador?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    Navigator.of(context).pop();

    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.go('/login');
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
          
          // Navegación principal
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Préstamos'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/loans');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Clientes'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/clients');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Calendario'),
            subtitle: const Text('Préstamos por fecha'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/calendar');
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge, color: Colors.purple),
            title: const Text('Perfiles'),
            subtitle: const Text('Gestionar usuarios'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/profiles');
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.add_circle, color: Color(0xFF00BCD4)),
            title: const Text('Registrar Préstamo'),
            subtitle: const Text('Crear nuevo préstamo'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/create-loan');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('Simular Préstamo'),
            subtitle: const Text('Simular sin guardar'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/loan-simulator');
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.green),
            title: const Text('Calcular Inversión'),
            subtitle: const Text('Simulador de inversiones'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/investment-calculator');
            },
          ),
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

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              context.go('/admin/profile');
            },
          ),

          ExpansionTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ajustes'),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppSettings.instance.themeModeNotifier,
                builder: (context, mode, _) {
                  return SwitchListTile.adaptive(
                    value: mode == ThemeMode.dark,
                    onChanged: (value) => AppSettings.instance.setDarkMode(value),
                    title: const Text('Modo oscuro'),
                    secondary: const Icon(Icons.dark_mode),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
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
            ],
          ),

          const Divider(),

          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _handleSignOut,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
