import 'package:flutter/material.dart';
import '../../../database/proveedor_repository.dart';
import '../../../models/proveedor.dart';
import '../../../widgets/search_field.dart';
import 'proveedor_form.dart';
import '../../../widgets/export_button.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  final ProveedorRepository _repository = ProveedorRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Proveedor> _proveedores = [];
  List<Proveedor> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProveedores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProveedores() async {
    setState(() => _isLoading = true);

    try {
      final lista = await _repository.getAll(soloActivos: true);
      setState(() {
        _proveedores = lista;
        _filtered = lista;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando proveedores: $e');
      setState(() {
        _proveedores = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _filtrar(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _proveedores);
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _filtered = _proveedores.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
            (p.cuit?.toLowerCase().contains(q) ?? false) ||
            (p.contacto?.toLowerCase().contains(q) ?? false) ||
            (p.telefono?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  Future<void> _abrirFormulario({Proveedor? proveedor}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ProveedorForm(proveedor: proveedor),
      ),
    );

    if (resultado == true) {
      _searchController.clear();
      await _loadProveedores();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SearchField(
            controller: _searchController,
            onChanged: _filtrar,
            hintText: 'Buscar por nombre, CUIT, contacto o teléfono...',
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // IZQUIERDA: título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proveedores',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} proveedores registrados',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          // DERECHA: botones
          Row(
            children: [
              ExportButton(
                titulo: 'Proveedores',
                headers: const [
                  'ID',
                  'Nombre',
                  'CUIT',
                  'Teléfono',
                  'Email',
                  'Dirección',
                  'Contacto',
                  'Estado',
                ],
                rows: _filtered
                    .map(
                      (p) => [
                        (p.id ?? '').toString(),
                        p.nombre,
                        p.cuit ?? '',
                        p.telefono ?? '',
                        p.email ?? '',
                        p.direccion ?? '',
                        p.contacto ?? '',
                        p.activo ? 'Activo' : 'Inactivo',
                      ],
                    )
                    .toList(),
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _abrirFormulario(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Nuevo Proveedor',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay proveedores registrados'
                  : 'No se encontraron resultados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Presiona "Nuevo Proveedor" para comenzar'
                  : 'Intenta con otros términos de búsqueda',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProveedores,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final proveedor = _filtered[index];
          return _ProveedorTile(
            proveedor: proveedor,
            onTap: () => _abrirFormulario(proveedor: proveedor),
            onDelete: () => _confirmarEliminar(proveedor),
          );
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(Proveedor proveedor) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Proveedor'),
          ],
        ),
        content: Text(
          '¿Estás seguro que deseas eliminar a "${proveedor.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _repository.delete(proveedor.id!);
      await _loadProveedores();
    }
  }
}

// Widget interno para cada item de la lista
class _ProveedorTile extends StatelessWidget {
  final Proveedor proveedor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProveedorTile({
    required this.proveedor,
    required this.onTap,
    required this.onDelete,
  });

  String _getInitials(String nombre) {
    final parts = nombre.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, 2).toUpperCase();
  }

  Color _getColor(String nombre) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[nombre.hashCode.abs() % colors.length].shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getColor(proveedor.nombre),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getInitials(proveedor.nombre),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proveedor.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (proveedor.contacto != null)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            proveedor.contacto!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (proveedor.telefono != null) ...[
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            proveedor.telefono!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (proveedor.telefono != null &&
                            proveedor.email != null)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        if (proveedor.email != null)
                          Expanded(
                            child: Text(
                              proveedor.email!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Eliminar',
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
