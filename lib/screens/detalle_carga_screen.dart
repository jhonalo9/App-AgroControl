import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/carga.dart';
import '../models/carretilla.dart';
import '../services/database_service.dart';

class DetalleCargaScreen extends StatefulWidget {
  final int cargaId;

  const DetalleCargaScreen({super.key, required this.cargaId});

  @override
  State<DetalleCargaScreen> createState() => _DetalleCargaScreenState();
}

class _DetalleCargaScreenState extends State<DetalleCargaScreen> {
  final _db = DatabaseService.instance;
  final _formatoMoneda = NumberFormat.currency(locale: 'es_PE', symbol: 'S/. ');

  CargaResumen? _resumen;
  List<Carretilla> _carretillas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final resumen = await _db.getResumenCarga(widget.cargaId);
    final carretillas = await _db.getCarretillasByCarga(widget.cargaId);
    setState(() {
      _resumen = resumen;
      _carretillas = carretillas;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _resumen == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final r = _resumen!;
    final fecha = DateTime.parse(r.carga.fecha);

    return Scaffold(
      appBar: AppBar(title: Text(r.comercianteNombre)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd/MM/yyyy').format(fecha),
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(
                  '${r.pesoTotal.toStringAsFixed(1)} kg · ${r.totalCarretillas} carretillas',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Total: ${_formatoMoneda.format(r.totalPagar)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _carretillas.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = _carretillas[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${c.numero}')),
                  title: Text('${c.peso.toStringAsFixed(1)} kg'),
                  subtitle: r.carga.descuentoKg > 0
                      ? Text('Neto: ${(c.peso - r.carga.descuentoKg).toStringAsFixed(1)} kg')
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}