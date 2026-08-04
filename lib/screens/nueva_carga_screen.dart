import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/carga.dart';
import '../models/comerciante.dart';
import '../services/database_service.dart';
import 'registro_carretillas_screen.dart';

class NuevaCargaScreen extends StatefulWidget {
  const NuevaCargaScreen({super.key});

  @override
  State<NuevaCargaScreen> createState() => _NuevaCargaScreenState();
}

class _NuevaCargaScreenState extends State<NuevaCargaScreen> {
  final _db = DatabaseService.instance;
  final _precioController = TextEditingController();
  final _descuentoController = TextEditingController(text: '0');

  List<Comerciante> _comerciantes = [];
  Comerciante? _comercianteSeleccionado;
  DateTime _fecha = DateTime.now();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarComerciantes();
  }

  Future<void> _cargarComerciantes() async {
    final lista = await _db.getComerciantes();
    setState(() {
      _comerciantes = lista;
      _comercianteSeleccionado = lista.isNotEmpty ? lista.first : null;
      _cargando = false;
    });
  }

  Future<void> _agregarComercianteRapido() async {
    final nombreController = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo comerciante'),
        content: TextField(
          controller: nombreController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, nombreController.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nombre != null && nombre.isNotEmpty) {
      final id = await _db.insertComerciante(Comerciante(nombre: nombre));
      await _cargarComerciantes();
      setState(() {
        _comercianteSeleccionado =
            _comerciantes.firstWhere((c) => c.id == id, orElse: () => _comerciantes.first);
      });
    }
  }

  Future<void> _elegirFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (seleccion != null) {
      setState(() => _fecha = seleccion);
    }
  }

  Future<void> _iniciarCarga() async {
    final precio = double.tryParse(_precioController.text.replaceAll(',', '.'));
    final descuentoTexto = _descuentoController.text.trim();
    final descuento = descuentoTexto.isEmpty
        ? 0.0
        : double.tryParse(descuentoTexto.replaceAll(',', '.'));

    if (_comercianteSeleccionado == null) {
      _mostrarError('Selecciona un comerciante');
      return;
    }
    if (precio == null || precio <= 0) {
      _mostrarError('Ingresa un precio por kg válido');
      return;
    }
    if (descuento == null || descuento <0) {
      _mostrarError('Ingresa un descuento por carretilla válido (o deja 0)');
      return;
    }

    try {
      final carga = Carga(
        comercianteId: _comercianteSeleccionado!.id!,
        precioKg: precio,
        descuentoKg: descuento,
        fecha: _fecha.toIso8601String(),
      );

      final cargaId = await _db.insertCarga(carga);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegistroCarretillasScreen(
            cargaId: cargaId,
            comercianteNombre: _comercianteSeleccionado!.nombre,
            descuentoKg: descuento,
          ),
        ),
      );
    } catch (e, stack) {
      // Con esto, si algo falla ya NO se queda en blanco: te muestra el error.
      debugPrint('Error al iniciar carga: $e\n$stack');
      if (!mounted) return;
      _mostrarError('Ocurrió un error al iniciar la carga: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva carga')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Comerciante', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _comerciantes.isEmpty
                            ? Text('No hay comerciantes. Agrega uno →',
                                style: TextStyle(color: Colors.grey.shade600))
                            : DropdownButtonFormField<Comerciante>(
                                value: _comercianteSeleccionado,
                                items: _comerciantes
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c.nombre)))
                                    .toList(),
                                onChanged: (c) => setState(() => _comercianteSeleccionado = c),
                              ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _agregarComercianteRapido,
                        icon: const Icon(Icons.add),
                        tooltip: 'Agregar comerciante',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Precio por kg', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _precioController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(prefixText: 'S/. '),
                  ),
                  const SizedBox(height: 20),
                  const Text('Fecha', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _elegirFecha,
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd/MM/yyyy').format(_fecha)),
                          const Icon(Icons.calendar_today_outlined, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Descuento por carretilla (peso tara)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Peso vacío de la carretilla que se resta de cada pesada',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descuentoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(suffixText: 'kg'),
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton(
                    onPressed: _comerciantes.isEmpty ? null : _iniciarCarga,
                    child: const Text('Iniciar carga'),
                  ),
                ],
              ),
            ),
    );
  }
}