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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/icons/TPayIcon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.account_balance_wallet,
                            size: 60,
                            color: Color(0xFF00BCD4),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // Nombre de la app
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'TPay',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00BCD4), // Turquesa
                      letterSpacing: 2,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Subtítulo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Sistema de Préstamos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      letterSpacing: 1,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 60),

            // Indicador de carga
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00BCD4),
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 60),

            // Mensaje de conexión a internet
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF00BCD4).withValues(alpha: 0.18),
                          const Color(0xFF006064).withValues(alpha: 0.16),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF00ACC1).withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.cloud_outlined,
                            color: Color(0xFF00838F),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Conéctate a la nube',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF006064),
                              ),
                            ),
                            Text(
                              'Necesitas internet para sincronizar',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Créditos del desarrollador
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withValues(alpha: 0.9),
                      border: Border.all(
                        color: const Color(0xFF26C6DA).withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF00ACC1),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Creado por',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF007C91),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [Color(0xFF00ACC1), Color(0xFF006064)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'Toledo Ávalos Ricardo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Experiencias financieras diseñadas con Flutter',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
