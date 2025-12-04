import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Iniciar animación
    _controller.forward();

    // Verificar sesión y navegar después de 3 segundos
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      try {
        final supabase = SupabaseService();
        final session = supabase.client.auth.currentSession;

        if (session != null) {
          // Hay sesión activa, verificar rol
          final userId = session.user.id;
          final response = await supabase.client
              .from('perfiles')
              .select('rol')
              .eq('usuario_id', userId)
              .single();

          final rol = response['rol'] as String?;

          if (mounted) {
            if (rol == 'administrador' || rol == 'moderador') {
              context.go('/admin');
            } else {
              context.go('/client');
            }
          }
        } else {
          // No hay sesión, ir a login
          if (mounted) {
            context.go('/login');
          }
        }
      } catch (e) {
        // Error al verificar sesión, ir a login
        if (mounted) {
          context.go('/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [colorScheme.surface, colorScheme.surfaceContainerHighest]
          : [colorScheme.primary.withOpacity(0.12), colorScheme.surface],
    );

    final bubbleColor = colorScheme.surface.withOpacity(isDark ? 0.9 : 0.96);
    final borderColor = colorScheme.primary.withOpacity(0.24);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.35),
                            colorScheme.primary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/icons/TPayIcon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.account_balance_wallet,
                              size: 60,
                              color: colorScheme.onPrimary,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'TPay',
                    style:
                        textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: colorScheme.primary,
                        ) ??
                        TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Requiere conexión a internet',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: textTheme.titleSmall?.color?.withOpacity(0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Desarrollado por el Ingeniero Toledo Avalos Ricardo',
                    style: textTheme.bodySmall?.copyWith(
                      letterSpacing: 0.2,
                      color: textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
