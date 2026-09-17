import 'package:flutter/material.dart';
import 'main_drawer.dart';
import 'pages/proveedores/proveedores_page.dart';
import 'pages/productos/productos_page.dart';
import 'pages/categorias/categorias_page.dart';
import 'pages/marcas/marcas_page.dart';
import 'pages/ubicaciones/ubicaciones_page.dart';
import 'pages/clientes/clientes_page.dart';
import 'pages/movimientos/movimientos_page.dart';
import 'pages/listados/listados_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ProveedoresPage(),  // 0
    const ProductosPage(),    // 1
    const CategoriasPage(),   // 2
    const MarcasPage(),       // 3
    const ClientesPage(),     // 4
    const UbicacionesPage(),  // 5
    const MovimientosPage(),  // 6
    const ListadosPage(),     // 7
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Container(
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
          ),
        ],
      ),
      drawer: MainDrawer( // 🔥 AHORA SÍ RECONOCE LA CLASE
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: _pages[_selectedIndex],
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