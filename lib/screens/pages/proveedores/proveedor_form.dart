import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../database/proveedor_repository.dart';
import '../../../models/proveedor.dart';

class ProveedorForm extends StatefulWidget {
  final Proveedor? proveedor;

  const ProveedorForm({super.key, this.proveedor});

  @override
  State<ProveedorForm> createState() => _ProveedorFormState();
}

class _ProveedorFormState extends State<ProveedorForm> {
  final _formKey = GlobalKey<FormState>();
  final ProveedorRepository _repository = ProveedorRepository();

  late final TextEditingController _nombreController;
  late final TextEditingController _cuitController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;
  late final TextEditingController _direccionController;
  late final TextEditingController _contactoController;
  late final TextEditingController _notaController;

  bool _activo = true;
  bool _guardando = false;

  bool get _esEdicion => widget.proveedor != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proveedor;
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _cuitController = TextEditingController(text: p?.cuit ?? '');
    _telefonoController = TextEditingController(text: p?.telefono ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _direccionController = TextEditingController(text: p?.direccion ?? '');
    _contactoController = TextEditingController(text: p?.contacto ?? '');
    _notaController = TextEditingController(text: p?.nota ?? '');
    _activo = p?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cuitController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _contactoController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor'),
        backgroundColor: Colors.blue.shade700,
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
              constraints: const BoxConstraints(maxWidth: 800),
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
                      _buildSeccion('Información Principal', Icons.info_outline),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nombreController,
                        label: 'Nombre del Proveedor *',
                        icon: Icons.business,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cuitController,
                              label: 'CUIT',
                              icon: Icons.badge,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                                LengthLimitingTextInputFormatter(13),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _telefonoController,
                              label: 'Teléfono',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSeccion('Contacto', Icons.contact_mail),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _contactoController,
                        label: 'Persona de Contacto',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 24),
                      _buildSeccion('Dirección y Notas', Icons.location_on),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _direccionController,
                        label: 'Dirección',
                        icon: Icons.home,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _notaController,
                        label: 'Notas / Observaciones',
                        icon: Icons.note,
                        maxLines: 3,
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
                              activeThumbColor: Colors.green,  // ✅ NUEVO
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _activo ? 'Proveedor Activo' : 'Proveedor Inactivo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _activo ? Colors.green.shade700 : Colors.red.shade700,
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
                                backgroundColor: Colors.blue.shade700,
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
                              label: Text(
                                _guardando
                                    ? 'Guardando...'
                                    : (_esEdicion ? 'Actualizar' : 'Guardar'),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
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

  Widget _buildSeccion(String titulo, IconData icono) {
    return Row(
      children: [
        Icon(icono, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
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
      final proveedor = Proveedor(
        id: widget.proveedor?.id,
        nombre: _nombreController.text.trim(),
        cuit: _textoONull(_cuitController.text),
        telefono: _textoONull(_telefonoController.text),
        email: _textoONull(_emailController.text),
        direccion: _textoONull(_direccionController.text),
        contacto: _textoONull(_contactoController.text),
        nota: _textoONull(_notaController.text),
        activo: _activo,
        fechaCreacion: widget.proveedor?.fechaCreacion ?? DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      await _repository.save(proveedor);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _guardando = false);
    }
  }

  String? _textoONull(String texto) {
    final t = texto.trim();
    return t.isEmpty ? null : t;
  }
}