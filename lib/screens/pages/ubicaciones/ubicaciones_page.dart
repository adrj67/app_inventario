import 'package:flutter/material.dart';
import '../../../database/ubicacion_repository.dart';
import '../../../models/ubicacion.dart';
import '../../../widgets/search_field.dart';
import 'ubicacion_form.dart';
import '../../../widgets/export_button.dart';

class UbicacionesPage extends StatefulWidget {
  const UbicacionesPage({super.key});

  @override
  State<UbicacionesPage> createState() => _UbicacionesPageState();
}

class _UbicacionesPageState extends State<UbicacionesPage> {
  final UbicacionRepository _repository = UbicacionRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Ubicacion> _ubicaciones = [];
  List<Ubicacion> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUbicaciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUbicaciones() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _repository.getAll();
      setState(() {
        _ubicaciones = lista;
        _filtered = lista;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _ubicaciones = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _filtrar(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _ubicaciones);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = _ubicaciones.where((u) {
        return u.deposito.toLowerCase().contains(q) ||
            (u.pasillo?.toLowerCase().contains(q) ?? false) ||
            (u.estante?.toLowerCase().contains(q) ?? false) ||
            (u.descripcion?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  Future<void> _abrirFormulario({Ubicacion? ubicacion}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => UbicacionForm(ubicacion: ubicacion),
      ),
    );
    if (resultado == true) {
      _searchController.clear();
      await _loadUbicaciones();
    }
  }

  Future<void> _confirmarEliminar(Ubicacion ubicacion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Ubicación'),
          ],
        ),
        content: Text('¿Eliminar "${ubicacion.nombreCompleto}"?'),
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
      await _repository.delete(ubicacion.id!);
      await _loadUbicaciones();
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
            hintText: 'Buscar por depósito, pasillo, estante...',
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
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: Colors.indigo.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubicaciones',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} ubicaciones',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ExportButton(
                titulo: 'Ubicaciones',
                headers: const [
                  'ID', 'Depósito', 'Pasillo', 'Estante', 'Nivel', 'Código QR', 'Descripción',
                ],
                rows: _filtered.map((u) => [
                  (u.id ?? '').toString(),
                  u.deposito,
                  u.pasillo ?? '',
                  u.estante ?? '',
                  u.nivel ?? '',
                  u.codigoQR ?? '',
                  u.descripcion ?? '',
                ]).toList(),
                color: Colors.indigo,
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _abrirFormulario(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Ubicación',
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
            Icon(Icons.location_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay ubicaciones'
                  : 'Sin resultados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final ubicacion = _filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warehouse, color: Colors.indigo.shade700),
            ),
            title: Text(
              ubicacion.deposito,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    if (ubicacion.pasillo != null)
                      _buildTag('Pasillo ${ubicacion.pasillo}'),
                    if (ubicacion.estante != null)
                      _buildTag('Estante ${ubicacion.estante}'),
                    if (ubicacion.nivel != null)
                      _buildTag('Nivel ${ubicacion.nivel}'),
                  ],
                ),
                if (ubicacion.descripcion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ubicacion.descripcion!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _abrirFormulario(ubicacion: ubicacion),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmarEliminar(ubicacion),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
            onTap: () => _abrirFormulario(ubicacion: ubicacion),
          ),
        );
      },
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.indigo.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}