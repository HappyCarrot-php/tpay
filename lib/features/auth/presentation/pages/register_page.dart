import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();

  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      final nombre = _nombreController.text.trim();
      final apellidoPaterno = _apellidoPaternoController.text.trim();
      final apellidoMaterno = _apellidoMaternoController.text.trim();
      final telefono = _telefonoController.text.trim();

      await _authRepository.register(
        email: email,
        password: password,
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno.isEmpty ? null : apellidoMaterno,
        telefono: telefono.isEmpty ? null : telefono,
      );

      if (!mounted) return;
      await _showSuccessDialog();
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(error.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(
                    colorScheme.primary.withAlpha(48),
                    colorScheme.surface,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 42,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cuenta creada',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Hemos enviado un correo para activar tu cuenta. Inicia sesión para continuar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.go('/login');
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Ir a iniciar sesión'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    final theme = Theme.of(context);
    final sanitized = message.replaceFirst('Exception: ', '').trim();
    final displayMessage = sanitized.isEmpty
        ? 'No se pudo completar el registro. Intenta nuevamente.'
        : sanitized;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            displayMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onError,
            ),
          ),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final fieldFill = Color.alphaBlend(
      colorScheme.primary.withAlpha(isDark ? 30 : 18),
      colorScheme.surface,
    );
    final outlineColor = colorScheme.outlineVariant.withAlpha(
      isDark ? 150 : 110,
    );
    final iconNeutral =
        textTheme.bodyMedium?.color?.withOpacity(0.65) ??
        colorScheme.onSurfaceVariant;

    InputDecoration fieldDecoration(
      String label,
      IconData icon, {
      Widget? suffixIcon,
      String? helperText,
      String? counterText,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        suffixIcon: suffixIcon,
        helperText: helperText,
        helperMaxLines: 2,
        counterText: counterText,
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        colorScheme.primary.withAlpha(26),
                        colorScheme.surface,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Image.asset(
                      'assets/icons/TPayIcon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.account_circle,
                          size: 64,
                          color: colorScheme.primary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Crear cuenta',
                    style:
                        textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ) ??
                        TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Completa los datos para comenzar a usar TPay.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _nombreController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                    decoration: fieldDecoration('Nombre *', Icons.person),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      if (!RegExp(
                        r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$',
                      ).hasMatch(trimmed)) {
                        return 'Solo letras';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _apellidoPaternoController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                    decoration: fieldDecoration(
                      'Apellido paterno *',
                      Icons.person_outline,
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'El apellido paterno es obligatorio';
                      }
                      if (!RegExp(
                        r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$',
                      ).hasMatch(trimmed)) {
                        return 'Solo letras';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _apellidoMaternoController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                    decoration: fieldDecoration(
                      'Apellido materno (opcional)',
                      Icons.person_outline,
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isNotEmpty) {
                        if (!RegExp(
                          r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$',
                        ).hasMatch(trimmed)) {
                          return 'Solo letras';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    enabled: !_isLoading,
                    decoration: fieldDecoration(
                      'Teléfono (opcional)',
                      Icons.phone,
                      helperText: '10 dígitos',
                      counterText: '',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isNotEmpty) {
                        if (trimmed.length != 10) {
                          return 'Debe tener 10 dígitos';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
                          return 'Solo números';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    decoration: fieldDecoration(
                      'Email *',
                      Icons.email,
                      helperText: 'Usarás este correo para iniciar sesión',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'El email es obligatorio';
                      }
                      if (!RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      ).hasMatch(trimmed)) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    decoration: fieldDecoration(
                      'Contraseña *',
                      Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: iconNeutral,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final sanitized = value?.trim() ?? '';
                      if (sanitized.isEmpty) {
                        return 'La contraseña es obligatoria';
                      }
                      if (sanitized.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    enabled: !_isLoading,
                    decoration: fieldDecoration(
                      'Confirmar contraseña *',
                      Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: iconNeutral,
                        ),
                        onPressed: () => setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        }),
                      ),
                    ),
                    validator: (value) {
                      final confirm = value?.trim() ?? '';
                      if (confirm.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (confirm != _passwordController.text.trim()) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Registrarme',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _isLoading ? null : () => context.go('/login'),
                    child: Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
