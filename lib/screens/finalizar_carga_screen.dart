import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/carga.dart';
import '../models/carretilla.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

class FinalizarCargaScreen extends StatefulWidget {
  final int cargaId;

  const FinalizarCargaScreen({super.key, required this.cargaId});

  @override
  State<FinalizarCargaScreen> createState() => _FinalizarCargaScreenState();
}

class _FinalizarCargaScreenState extends State<FinalizarCargaScreen> {
  final _db = DatabaseService.instance;
  final _formatoMoneda = NumberFormat.currency(locale: 'es_PE', symbol: 'S/. ');

  CargaResumen? _resumen;
  bool _cargando = true;
  bool _yaFinalizada = false;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    final resumen = await _db.getResumenCarga(widget.cargaId);
    setState(() {
      _resumen = resumen;
      _cargando = false;
    });
  }

  Future<Uint8List> _generarPdf(CargaResumen resumen, List<Carretilla> carretillas) async {
    final doc = pw.Document();
    final fecha = DateTime.parse(resumen.carga.fecha);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Papayas App - Resumen de carga',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}'),
              pw.Text('Comerciante: ${resumen.comercianteNombre}'),
              pw.Text('Precio por kg: ${_formatoMoneda.format(resumen.carga.precioKg)}'),
              if (resumen.carga.descuentoKg > 0)
                pw.Text(
                    'Descuento por carretilla (tara): ${resumen.carga.descuentoKg.toStringAsFixed(1)} kg'),
              pw.SizedBox(height: 16),
              pw.Text('Detalle de carretillas',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: resumen.carga.descuentoKg > 0
                    ? ['#', 'Peso bruto (kg)', 'Peso neto (kg)']
                    : ['#', 'Peso (kg)'],
                data: carretillas.map((c) {
                  if (resumen.carga.descuentoKg > 0) {
                    return [
                      c.numero.toString(),
                      c.peso.toStringAsFixed(1),
                      (c.peso - resumen.carga.descuentoKg).toStringAsFixed(1),
                    ];
                  }
                  return [c.numero.toString(), c.peso.toStringAsFixed(1)];
                }).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total carretillas'),
                  pw.Text('${resumen.totalCarretillas}'),
                ],
              ),
              if (resumen.carga.descuentoKg > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Peso bruto total'),
                    pw.Text('${resumen.pesoBrutoTotal.toStringAsFixed(1)} kg'),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Peso total (neto)'),
                  pw.Text('${resumen.pesoTotal.toStringAsFixed(1)} kg'),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL A PAGAR',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatoMoneda.format(resumen.totalPagar),
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<void> _imprimir() async {
    final carretillas = await _db.getCarretillasByCarga(widget.cargaId);
    final pdfBytes = await _generarPdf(_resumen!, carretillas);
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  Future<void> _compartirPdf() async {
    final carretillas = await _db.getCarretillasByCarga(widget.cargaId);
    final pdfBytes = await _generarPdf(_resumen!, carretillas);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'carga_${widget.cargaId}.pdf',
    );
  }

  Future<void> _finalizar() async {
    await _db.finalizarCarga(widget.cargaId);
    setState(() => _yaFinalizada = true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carga finalizada y guardada')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _resumen == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final r = _resumen!;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _FilaResumen(label: 'Comerciante', valor: r.comercianteNombre),
                    const Divider(),
                    _FilaResumen(label: 'Carretillas', valor: '${r.totalCarretillas}'),
                    const Divider(),
                    if (r.carga.descuentoKg > 0) ...[
                      _FilaResumen(
                          label: 'Peso bruto', valor: '${r.pesoBrutoTotal.toStringAsFixed(1)} kg'),
                      const Divider(),
                      _FilaResumen(
                          label: 'Descuento (tara)',
                          valor: '${r.carga.descuentoKg.toStringAsFixed(1)} kg × carretilla'),
                      const Divider(),
                    ],
                    _FilaResumen(label: 'Peso neto', valor: '${r.pesoTotal.toStringAsFixed(1)} kg'),
                    const Divider(),
                    _FilaResumen(label: 'Precio', valor: _formatoMoneda.format(r.carga.precioKg)),
                    const Divider(),
                    _FilaResumen(
                      label: 'Total',
                      valor: _formatoMoneda.format(r.totalPagar),
                      destacado: true,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _yaFinalizada ? null : _finalizar,
              child: const Text('Finalizar'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _imprimir,
              icon: const Icon(Icons.print_outlined),
              label: const Text('Imprimir'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _compartirPdf,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String label;
  final String valor;
  final bool destacado;

  const _FilaResumen({required this.label, required this.valor, this.destacado = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: destacado ? 18 : 15, color: Colors.grey.shade700)),
          Text(
            valor,
            style: TextStyle(
              fontSize: destacado ? 20 : 16,
              fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
              color: destacado ? const Color(0xFFEF6C00) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}