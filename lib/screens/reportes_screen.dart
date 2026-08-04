import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/carga.dart';
import '../services/database_service.dart';

/// Reporte simple con totales generales. Se puede ampliar más adelante
/// (por rango de fechas, por comerciante, gráficos, etc.).
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
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
    final pesoTotal = _historial.fold(0.0, (s, c) => s + c.pesoTotal);
    final montoTotal = _historial.fold(0.0, (s, c) => s + c.totalPagar);
    final totalCarretillas = _historial.fold(0, (s, c) => s + c.totalCarretillas);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _TarjetaReporte(
                  icono: Icons.local_shipping_outlined,
                  titulo: 'Cargas finalizadas',
                  valor: '${_historial.length}',
                ),
                _TarjetaReporte(
                  icono: Icons.scale_outlined,
                  titulo: 'Peso total acumulado',
                  valor: '${pesoTotal.toStringAsFixed(1)} kg',
                ),
                _TarjetaReporte(
                  icono: Icons.shopping_basket_outlined,
                  titulo: 'Total carretillas',
                  valor: '$totalCarretillas',
                ),
                _TarjetaReporte(
                  icono: Icons.payments_outlined,
                  titulo: 'Monto total pagado',
                  valor: _formatoMoneda.format(montoTotal),
                  destacado: true,
                ),
              ],
            ),
    );
  }
}

class _TarjetaReporte extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final bool destacado;

  const _TarjetaReporte({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icono, color: destacado ? const Color(0xFFEF6C00) : const Color(0xFF2E7D32)),
        title: Text(titulo),
        trailing: Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: destacado ? const Color(0xFFEF6C00) : Colors.black87,
          ),
        ),
      ),
    );
  }
}
