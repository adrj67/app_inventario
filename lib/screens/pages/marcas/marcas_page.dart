import 'package:flutter/material.dart';
import '../../../database/marca_repository.dart';
import '../../../models/marca.dart';
import '../../../widgets/search_field.dart';
import 'marca_form.dart';
import '../../../widgets/export_button.dart';

class MarcasPage extends StatefulWidget {
  const MarcasPage({super.key});

  @override
  State<MarcasPage> createState() => _MarcasPageState();
}

class _MarcasPageState extends State<MarcasPage> {
  final MarcaRepository _repository = MarcaRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Marca> _marcas = [];
  List<Marca> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarcas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarcas() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _repository.getAll();
      setState(() {
        _marcas = lista;
        _filtered = lista;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _marcas = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _filtrar(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _marcas);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = _marcas.where((m) {
        return m.nombre.toLowerCase().contains(q) ||
            (m.descripcion?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  Future<void> _abrirFormulario({Marca? marca}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MarcaForm(marca: marca),
      ),
    );
    if (resultado == true) {
      _searchController.clear();
      await _loadMarcas();
    }
  }

  Future<void> _confirmarEliminar(Marca marca) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Marca'),
          ],
        ),
        content: Text('¿Eliminar "${marca.nombre}"?'),
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
      await _repository.delete(marca.id!);
      await _loadMarcas();
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
            hintText: 'Buscar marcas...',
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
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_offer, color: Colors.teal.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marcas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} marcas',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ExportButton(
                titulo: 'Marcas',
                headers: const ['ID', 'Nombre', 'Descripción', 'Estado'],
                rows: _filtered.map((m) => [
                  (m.id ?? '').toString(),
                  m.nombre,
                  m.descripcion ?? '',
                  m.activa ? 'Activa' : 'Inactiva',
                ]).toList(),
                color: Colors.teal,
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _abrirFormulario(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Marca',
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
            Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'No hay marcas' : 'Sin resultados',
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
        final marca = _filtered[index];
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
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  marca.nombre.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              marca.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: marca.descripcion != null ? Text(marca.descripcion!) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _abrirFormulario(marca: marca),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmarEliminar(marca),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
            onTap: () => _abrirFormulario(marca: marca),
          ),
        );
      },
    );
  }
}