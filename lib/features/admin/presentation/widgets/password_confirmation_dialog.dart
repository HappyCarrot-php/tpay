import 'package:flutter/material.dart';

class PasswordConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmButtonText;
  final String adminPassword;

  const PasswordConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmButtonText,
    required this.adminPassword,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String adminPassword,
    String confirmButtonText = 'Confirmar',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordConfirmationDialog(
        title: title,
        message: message,
        confirmButtonText: confirmButtonText,
        adminPassword: adminPassword,
      ),
    );
  }

  @override
  State<PasswordConfirmationDialog> createState() => _PasswordConfirmationDialogState();
}

class _PasswordConfirmationDialogState extends State<PasswordConfirmationDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showPasswordField = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (!_showPasswordField) {
      setState(() {
        _showPasswordField = true;
      });
    } else {
      // Validar contraseña
      final password = _passwordController.text;
      
      if (password.isEmpty) {
        setState(() {
          _errorMessage = 'Ingrese su contraseña';
        });
        return;
      }

      // Validar con la contraseña del administrador
      if (password != widget.adminPassword) {
        setState(() {
          _errorMessage = 'Contraseña incorrecta';
        });
        return;
      }

      // Contraseña correcta
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          if (_showPasswordField) ...[
            const SizedBox(height: 24),
            const Text(
              'Ingrese su contraseña de administrador:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Ingrese su contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _errorMessage,
              ),
              onChanged: (value) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              onSubmitted: (value) => _handleConfirm(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            _showPasswordField ? 'Confirmar' : widget.confirmButtonText,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
