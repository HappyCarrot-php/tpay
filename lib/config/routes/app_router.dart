import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// Auth
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';

// Admin
import '../../features/admin/presentation/pages/admin_home_page.dart';
import '../../features/admin/presentation/pages/loan_simulator_page.dart';
import '../../features/admin/presentation/pages/create_loan_page.dart';
import '../../features/admin/presentation/pages/investment_calculator_page.dart';
import '../../features/admin/presentation/pages/calculator_page.dart';
import '../../features/admin/presentation/pages/partner_mode_page.dart';
import '../../features/admin/presentation/pages/admin_movements_page.dart';
import '../../features/admin/presentation/pages/admin_profile_settings_page.dart';
import '../../features/admin/presentation/pages/database_backup_page.dart';
import '../../features/admin/presentation/pages/admin_profiles_page.dart';
import '../../features/admin/presentation/pages/admin_calendar_page.dart';

// Client
import '../../features/client/presentation/pages/client_home_page.dart';
import '../../features/client/presentation/pages/client_contact_page.dart';
import '../../features/client/presentation/pages/client_profile_page.dart';
import '../../features/client/presentation/pages/client_calendar_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/', // Splash screen primero
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
        name: 'splash',
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
        name: 'login',
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
        name: 'register',
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomePage(initialIndex: 0),
        name: 'admin-home',
        routes: [
          GoRoute(
            path: 'dashboard',
            builder: (context, state) => const AdminHomePage(initialIndex: 0),
            name: 'admin-dashboard',
          ),
          GoRoute(
            path: 'loans',
            builder: (context, state) => const AdminHomePage(initialIndex: 1),
            name: 'admin-loans',
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateLoanPage(),
                name: 'create-loan',
              ),
            ],
          ),
          GoRoute(
            path: 'clients',
            builder: (context, state) => const AdminHomePage(initialIndex: 2),
            name: 'admin-clients',
          ),
          GoRoute(
            path: 'create-loan',
            builder: (context, state) => const CreateLoanPage(),
            name: 'create-loan-direct',
          ),
          GoRoute(
            path: 'loan-simulator',
            builder: (context, state) => const LoanSimulatorPage(),
            name: 'loan-simulator',
          ),
          GoRoute(
            path: 'investment-calculator',
            builder: (context, state) => const InvestmentCalculatorPage(),
            name: 'investment-calculator',
          ),
          GoRoute(
            path: 'partner-mode',
            builder: (context, state) => const PartnerModePage(),
            name: 'partner-mode',
          ),
          GoRoute(
            path: 'calculator',
            builder: (context, state) => const CalculatorPage(),
            name: 'calculator',
          ),
          GoRoute(
            path: 'movements',
            builder: (context, state) => const AdminMovementsPage(),
            name: 'admin-movements',
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const AdminProfileSettingsPage(),
            name: 'admin-profile',
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const AdminProfileSettingsPage(),
            name: 'admin-settings',
          ),
          GoRoute(
            path: 'database-backup',
            builder: (context, state) => const DatabaseBackupPage(),
            name: 'database-backup',
          ),
          GoRoute(
            path: 'profiles',
            builder: (context, state) => const AdminProfilesPage(),
            name: 'admin-profiles',
          ),
          GoRoute(
            path: 'calendar',
            builder: (context, state) => const AdminCalendarPage(),
            name: 'admin-calendar',
          ),
        ],
      ),

      // Client routes
      GoRoute(
        path: '/client',
        builder: (context, state) => const ClientHomePage(),
        name: 'client-home',
      ),
      GoRoute(
        path: '/client-contact',
        builder: (context, state) => const ClientContactPage(),
        name: 'client-contact',
      ),
      GoRoute(
        path: '/client-profile',
        builder: (context, state) => const ClientProfilePage(),
        name: 'client-profile',
      ),
      GoRoute(
        path: '/client/calendar',
        builder: (context, state) => const ClientCalendarPage(),
        name: 'client-calendar',
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Página no encontrada',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/admin'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
