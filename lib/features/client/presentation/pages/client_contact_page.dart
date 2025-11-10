import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientContactPage extends StatelessWidget {
  const ClientContactPage({super.key});

  // Aquí se pueden definir los contactos de los moderadores
  // En producción, esto vendría de una base de datos
  final List<Map<String, String>> _moderadores = const [
    {
      'nombre': 'Moderador Principal',
      'telefono': '+52 123 456 7890',
      'email': 'moderador@tpay.com',
    },
    {
      'nombre': 'Soporte Emergencias',
      'telefono': '+52 098 765 4321',
      'email': 'soporte@tpay.com',
    },
  ];

  Future<void> _llamarTelefono(String telefono) async {
    final tel = telefono.replaceAll(' ', '');
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _enviarEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
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
      body: Padding(
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
                                  moderador['nombre']!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.phone, color: Color(0xFF00BCD4)),
                            title: Text(moderador['telefono']!),
                            trailing: IconButton(
                              icon: const Icon(Icons.call, color: Colors.green),
                              onPressed: () => _llamarTelefono(moderador['telefono']!),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.email, color: Color(0xFF00BCD4)),
                            title: Text(moderador['email']!),
                            trailing: IconButton(
                              icon: const Icon(Icons.email_outlined, color: Colors.blue),
                              onPressed: () => _enviarEmail(moderador['email']!),
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
                              onPressed: () => _enviarWhatsApp(moderador['telefono']!),
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
