import 'package:flutter/material.dart';
import '../../../database/categoria_repository.dart';
import '../../../models/categoria.dart';

class CategoriaForm extends StatefulWidget {
  final Categoria? categoria;
  final int? categoriaPadreIdPredefinido;

  const CategoriaForm({
    super.key,
    this.categoria,
    this.categoriaPadreIdPredefinido,
  });

  @override
  State<CategoriaForm> createState() => _CategoriaFormState();
}

class _CategoriaFormState extends State<CategoriaForm> {
  final _formKey = GlobalKey<FormState>();
  final CategoriaRepository _repository = CategoriaRepository();

  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;

  bool _activa = true;
  int? _categoriaPadreId;
  List<Categoria> _categoriasDisponibles = [];
  bool _cargando = true;
  bool _guardando = false;

  bool get _esEdicion => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    final c = widget.categoria;
    _nombreController = TextEditingController(text: c?.nombre ?? '');
    _descripcionController = TextEditingController(text: c?.descripcion ?? '');
    _activa = c?.activa ?? true;
    _categoriaPadreId = c?.categoriaPadreId ?? widget.categoriaPadreIdPredefinido;
    _cargarCategorias();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final lista = await _repository.getAll(soloActivas: true);
      // Excluir la categoría actual y sus descendientes
      final disponibles = lista.where((c) {
        if (widget.categoria == null) return true;
        if (c.id == widget.categoria!.id) return false;
        return true;
      }).toList();

      setState(() {
        _categoriasDisponibles = disponibles;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Categoría' : 'Nueva Categoría'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _nombreController,
                        label: 'Nombre *',
                        icon: Icons.category,
                        validator: (v) => v?.trim().isEmpty ?? true
                            ? 'El nombre es obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descripcionController,
                        label: 'Descripción',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      if (!_cargando)
                        DropdownButtonFormField<int>(
                          initialValue: _categoriaPadreId,
                          decoration: InputDecoration(
                            labelText: 'Categoría Padre',
                            prefixIcon: Icon(Icons.folder, color: Colors.purple.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Sin categoría padre (raíz)'),
                            ),
                            ..._categoriasDisponibles.map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.nombre),
                                )),
                          ],
                          onChanged: (v) => setState(() => _categoriaPadreId = v),
                        ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _activa ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _activa ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Switch(
                              value: _activa,
                              onChanged: (v) => setState(() => _activa = v),
                              activeThumbColor: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _activa ? 'Categoría Activa' : 'Categoría Inactiva',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _activa
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _guardando
                                  ? null
                                  : () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _guardando ? null : _guardar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: _guardando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_esEdicion ? 'Actualizar' : 'Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final categoria = Categoria(
        id: widget.categoria?.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        categoriaPadreId: _categoriaPadreId,
        activa: _activa,
        fechaCreacion: widget.categoria?.fechaCreacion ?? DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      await _repository.save(categoria);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _guardando = false);
    }
  }
}