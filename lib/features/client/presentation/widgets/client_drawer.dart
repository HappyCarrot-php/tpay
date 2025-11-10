import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientDrawer extends StatelessWidget {
  const ClientDrawer({super.key});

  String _getUserEmail() {
    return Supabase.instance.client.auth.currentUser?.email ?? 'Cliente';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
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
                  child: Icon(Icons.person, size: 35, color: Color(0xFF00BCD4)),
                ),
                const SizedBox(height: 10),
                Text(
                  _getUserEmail(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Cliente',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Color(0xFF00BCD4)),
            title: const Text('Mis Préstamos'),
            onTap: () {
              Navigator.pop(context);
              context.go('/client-home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone, color: Color(0xFF00BCD4)),
            title: const Text('Contacto Moderador'),
            onTap: () {
              Navigator.pop(context);
              context.push('/client-contact');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF00BCD4)),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              context.push('/client-profile');
            },
          ),
        ],
      ),
    );
  }
}
