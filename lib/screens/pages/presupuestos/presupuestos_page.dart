import 'package:app_inventario_flutter/screens/pages/presupuestos/presupuesto_form.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/presupuesto_repository.dart';
import '../../../database/cliente_repository.dart';
import '../../../models/presupuesto.dart';
import '../../../models/cliente.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/export_button.dart';


class PresupuestosPage extends StatefulWidget {
  const PresupuestosPage({super.key});

  @override
  State<PresupuestosPage> createState() => _PresupuestosPageState();
}

class _PresupuestosPageState extends State<PresupuestosPage> {
  final PresupuestoRepository _repository = PresupuestoRepository();
  final ClienteRepository _clienteRepository = ClienteRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Presupuesto> _presupuestos = [];
  List<Presupuesto> _filtered = [];
  Map<int, Cliente> _clientesMap = {};
  bool _isLoading = true;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _loadPresupuestos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPresupuestos() async {
    setState(() => _isLoading = true);
    try {
      final presupuestos = await _repository.getAll();
      final clientes = await _clienteRepository.getAll(soloActivos: false);

      final map = <int, Cliente>{};
      for (final c in clientes) {
        if (c.id != null) map[c.id!] = c;
      }

      setState(() {
        _presupuestos = presupuestos;
        _clientesMap = map;
        _isLoading = false;
      });
      _aplicarFiltros();
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _presupuestos = [];
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    List<Presupuesto> resultado = List.from(_presupuestos);

    if (_filtroEstado != 'todos') {
      resultado = resultado.where((p) => p.estado == _filtroEstado).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado.where((p) {
        final cliente = _clientesMap[p.clienteId];
        return p.numero.toLowerCase().contains(query) ||
            (p.nota?.toLowerCase().contains(query) ?? false) ||
            (cliente?.nombre.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() => _filtered = resultado);
  }

  Future<void> _abrirFormulario({Presupuesto? presupuesto}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PresupuestoForm(presupuesto: presupuesto),
      ),
    );
    if (resultado == true) {
      _searchController.clear();
      _filtroEstado = 'todos';
      await _loadPresupuestos();
    }
  }

  Future<void> _confirmarEliminar(Presupuesto presupuesto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Presupuesto'),
          ],
        ),
        content: Text('¿Eliminar el presupuesto ${presupuesto.numero}?'),
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
      await _repository.delete(presupuesto.id!);
      await _loadPresupuestos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: SearchField(
            controller: _searchController,
            onChanged: (_) => _aplicarFiltros(),
            hintText: 'Buscar por número, cliente o nota...',
          ),
        ),
        _buildFiltros(),
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
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.request_quote,
                  color: Colors.deepOrange.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Presupuestos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_filtered.length} presupuestos',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ExportButton(
                titulo: 'Presupuestos',
                headers: const [
                  'Número', 'Fecha', 'Vencimiento', 'Cliente',
                  'Subtotal', 'IVA', 'Total', 'Estado',
                ],
                rows: _filtered.map((p) {
                  final cliente = _clientesMap[p.clienteId];
                  return [
                    p.numero,
                    DateFormat('dd/MM/yyyy').format(p.fecha),
                    DateFormat('dd/MM/yyyy').format(p.fechaVencimiento),
                    cliente?.nombre ?? '(sin cliente)',
                    p.subtotal.toStringAsFixed(2),
                    p.iva.toStringAsFixed(2),
                    p.total.toStringAsFixed(2),
                    p.estado,
                  ];
                }).toList(),
                color: Colors.deepOrange,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _abrirFormulario(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Nuevo Presupuesto',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Todos', 'todos', Icons.list),
          const SizedBox(width: 8),
          _buildFilterChip('Pendientes', 'pendiente', Icons.schedule, Colors.orange),
          const SizedBox(width: 8),
          _buildFilterChip('Aprobados', 'aprobado', Icons.check_circle, Colors.green),
          const SizedBox(width: 8),
          _buildFilterChip('Rechazados', 'rechazado', Icons.cancel, Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, [MaterialColor? color]) {
    final isSelected = _filtroEstado == value;
    final baseColor = color ?? Colors.deepOrange;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : baseColor.shade700),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      selectedColor: baseColor.shade700,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? baseColor.shade700 : Colors.grey.shade300),
      onSelected: (selected) {
        setState(() => _filtroEstado = value);
        _aplicarFiltros();
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.request_quote_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty && _filtroEstado == 'todos'
                  ? 'No hay presupuestos'
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

    return RefreshIndicator(
      onRefresh: _loadPresupuestos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final p = _filtered[index];
          final cliente = _clientesMap[p.clienteId];
          return _PresupuestoCard(
            presupuesto: p,
            cliente: cliente,
            onTap: () => _abrirFormulario(presupuesto: p),
            onDelete: () => _confirmarEliminar(p),
          );
        },
      ),
    );
  }
}

class _PresupuestoCard extends StatelessWidget {
  final Presupuesto presupuesto;
  final Cliente? cliente;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PresupuestoCard({
    required this.presupuesto,
    required this.cliente,
    required this.onTap,
    required this.onDelete,
  });

  MaterialColor _getEstadoColor() {
    switch (presupuesto.estado) {
      case 'aprobado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      case 'vencido':
        return Colors.grey;
      default:
        return presupuesto.estaVencido ? Colors.grey : Colors.orange;
    }
  }

  IconData _getEstadoIcon() {
    switch (presupuesto.estado) {
      case 'aprobado':
        return Icons.check_circle;
      case 'rechazado':
        return Icons.cancel;
      case 'vencido':
        return Icons.schedule;
      default:
        return presupuesto.estaVencido ? Icons.schedule : Icons.pending;
    }
  }

  String _getEstadoLabel() {
    if (presupuesto.estaVencido &&
        presupuesto.estado != 'aprobado' &&
        presupuesto.estado != 'rechazado') {
      return 'Vencido';
    }
    return presupuesto.estado[0].toUpperCase() + presupuesto.estado.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getEstadoColor();
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

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
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getEstadoIcon(), color: color.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          presupuesto.numero,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: color.shade200),
                          ),
                          child: Text(
                            _getEstadoLabel(),
                            style: TextStyle(
                              fontSize: 10,
                              color: color.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cliente?.nombre ?? 'Sin cliente',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Vence: ${dateFormat.format(presupuesto.fechaVencimiento)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text(
                      currencyFormat.format(presupuesto.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
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
}