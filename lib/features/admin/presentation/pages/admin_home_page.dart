import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_drawer.dart';
import 'admin_dashboard_page.dart';
import 'admin_loans_list_page.dart';
import 'admin_clients_page.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../data/repositories/cliente_repository.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../../../core/services/audio_service.dart';

class AdminHomePage extends StatefulWidget {
  final int initialIndex;
  
  const AdminHomePage({super.key, this.initialIndex = 0});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late int _selectedIndex;
  final GlobalKey<AdminLoansListPageState> _loansPageKey = GlobalKey<AdminLoansListPageState>();
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant AdminHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex &&
      widget.initialIndex >= 0 &&
      widget.initialIndex < _titles.length) {
      // Post-frame update avoids setState during build when coming from router rebuilds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedIndex = widget.initialIndex);
      });
    }
  }

  List<Widget> get _pages => [
    const AdminDashboardPage(),
    AdminLoansListPage(key: _loansPageKey),
    const AdminClientsPage(),
    const AdminProfilePage(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Préstamos',
    'Clientes',
    'Mi Perfil',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _selectedIndex == 1 ? [
          // Botón para mostrar filtros de ordenamiento cuando está en Préstamos
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Ordenar',
            onPressed: () {
              _loansPageKey.currentState?.mostrarMenuOrdenamiento();
            },
          ),
        ] : null,
      ),
      drawer: const AdminDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Préstamos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// Página de perfil del administrador con datos reales
class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _perfilRepo = PerfilRepository();
  final _clienteRepo = ClienteRepository();
  final _movimientoRepo = MovimientoRepository();

  bool _isLoading = true;
  String? _nombre;
  String? _email;
  String? _rol;
  int _prestamosActivos = 0;
  int _clientesRegistrados = 0;
  double _totalPrestado = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Obtener perfil
      final perfil = await _perfilRepo.obtenerPerfilActual();
      final email = _perfilRepo.obtenerEmailActual();

      // Obtener estadísticas
      final clientes = await _clienteRepo.obtenerClientes();
      final prestamosActivos = await _movimientoRepo.obtenerMovimientos(
        filtro: FiltroEstadoPrestamo.activos,
        limite: 1000,
      );

      double totalPrestado = 0;
      for (var prestamo in prestamosActivos) {
        totalPrestado += prestamo.monto + prestamo.interes;
      }

      if (mounted) {
        setState(() {
          _nombre = perfil?.nombreCompleto ?? 'Usuario';
          _email = email ?? 'No disponible';
          _rol = perfil?.rol ?? 'cliente';
          _clientesRegistrados = clientes.length;
          _prestamosActivos = prestamosActivos.length;
          _totalPrestado = totalPrestado;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF00BCD4),
            child: Icon(
              _rol == 'administrador' 
                  ? Icons.admin_panel_settings
                  : _rol == 'moderador'
                      ? Icons.manage_accounts
                      : Icons.person,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Nombre
          Text(
            _nombre ?? 'Usuario',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Email
          Text(
            _email ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Estadísticas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Estadísticas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    'Préstamos Activos', 
                    _prestamosActivos.toString(), 
                    Icons.receipt_long,
                  ),
                  const Divider(),
                  _buildStatItem(
                    'Clientes Registrados', 
                    _clientesRegistrados.toString(), 
                    Icons.people,
                  ),
                  const Divider(),
                  _buildStatItem(
                    'Total Prestado', 
                    '\$${_totalPrestado.toInt().toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    )}', 
                    Icons.attach_money,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón cerrar sesión
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Mostrar diálogo de confirmación
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
                  ),
                );

                if (confirmar == true && context.mounted) {
                  try {
                    // Reproducir sonido de logout
                    await AudioService().playLogoutSound();
                    
                    // Cerrar sesión
                    final authRepo = AuthRepository();
                    await authRepo.logout();

                    if (context.mounted) {
                      // Navegar a login
                      context.go('/login');
                      
                      // Mostrar mensaje
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sesión cerrada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al cerrar sesión: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('CERRAR SESIÓN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00BCD4)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
