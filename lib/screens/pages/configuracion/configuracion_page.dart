import 'package:flutter/material.dart';
import '../../../database/configuracion_repository.dart';
import '../../../models/configuracion.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final _formKey = GlobalKey<FormState>();
  final ConfiguracionRepository _repository = ConfiguracionRepository();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cuitController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sitioWebController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();

  String? _condicionIva;
  int? _configId;
  bool _isLoading = true;
  bool _guardando = false;

  final List<String> _condicionesIva = [
    'Responsable Inscripto',
    'Monotributo',
    'Exento',
    'Consumidor Final',
    'No Categorizado',
  ];

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cuitController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _sitioWebController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final config = await _repository.get();
      setState(() {
        _configId = config.id;
        _nombreController.text = config.nombreEmpresa;
        _cuitController.text = config.cuit ?? '';
        _direccionController.text = config.direccion ?? '';
        _telefonoController.text = config.telefono ?? '';
        _emailController.text = config.email ?? '';
        _sitioWebController.text = config.sitioWeb ?? '';
        _condicionIva = config.condicionIva ?? 'Responsable Inscripto';
        _observacionesController.text = config.observaciones ?? '';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildCardDatosFiscales(),
                        const SizedBox(height: 16),
                        _buildCardContacto(),
                        const SizedBox(height: 16),
                        _buildCardExtras(),
                        const SizedBox(height: 24),
                        _buildBotones(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.settings,
              color: Colors.deepPurple.shade700,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración de la Empresa',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'Estos datos aparecerán en los presupuestos y documentos',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardDatosFiscales() {
    return _buildCard(
      titulo: 'Datos Fiscales',
      icono: Icons.receipt_long,
      children: [
        _buildTextField(
          controller: _nombreController,
          label: 'Nombre / Razón Social *',
          icon: Icons.business,
          validator: (v) =>
              v?.trim().isEmpty ?? true ? 'El nombre es obligatorio' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _cuitController,
                label: 'CUIT',
                icon: Icons.badge,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _condicionIva,
                decoration: InputDecoration(
                  labelText: 'Condición frente al IVA',
                  prefixIcon:
                      Icon(Icons.gavel, color: Colors.deepPurple.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _condicionesIva
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _condicionIva = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardContacto() {
    return _buildCard(
      titulo: 'Contacto',
      icono: Icons.contact_mail,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _telefonoController,
                label: 'Teléfono',
                icon: Icons.phone,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _direccionController,
          label: 'Dirección',
          icon: Icons.location_on,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _sitioWebController,
          label: 'Sitio Web',
          icon: Icons.language,
        ),
      ],
    );
  }

  Widget _buildCardExtras() {
    return _buildCard(
      titulo: 'Información Adicional',
      icono: Icons.notes,
      children: [
        _buildTextField(
          controller: _observacionesController,
          label: 'Observaciones (aparecerán en los presupuestos)',
          icon: Icons.note,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'El logo de la empresa se agregará en un próximo paso.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotones() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _guardando ? null : _cargarConfiguracion,
          icon: const Icon(Icons.refresh),
          label: const Text('Descartar cambios'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
            _guardando ? 'Guardando...' : 'Guardar Configuración',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
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
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono,
                      color: Colors.deepPurple.shade700, size: 20),
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
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
      final config = Configuracion(
        id: _configId,
        nombreEmpresa: _nombreController.text.trim(),
        cuit: _textoONull(_cuitController.text),
        direccion: _textoONull(_direccionController.text),
        telefono: _textoONull(_telefonoController.text),
        email: _textoONull(_emailController.text),
        sitioWeb: _textoONull(_sitioWebController.text),
        condicionIva: _condicionIva,
        observaciones: _textoONull(_observacionesController.text),
        fechaModificacion: DateTime.now(),
      );

      await _repository.save(config);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String? _textoONull(String texto) {
    final t = texto.trim();
    return t.isEmpty ? null : t;
  }
}