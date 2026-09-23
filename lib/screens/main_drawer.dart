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
    final size = MediaQuery.of(context).size;
    final altoDisponible = size.height;

    // Altura del header y footer
    final altoHeader = altoDisponible * 0.18; // 18% para el header
    final altoFooter = 50.0;

    // Altura para los items (dividida entre la cantidad)
    final altoItems = altoDisponible - altoHeader - altoFooter;
    final altoItem = altoItems / 10; // 10 items

    return Drawer(
      width: 260,
      child: Column(
        children: [
          // ==================== HEADER ====================
          _buildHeader(altoHeader),

          // ==================== ITEMS PRINCIPALES ====================
          Expanded(
            child: Column(
              children: [
                _buildItem(context, Icons.business, 'Proveedores', 0, altoItem),
                _buildItem(context, Icons.inventory_2, 'Productos', 1, altoItem),
                _buildItem(context, Icons.category, 'Categorías', 2, altoItem),
                _buildItem(context, Icons.local_offer, 'Marcas', 3, altoItem),
                _buildItem(context, Icons.people, 'Clientes', 4, altoItem),
                _buildItem(context, Icons.location_on, 'Depositos', 5, altoItem),
                _buildItem(context, Icons.history, 'Movimientos', 6, altoItem),
                _buildItem(context, Icons.request_quote, 'Presupuestos', 7, altoItem),
                _buildItem(context, Icons.list_alt, 'Listados', 8, altoItem),
                _buildItem(context, Icons.settings, 'Configuración', 9, altoItem),
              ],
            ),
          ),

          // ==================== FOOTER ====================
          _buildFooter(context, altoFooter),
        ],
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(double alto) {
    return Container(
      height: alto,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Inventario Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Sistema de Gestión',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ITEM ====================
  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
    double alto,
  ) {
    final isSelected = selectedIndex == index;
    return SizedBox(
      height: alto,
      child: Material(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onItemSelected(index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== FOOTER ====================
  Widget _buildFooter(BuildContext context, double alto) {
    return Container(
      height: alto,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAbout(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Acerca de',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ABOUT ====================
  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2, color: Colors.blue),
            SizedBox(width: 8),
            Text('Acerca de'),
          ],
        ),
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
              'Versión 1.0.0\n\nSistema de gestión de inventario\npara PYMEs.\n\nAdrian Rojo-+54 223 400-1010',
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