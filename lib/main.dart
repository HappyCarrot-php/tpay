import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await SupabaseService().initialize();
  
  // Inicializar notificaciones
  await NotificationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Configuración de localización para español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'MX'), // Español - México
      ],
      locale: const Locale('es', 'MX'),
      
      // Router
      routerConfig: AppRouter.router,
    );
  }
}
