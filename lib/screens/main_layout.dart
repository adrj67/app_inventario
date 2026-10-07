import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/productos_filter_controller.dart';
import 'main_drawer.dart';
import 'pages/proveedores/proveedores_page.dart';
import 'pages/productos/productos_page.dart';
import 'pages/categorias/categorias_page.dart';
import 'pages/marcas/marcas_page.dart';
import 'pages/clientes/clientes_page.dart';
import 'pages/ubicaciones/ubicaciones_page.dart';
import 'pages/movimientos/movimientos_page.dart';
import 'pages/presupuestos/presupuestos_page.dart';
import 'pages/listados/listados_page.dart';
import 'pages/configuracion/configuracion_page.dart';
import '../config/demo_config.dart';
import '../services/demo_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // 🔥 Controller compartido para filtros de productos
  final ProductosFilterController _productosFilterController =
      ProductosFilterController();

  late final List<Widget> _pages;

  DemoStatus? _demoStatus;
  bool _cargandoDemo = true;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ProveedoresPage(),   // 0
      const ProductosPage(),     // 1
      const CategoriasPage(),    // 2
      const MarcasPage(),        // 3
      const ClientesPage(),      // 4
      const UbicacionesPage(),   // 5
      const MovimientosPage(),   // 6
      const PresupuestosPage(),  // 7
      const ListadosPage(),      // 8
      const ConfiguracionPage(), // 9
    ];

    // 🔥 Escuchar cambios del controller
    _productosFilterController.addListener(_onFiltroProductosCambiado);

    // 🔥 Cargar estado de la demo
    if (DemoConfig.isDemo) {
      _cargarDemoStatus();
      // Actualizar cada minuto
      Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) _cargarDemoStatus();
      });
    } else {
      setState(() => _cargandoDemo = false);
    }
  }

  Future<void> _cargarDemoStatus() async {
    final status = await DemoService.obtenerEstado();
    if (mounted) {
      setState(() {
        _demoStatus = status;
        _cargandoDemo = false;
      });
    }
  }

  @override
  void dispose() {
    _productosFilterController.removeListener(_onFiltroProductosCambiado);
    _productosFilterController.dispose();
    super.dispose();
  }

  void _onFiltroProductosCambiado() {
    // Cuando se aplica un filtro desde otra página, navegar a Productos
    if (_selectedIndex != 1) {
      setState(() => _selectedIndex = 1);
    }
  }

  Widget _buildDemoBadge(BuildContext context, DemoStatus status) {
    final color = _getDemoColor(status.urgencia);
    final icono = status.expirado
        ? Icons.lock
        : status.urgencia == 'urgente'
            ? Icons.warning_amber
            : Icons.schedule;

    return Tooltip(
      message: status.expirado
          ? 'Tu prueba ha expirado - Clic para más info'
          : 'Demo: ${status.textoRestante} restantes - Clic para más info',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarDialogoDemo(context, status),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.shade700,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  'DEMO: ${status.textoRestante}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MaterialColor _getDemoColor(String urgencia) {
    switch (urgencia) {
      case 'expirado':
        return Colors.red;
      case 'urgente':
        return Colors.red;
      case 'advertencia':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

    Future<void> _mostrarDialogoDemo(BuildContext context, DemoStatus status) async {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getDemoColor(status.urgencia).shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                status.expirado ? Icons.lock : Icons.schedule,
                color: _getDemoColor(status.urgencia).shade700,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Información de la Demo'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado actual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getDemoColor(status.urgencia).shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getDemoColor(status.urgencia).shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      status.expirado
                          ? 'PRUEBA EXPIRADA'
                          : status.textoRestante.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getDemoColor(status.urgencia).shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.expirado
                          ? 'Tu período de prueba terminó'
                          : 'Tiempo restante de prueba',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getDemoColor(status.urgencia).shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fecha de inicio
              if (status.fechaInicio != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Inicio de la prueba',
                  dateFormat.format(status.fechaInicio!),
                ),

              // Duración total
              _buildInfoRow(
                Icons.timer,
                'Duración total',
                '${DemoConfig.diasDemo} días',
              ),

              const Divider(height: 24),

              // Contacto
              Text(
                'PARA COMPRAR LA LICENCIA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // Email
              InkWell(
                onTap: () => _abrirEmail(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DemoConfig.emailContacto,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: Colors.blue.shade700),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Teléfono
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DemoConfig.telefonoContacto,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _abrirEmail();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: const Text('Comprar licencia'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icono, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: DemoConfig.emailContacto,
      query: 'subject=Quiero comprar Inventario Pro',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _productosFilterController),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventario Pro'),
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          elevation: 2,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showGlobalSearch(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _refreshData(context),
            ),
            const SizedBox(width: 8),
            // 🔥 Badge dinámico de demo (clickeable)
            if (DemoConfig.isDemo && !_cargandoDemo && _demoStatus != null)
              _buildDemoBadge(context, _demoStatus!),
            /* Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),*/
          ],
        ),
        drawer: MainDrawer(
          selectedIndex: _selectedIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
    );
  }

  void _showGlobalSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Búsqueda Global'),
        content: const Text('Próximamente...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _refreshData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos actualizados'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}