import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/carga.dart';
import '../services/database_service.dart';
import 'detalle_carga_screen.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _db = DatabaseService.instance;
  final _formatoMoneda = NumberFormat.currency(locale: 'es_PE', symbol: 'S/. ');
  List<CargaResumen> _historial = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await _db.getHistorial();
    setState(() {
      _historial = lista;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _historial.isEmpty
              ? Center(
                  child: Text('Aún no hay cargas finalizadas',
                      style: TextStyle(color: Colors.grey.shade500)),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historial.length,
                    itemBuilder: (context, index) {
                      final item = _historial[index];
                      final fecha = DateTime.parse(item.carga.fecha);
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            item.comercianteNombre,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${DateFormat('dd MMM', 'es').format(fecha)} · '
                              '${item.pesoTotal.toStringAsFixed(0)} kg · '
                              '${item.totalCarretillas} carretillas',
                            ),
                          ),
                          trailing: Text(
                            _formatoMoneda.format(item.totalPagar),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                              fontSize: 15,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalleCargaScreen(cargaId: item.carga.id!),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
