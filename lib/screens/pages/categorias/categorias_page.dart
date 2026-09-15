import 'package:flutter/material.dart';
import '../../../database/categoria_repository.dart';
import '../../../models/categoria.dart';
import '../../../widgets/search_field.dart';
import 'categoria_form.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  final CategoriaRepository _repository = CategoriaRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Categoria> _categorias = [];
  List<Categoria> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _repository.getAll(soloActivas: true);
      setState(() {
        _categorias = lista;
        _filtered = lista;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _categorias = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _filtrar(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _categorias);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = _categorias.where((c) {
        return c.nombre.toLowerCase().contains(q) ||
            (c.descripcion?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  Future<void> _abrirFormulario({Categoria? categoria}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CategoriaForm(categoria: categoria),
      ),
    );
    if (resultado == true) {
      _searchController.clear();
      await _loadCategorias();
    }
  }

  Future<void> _confirmarEliminar(Categoria categoria) async {
    try {
      final hijos = await _repository.getHijos(categoria.id!);
      if (hijos.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se puede eliminar "${categoria.nombre}": tiene ${hijos.length} subcategorías'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } catch (e) {
      // ignore
    }

    if (!mounted) return;
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Categoría'),
          ],
        ),
        content: Text('¿Eliminar "${categoria.nombre}"?'),
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
      await _repository.delete(categoria.id!);
      await _loadCategorias();
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
            hintText: 'Buscar categorías...',
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
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.category, color: Colors.purple.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} categorías',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _abrirFormulario(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Categoría',
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
            Icon(Icons.category_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay categorías'
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

    // Separar raíces y subcategorías
    final raices = _filtered.where((c) => c.categoriaPadreId == null).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: raices.length,
      itemBuilder: (context, index) {
        final raiz = raices[index];
        final hijos = _filtered.where((c) => c.categoriaPadreId == raiz.id).toList();
        return _CategoriaCard(
          categoria: raiz,
          subcategorias: hijos,
          onTap: () => _abrirFormulario(categoria: raiz),
          onDelete: () => _confirmarEliminar(raiz),
          onSubTap: (sub) => _abrirFormulario(categoria: sub),
          onSubDelete: (sub) => _confirmarEliminar(sub),
        );
      },
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final Categoria categoria;
  final List<Categoria> subcategorias;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(Categoria) onSubTap;
  final Function(Categoria) onSubDelete;

  const _CategoriaCard({
    required this.categoria,
    required this.subcategorias,
    required this.onTap,
    required this.onDelete,
    required this.onSubTap,
    required this.onSubDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.folder, color: Colors.purple.shade700),
        ),
        title: Text(
          categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: categoria.descripcion != null
            ? Text(categoria.descripcion!)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${subcategorias.length} sub',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
          ],
        ),
        children: [
          if (subcategorias.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sin subcategorías',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            )
          else
            ...subcategorias.map((sub) => ListTile(
                  leading: Icon(Icons.subdirectory_arrow_right,
                      color: Colors.grey.shade600),
                  title: Text(sub.nombre),
                  subtitle: sub.descripcion != null ? Text(sub.descripcion!) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: () => onSubDelete(sub),
                  ),
                  onTap: () => onSubTap(sub),
                )),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar categoría'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}