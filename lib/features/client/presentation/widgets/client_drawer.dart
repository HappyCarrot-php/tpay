import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/settings/app_settings.dart';

class ClientDrawer extends StatelessWidget {
  const ClientDrawer({super.key});

  String _getUserEmail() {
    return Supabase.instance.client.auth.currentUser?.email ?? 'Cliente';
  }

  Future<void> _handleLogout(BuildContext context) async {
    final router = GoRouter.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta?'),
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

    if (shouldLogout != true) {
      return;
    }

    Navigator.of(context).pop();
    await Supabase.instance.client.auth.signOut();
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.onPrimary,
                  child: Icon(Icons.person, size: 35, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  _getUserEmail(),
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ) ??
                      const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Cliente',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary.withAlpha(204),
                      ) ??
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.contact_phone, color: theme.colorScheme.primary),
            title: const Text('Contacto Moderador'),
            onTap: () {
              Navigator.pop(context);
              context.push('/client-contact');
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
            title: const Text('Calendario de Pagos'),
            onTap: () {
              Navigator.pop(context);
              context.push('/client/calendar');
            },
          ),
          ListTile(
            leading: Icon(Icons.phone, color: theme.colorScheme.primary),
            title: const Text('Editar Teléfono'),
            onTap: () {
              Navigator.pop(context);
              context.push('/client-profile');
            },
          ),
          const Divider(),
          ExpansionTile(
            leading: Icon(Icons.settings, color: theme.colorScheme.primary),
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
            ],
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
