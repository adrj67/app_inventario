import 'package:flutter/material.dart';
import '../../../database/ubicacion_repository.dart';
import '../../../models/ubicacion.dart';

class UbicacionForm extends StatefulWidget {
  final Ubicacion? ubicacion;

  const UbicacionForm({super.key, this.ubicacion});

  @override
  State<UbicacionForm> createState() => _UbicacionFormState();
}

class _UbicacionFormState extends State<UbicacionForm> {
  final _formKey = GlobalKey<FormState>();
  final UbicacionRepository _repository = UbicacionRepository();

  late final TextEditingController _depositoController;
  late final TextEditingController _pasilloController;
  late final TextEditingController _estanteController;
  late final TextEditingController _nivelController;
  late final TextEditingController _codigoQRController;
  late final TextEditingController _descripcionController;

  bool _activo = true;
  bool _guardando = false;

  bool get _esEdicion => widget.ubicacion != null;

  @override
  void initState() {
    super.initState();
    final u = widget.ubicacion;
    _depositoController = TextEditingController(text: u?.deposito ?? '');
    _pasilloController = TextEditingController(text: u?.pasillo ?? '');
    _estanteController = TextEditingController(text: u?.estante ?? '');
    _nivelController = TextEditingController(text: u?.nivel ?? '');
    _codigoQRController = TextEditingController(text: u?.codigoQR ?? '');
    _descripcionController = TextEditingController(text: u?.descripcion ?? '');
    _activo = u?.activo ?? true;
  }

  @override
  void dispose() {
    _depositoController.dispose();
    _pasilloController.dispose();
    _estanteController.dispose();
    _nivelController.dispose();
    _codigoQRController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Ubicación' : 'Nueva Ubicación'),
        backgroundColor: Colors.indigo.shade700,
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
                        controller: _depositoController,
                        label: 'Depósito *',
                        icon: Icons.warehouse,
                        validator: (v) => v?.trim().isEmpty ?? true
                            ? 'El depósito es obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _pasilloController,
                              label: 'Pasillo',
                              icon: Icons.door_sliding,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _estanteController,
                              label: 'Estante',
                              icon: Icons.shelves,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _nivelController,
                              label: 'Nivel',
                              icon: Icons.stairs,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _codigoQRController,
                        label: 'Código QR',
                        icon: Icons.qr_code,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descripcionController,
                        label: 'Descripción',
                        icon: Icons.description,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _activo ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _activo ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Switch(
                              value: _activo,
                              onChanged: (v) => setState(() => _activo = v),
                              activeThumbColor: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _activo ? 'Ubicación Activa' : 'Ubicación Inactiva',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _activo
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
                                backgroundColor: Colors.indigo.shade700,
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
        prefixIcon: Icon(icon, color: Colors.indigo.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
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
      final ubicacion = Ubicacion(
        id: widget.ubicacion?.id,
        deposito: _depositoController.text.trim(),
        pasillo: _pasilloController.text.trim().isEmpty
            ? null
            : _pasilloController.text.trim(),
        estante: _estanteController.text.trim().isEmpty
            ? null
            : _estanteController.text.trim(),
        nivel: _nivelController.text.trim().isEmpty
            ? null
            : _nivelController.text.trim(),
        codigoQR: _codigoQRController.text.trim().isEmpty
            ? null
            : _codigoQRController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        activo: _activo,
        fechaCreacion: widget.ubicacion?.fechaCreacion ?? DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      await _repository.save(ubicacion);
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