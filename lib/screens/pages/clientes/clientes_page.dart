import 'package:flutter/material.dart';
import '../../../database/cliente_repository.dart';
import '../../../models/cliente.dart';
import '../../../widgets/search_field.dart';
import 'cliente_form.dart';
import '../../../widgets/export_button.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final ClienteRepository _repository = ClienteRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Cliente> _clientes = [];
  List<Cliente> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClientes() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _repository.getAll();
      setState(() {
        _clientes = lista;
        _filtered = lista;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _clientes = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _filtrar(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _clientes);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = _clientes.where((c) {
        return c.nombre.toLowerCase().contains(q) ||
            (c.cuit?.toLowerCase().contains(q) ?? false) ||
            (c.telefono?.toLowerCase().contains(q) ?? false) ||
            (c.email?.toLowerCase().contains(q) ?? false) ||
            (c.localidad?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  Future<void> _abrirFormulario({Cliente? cliente}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ClienteForm(cliente: cliente),
      ),
    );
    if (resultado == true) {
      _searchController.clear();
      await _loadClientes();
    }
  }

  Future<void> _confirmarEliminar(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Cliente'),
          ],
        ),
        content: Text('¿Eliminar a "${cliente.nombre}"?'),
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
      await _repository.delete(cliente.id!);
      await _loadClientes();
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
            hintText: 'Buscar por nombre, CUIT, teléfono, email...',
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people, color: Colors.cyan.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clientes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} clientes',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ExportButton(
                titulo: 'Clientes',
                headers: const [
                  'ID', 'Nombre', 'CUIT', 'Teléfono', 'Email',
                  'Dirección', 'Localidad', 'Estado',
                ],
                rows: _filtered.map((c) => [
                  (c.id ?? '').toString(),
                  c.nombre,
                  c.cuit ?? '',
                  c.telefono ?? '',
                  c.email ?? '',
                  c.direccion ?? '',
                  c.localidad ?? '',
                  c.activo ? 'Activo' : 'Inactivo',
                ]).toList(),
                color: Colors.cyan,
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _abrirFormulario(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Cliente',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay clientes registrados'
                  : 'Sin resultados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Presiona "Nuevo Cliente" para comenzar'
                  : 'Intenta con otros términos',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final cliente = _filtered[index];
        return _ClienteCard(
          cliente: cliente,
          onTap: () => _abrirFormulario(cliente: cliente),
          onDelete: () => _confirmarEliminar(cliente),
        );
      },
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ClienteCard({
    required this.cliente,
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
      Colors.cyan,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.indigo,
      Colors.purple,
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
                  color: _getColor(cliente.nombre),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getInitials(cliente.nombre),
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
                      cliente.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (cliente.telefono != null)
                          _buildInfo(Icons.phone, cliente.telefono!),
                        if (cliente.email != null)
                          _buildInfo(Icons.email, cliente.email!),
                        if (cliente.localidad != null)
                          _buildInfo(Icons.location_city, cliente.localidad!),
                      ],
                    ),
                    if (cliente.cuit != null) ...[
                      const SizedBox(height: 4),
                      _buildInfo(Icons.badge, cliente.cuit!, small: true),
                    ],
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

  Widget _buildInfo(IconData icon, String text, {bool small = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: small ? 12 : 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: small ? 11 : 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}