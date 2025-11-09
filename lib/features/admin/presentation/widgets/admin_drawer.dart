import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 35,
                    color: Color(0xFF00BCD4),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Panel Administrador',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'TPay',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Préstamos
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Préstamos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/loans');
            },
          ),
          
          // Clientes
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Clientes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/clients');
            },
          ),
          
          // Movimientos
          ListTile(
            leading: const Icon(Icons.history, color: Colors.purple),
            title: const Text('Movimientos'),
            subtitle: const Text('Historial de operaciones'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/movements');
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
              Navigator.pushNamed(context, '/admin/create-loan');
            },
          ),
          
          // Simulador de Préstamo
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('Simular Préstamo'),
            subtitle: const Text('Simular sin guardar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/loan-simulator');
            },
          ),
          
          // Calcular Inversión
          ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.green),
            title: const Text('Calcular Inversión'),
            subtitle: const Text('Simulador de inversiones'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/investment-calculator');
            },
          ),
          
          // Calculadora
          ListTile(
            leading: const Icon(Icons.calculate, color: Colors.orange),
            title: const Text('Calculadora'),
            subtitle: const Text('Cálculos express'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/calculator');
            },
          ),
          
          const Divider(),
          
          // Perfil
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/profile');
            },
          ),
          
          // Configuración
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/settings');
            },
          ),
          
          const Divider(),
          
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
        ],
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro de cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Aquí iría la lógica para cerrar sesión
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
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
