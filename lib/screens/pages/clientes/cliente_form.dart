import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../database/cliente_repository.dart';
import '../../../models/cliente.dart';

class ClienteForm extends StatefulWidget {
  final Cliente? cliente;

  const ClienteForm({super.key, this.cliente});

  @override
  State<ClienteForm> createState() => _ClienteFormState();
}

class _ClienteFormState extends State<ClienteForm> {
  final _formKey = GlobalKey<FormState>();
  final ClienteRepository _repository = ClienteRepository();

  late final TextEditingController _nombreController;
  late final TextEditingController _cuitController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;
  late final TextEditingController _direccionController;
  late final TextEditingController _localidadController;
  late final TextEditingController _notaController;

  bool _activo = true;
  bool _guardando = false;

  bool get _esEdicion => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombreController = TextEditingController(text: c?.nombre ?? '');
    _cuitController = TextEditingController(text: c?.cuit ?? '');
    _telefonoController = TextEditingController(text: c?.telefono ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _direccionController = TextEditingController(text: c?.direccion ?? '');
    _localidadController = TextEditingController(text: c?.localidad ?? '');
    _notaController = TextEditingController(text: c?.nota ?? '');
    _activo = c?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cuitController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _localidadController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Cliente' : 'Nuevo Cliente'),
        backgroundColor: Colors.cyan.shade700,
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
              child: Column(
                children: [
                  // Sección: Información Principal
                  _buildCard(
                    titulo: 'Información Principal',
                    icono: Icons.person,
                    children: [
                      _buildTextField(
                        controller: _nombreController,
                        label: 'Nombre / Razón Social *',
                        icon: Icons.person,
                        validator: (v) => v?.trim().isEmpty ?? true
                            ? 'El nombre es obligatorio'
                            : null,
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
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sección: Contacto
                  _buildCard(
                    titulo: 'Contacto y Dirección',
                    icono: Icons.contact_mail,
                    children: [
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _direccionController,
                              label: 'Dirección',
                              icon: Icons.home,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _localidadController,
                              label: 'Localidad',
                              icon: Icons.location_city,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _notaController,
                        label: 'Notas / Observaciones',
                        icon: Icons.note,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Estado
                  _buildCard(
                    titulo: 'Estado',
                    icono: Icons.toggle_on,
                    children: [
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
                              _activo ? 'Cliente Activo' : 'Cliente Inactivo',
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
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botones
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
                            backgroundColor: Colors.cyan.shade700,
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
                            _esEdicion ? 'Actualizar Cliente' : 'Guardar Cliente',
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
    );
  }

  Widget _buildCard({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: Colors.cyan.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
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
        prefixIcon: Icon(icon, color: Colors.cyan.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.cyan.shade700, width: 2),
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
      final cliente = Cliente(
        id: widget.cliente?.id,
        nombre: _nombreController.text.trim(),
        cuit: _textoONull(_cuitController.text),
        telefono: _textoONull(_telefonoController.text),
        email: _textoONull(_emailController.text),
        direccion: _textoONull(_direccionController.text),
        localidad: _textoONull(_localidadController.text),
        nota: _textoONull(_notaController.text),
        activo: _activo,
        fechaCreacion: widget.cliente?.fechaCreacion ?? DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      await _repository.save(cliente);
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

  String? _textoONull(String texto) {
    final t = texto.trim();
    return t.isEmpty ? null : t;
  }
}