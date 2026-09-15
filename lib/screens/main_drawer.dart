import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const MainDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade600],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.inventory_2, size: 40, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Inventario Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sistema de Gestión',
                  style: TextStyle(
                    color: Colors.white70, // 🔥 CORREGIDO: shade200 → Colors.white70
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildItem(context, Icons.business, 'Proveedores', 0),
          _buildItem(context, Icons.inventory_2, 'Productos', 1),
          _buildItem(context, Icons.label, 'Categorías', 2),
          _buildItem(context, Icons.label, 'Marcas', 3),
          _buildItem(context, Icons.people, 'Clientes', 4),
          _buildItem(context, Icons.location_on, 'Ubicaciones', 5),
          _buildItem(context, Icons.history, 'Movimientos', 6),
          _buildItem(context, Icons.list_alt, 'Listados', 7),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue.shade50 : null,
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        onItemSelected(index);
      },
    );
  }

  // 🔥 CORREGIDO: método con context como parámetro
  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acerca de'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 60, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Inventario Pro',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Versión 1.0.0\n\nSistema de gestión de inventario\npara PYMEs.\n\n Adrian Rojo +54 223 400-1010',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}