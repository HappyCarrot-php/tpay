import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientContactPage extends StatefulWidget {
  const ClientContactPage({super.key});

  @override
  State<ClientContactPage> createState() => _ClientContactPageState();
}

class _ClientContactPageState extends State<ClientContactPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _moderadores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarModeradoresDesdeDB();
  }

  Future<void> _cargarModeradoresDesdeDB() async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select('nombre_completo, telefono, id')
          .eq('rol', 'moderador')
          .eq('activo', true);

      setState(() {
        _moderadores = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar moderadores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _llamarTelefono(String telefono) async {
    final tel = telefono.replaceAll(' ', '');
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _enviarWhatsApp(String telefono) async {
    final tel = telefono.replaceAll(' ', '').replaceAll('+', '');
    final uri = Uri.parse('https://wa.me/$tel');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto de Emergencia'),
        backgroundColor: const Color(0xFF00BCD4),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _moderadores.isEmpty
              ? const Center(
                  child: Text('No hay moderadores disponibles en este momento'),
                )
              : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              color: Color(0xFFFFF8E1),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Contacta a un moderador en caso de emergencia o dudas sobre tus préstamos.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Moderadores Disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _moderadores.length,
                itemBuilder: (context, index) {
                  final moderador = _moderadores[index];
                  final nombre = moderador['nombre_completo'] ?? 'Moderador';
                  final telefono = moderador['telefono'] ?? '';
                  
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFF00BCD4),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (telefono.isNotEmpty) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.phone, color: Color(0xFF00BCD4)),
                              title: Text(telefono),
                              trailing: IconButton(
                                icon: const Icon(Icons.call, color: Colors.green),
                                onPressed: () => _llamarTelefono(telefono),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.message),
                                label: const Text('Enviar WhatsApp'),
                                onPressed: () => _enviarWhatsApp(telefono),
                              ),
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'No hay teléfono registrado',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
