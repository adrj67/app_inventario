import 'package:flutter/material.dart';
import '../../../database/configuracion_repository.dart';
import '../../../models/configuracion.dart';
import 'package:intl/intl.dart';
import '../../../services/backup_service.dart';
import 'dart:io';

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

  // 🔥 NUEVO: Info de backups
  DateTime? _ultimoBackup;
  int _cantidadBackups = 0;
  String _rutaBackups = '';
  bool _cargandoBackups = true;
  bool _creandoBackup = false;

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
    _cargarInfoBackups(); 
  }

  Future<void> _cargarInfoBackups() async {
    setState(() => _cargandoBackups = true);
    try {
      final ultimo = await BackupService.obtenerFechaUltimoBackup();
      final cantidad = await BackupService.contarBackups();
      final ruta = await BackupService.obtenerRutaBackups();

      // 🔥 DEBUG TEMPORAL
      debugPrint('=== INFO BACKUPS ===');
      debugPrint('Último: $ultimo');
      debugPrint('Cantidad: $cantidad');
      debugPrint('Ruta: $ruta');

      // 🔥 DEBUG: listar archivos directamente
      final dir = Directory(ruta);
      if (await dir.exists()) {
        final archivos = dir.listSync();
        debugPrint('Archivos en la carpeta: ${archivos.length}');
        for (final a in archivos) {
          debugPrint('  - ${a.path.split(Platform.pathSeparator).last}');
        }
      } else {
        debugPrint('⚠️ La carpeta NO existe: $ruta');
      }
      debugPrint('====================');

      if (!mounted) return;
      setState(() {
        _ultimoBackup = ultimo;
        _cantidadBackups = cantidad;
        _rutaBackups = ruta;
        _cargandoBackups = false;
      });
    } catch (e) {
      debugPrint('Error cargando info de backups: $e');
      if (mounted) setState(() => _cargandoBackups = false);
    }
  }

  Widget _buildCardBackups() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return _buildCard(
      titulo: 'Backup y Restauración',
      icono: Icons.backup,
      children: [
        if (_cargandoBackups)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          // Info del último backup
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _ultimoBackup != null ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _ultimoBackup != null ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _ultimoBackup != null ? Icons.check_circle : Icons.warning_amber,
                  color: _ultimoBackup != null ? Colors.green.shade700 : Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ultimoBackup != null
                            ? 'Último backup: ${dateFormat.format(_ultimoBackup!)}'
                            : 'Sin backups todavía',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ultimoBackup != null
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_cantidadBackups backup${_cantidadBackups != 1 ? "s" : ""} disponible${_cantidadBackups != 1 ? "s" : ""} · Se mantienen los últimos 7',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botones
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _creandoBackup ? null : _crearBackupManual,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _creandoBackup
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.backup),
                  label: Text(
                    _creandoBackup ? 'Creando...' : 'Crear backup ahora',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cantidadBackups == 0 ? null : _mostrarSelectorBackups,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.restore),
                  label: const Text(
                    'Restaurar backup',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info de la ruta
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.folder, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carpeta de backups',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        _rutaBackups,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Aviso
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El backup automático se ejecuta una vez cada 24 horas. '
                    'Al restaurar, se reemplazan TODOS los datos actuales.',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

    // ==================== CREAR BACKUP ====================

  Future<void> _crearBackupManual() async {
    setState(() => _creandoBackup = true);

    try {
      final archivo = await BackupService.crearBackup();

      if (!mounted) return;
      await _cargarInfoBackups();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Backup creado: ${archivo.path.split('/').last}'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          width: 500,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _creandoBackup = false);
    }
  }

  // ==================== RESTAURAR BACKUP ====================

  Future<void> _mostrarSelectorBackups() async {
    debugPrint('=== INICIANDO _mostrarSelectorBackups ===');

    final backups = await BackupService.listarBackups();

    debugPrint('Backups encontrados: ${backups.length}');

    if (!mounted) return;

    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay backups disponibles'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;

    final seleccionado = await showDialog<BackupInfo>(
      context: context,
      builder: (context) => _SelectorBackupDialog(backups: backups),
    );

    if (seleccionado == null) return;
    if (!mounted) return;

    //if (seleccionado == null) return;

    // Confirmar restauración
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            const Text('Confirmar restauración'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Restaurar el backup del ${DateFormat('dd/MM/yyyy HH:mm').format(seleccionado.fecha)}?',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'TODOS los datos actuales serán reemplazados. '
                      'Se creará un backup del estado actual antes de restaurar.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Ejecutar restauración
    try {
      await BackupService.restaurarBackup(seleccionado.archivo);

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 12),
              const Text('Backup restaurado'),
            ],
          ),
          content: const Text(
            'Los datos fueron restaurados correctamente.\n\n'
            'Cerrá y volvé a abrir la aplicación para ver los cambios.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );

      // Recargar info
      await _cargarInfoBackups();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al restaurar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                        _buildCardBackups(),
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

// ==================== DIÁLOGO SELECTOR DE BACKUP ====================

class _SelectorBackupDialog extends StatefulWidget {
  final List<BackupInfo> backups;

  const _SelectorBackupDialog({required this.backups});

  @override
  State<_SelectorBackupDialog> createState() => _SelectorBackupDialogState();
}

class _SelectorBackupDialogState extends State<_SelectorBackupDialog> {
  BackupInfo? _seleccionado;

  @override
  void initState() {
    super.initState();
    if (widget.backups.isNotEmpty) {
      _seleccionado = widget.backups.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.restore, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Seleccionar backup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.backups.length} backup${widget.backups.length != 1 ? "s" : ""} disponible${widget.backups.length != 1 ? "s" : ""}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Lista
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.backups.length,
                itemBuilder: (context, index) {
                  final backup = widget.backups[index];
                  final isSelected = _seleccionado?.archivo.path == backup.archivo.path;
                  final esReciente = index == 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _seleccionado = backup),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade400,
                              size: 20,
                            ),
                            Icon(
                              Icons.description,
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        dateFormat.format(backup.fecha),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isSelected
                                              ? Colors.blue.shade900
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                      if (esReciente) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade700,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'MÁS RECIENTE',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${backup.tamanioFormateado} · ${backup.nombreArchivo}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _seleccionado == null
                        ? null
                        : () => Navigator.pop(context, _seleccionado),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Seleccionar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}