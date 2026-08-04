import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/carretilla.dart';
import '../services/database_service.dart';
import 'finalizar_carga_screen.dart';

class RegistroCarretillasScreen extends StatefulWidget {
  final int cargaId;
  final String comercianteNombre;
  final double descuentoKg;

  const RegistroCarretillasScreen({
    super.key,
    required this.cargaId,
    required this.comercianteNombre,
    this.descuentoKg = 0,
  });

  @override
  State<RegistroCarretillasScreen> createState() => _RegistroCarretillasScreenState();
}

class _RegistroCarretillasScreenState extends State<RegistroCarretillasScreen> {
  final _db = DatabaseService.instance;
  final _pesoController = TextEditingController();
  final _pesoFocus = FocusNode();

  List<Carretilla> _carretillas = [];
  bool _cargando = true;
  bool _tieneDatosIngresados = false;
   double _descuentoKg = 0.0;

  double get _totalPesoBruto => _carretillas.fold(0, (suma, c) => suma + c.peso);
  double get _totalPesoNeto => _totalPesoBruto - (widget.descuentoKg * _totalCarretillas);
  int get _totalCarretillas => _carretillas.length;

  @override
  void initState() {
    super.initState();
    _cargarCarretillas();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _pesoFocus.dispose();
    super.dispose();
  }

  Future<void> _cargarCarretillas() async {
    try {
      final lista = await _db.getCarretillasByCarga(widget.cargaId);
      setState(() {
        _carretillas = lista;
        _cargando = false;
        _tieneDatosIngresados = lista.isNotEmpty;
      });
    } catch (e, stack) {
      debugPrint('Error al cargar carretillas: $e\n$stack');
      setState(() {
        _cargando = false;
      });
      _mostrarError('Error al cargar carretillas: $e');
    }
  }



  Future<void> _editarPesoTara() async {
  final pesoController = TextEditingController(
    text: widget.descuentoKg.toString(),
  );


  Future<void> _editarPesoTara() async {
  final pesoController = TextEditingController(
    text: _descuentoKg.toString(),
  );
  
  final nuevoPesoTara = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Editar peso tara'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Peso vacío de la carretilla que se resta de cada pesada'),
          const SizedBox(height: 8),
          TextField(
            controller: pesoController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Peso tara',
              suffixText: 'kg',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final peso = double.tryParse(pesoController.text.replaceAll(',', '.'));
            if (peso != null && peso >= 0) {
              Navigator.pop(context, peso);
            } else {
              _mostrarError('Ingresa un peso válido');
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );

  if (nuevoPesoTara != null && nuevoPesoTara != _descuentoKg) {
    // Actualizar el descuento en la base de datos
    try {
      await _db.updateCargaDescuento(widget.cargaId, nuevoPesoTara);
      
      // Actualizar el estado local
      setState(() {
        _descuentoKg = nuevoPesoTara;
      });
      
      _mostrarError('Peso tara actualizado correctamente', isError: false);
    } catch (e) {
      _mostrarError('Error al actualizar el peso tara: $e');
    }
  }
}
  
  final nuevoPesoTara = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Editar peso tara'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Peso vacío de la carretilla que se resta de cada pesada'),
          const SizedBox(height: 8),
          TextField(
            controller: pesoController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Peso tara',
              suffixText: 'kg',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final peso = double.tryParse(pesoController.text.replaceAll(',', '.'));
            if (peso != null && peso >= 0) {
              Navigator.pop(context, peso);
            } else {
              _mostrarError('Ingresa un peso válido');
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );

  if (nuevoPesoTara != null && nuevoPesoTara != widget.descuentoKg) {
    // Actualizar el descuento en la base de datos
    try {
      await _db.updateCargaDescuento(widget.cargaId, nuevoPesoTara);
      
      // Actualizar el widget
      setState(() {
        // Como widget.descuentoKg es final, necesitamos usar un workaround
        // Usamos un setState para forzar el rebuild con el nuevo valor
      });
      
      // Recargar la carga para obtener el nuevo descuento
      
      
      // Opción más simple: recargar la pantalla con los nuevos datos
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegistroCarretillasScreen(
              cargaId: widget.cargaId,
              comercianteNombre: widget.comercianteNombre,
              descuentoKg: nuevoPesoTara,
            ),
          ),
        );
      }
      
      _mostrarError('Peso tara actualizado correctamente', isError: false);
    } catch (e) {
      _mostrarError('Error al actualizar el peso tara: $e');
    }
  }
}

  Future<void> _agregarCarretilla() async {
    final peso = double.tryParse(_pesoController.text.replaceAll(',', '.'));
    if (peso == null || peso <= 0) {
      _mostrarError('Ingresa un peso válido');
      return;
    }

    final nuevaCarretilla = Carretilla(
      cargaId: widget.cargaId,
      numero: _totalCarretillas + 1,
      peso: peso,
    );

    await _db.insertCarretilla(nuevaCarretilla);
    setState(() {
      _tieneDatosIngresados = true;
    });
    _pesoController.clear();
    await _cargarCarretillas();
    _pesoFocus.requestFocus();
  }

  Future<void> _eliminarCarretilla(Carretilla c) async {
    await _db.deleteCarretilla(c.id!);
    await _cargarCarretillas();
  }

  Future<void> _editarPesoCarretilla(Carretilla carretilla) async {
    final pesoController = TextEditingController(text: carretilla.peso.toString());
    
    final nuevoPeso = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar peso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Carretilla #${carretilla.numero}'),
            const SizedBox(height: 8),
            TextField(
              controller: pesoController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Nuevo peso',
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final peso = double.tryParse(pesoController.text.replaceAll(',', '.'));
              if (peso != null && peso > 0) {
                Navigator.pop(context, peso);
              } else {
                _mostrarError('Ingresa un peso válido');
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoPeso != null && nuevoPeso != carretilla.peso) {
      await _db.updateCarretilla(Carretilla(
        id: carretilla.id,
        cargaId: carretilla.cargaId,
        numero: carretilla.numero,
        peso: nuevoPeso,
      ));
      await _cargarCarretillas();
      _mostrarError('Peso actualizado correctamente', isError: false);
    }
  }

  void _mostrarError(String mensaje, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_tieneDatosIngresados) {
      return true;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la carga?'),
        content: const Text(
          'Hay carretillas registradas. ¿Estás seguro de que quieres salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir registrando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    return confirmar ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registro de carretillas'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // CONTENEDOR SUPERIOR REDISEÑADO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        // Izquierda: Comerciante
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Comerciante:', style: TextStyle(color: Colors.grey.shade600)),
                              Text(widget.comercianteNombre,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        // Derecha: Icono de carretilla + peso total
                        // En el contenedor superior, reemplaza el Container con esto:

// En el contenedor superior, reemplaza el Container con esto:

Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.wheelchair_pickup, color: Colors.orange),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Peso tara (carretilla)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          // HAZ CLIC AQUÍ PARA EDITAR EL PESO TARA
          GestureDetector(
            onTap: _editarPesoTara,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.descuentoKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Carretilla #${_totalCarretillas + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pesoController,
                            focusNode: _pesoFocus,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                            ],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _agregarCarretilla(),
                            decoration: const InputDecoration(
                              labelText: 'Peso',
                              suffixText: 'kg',
                            ),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 110,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _agregarCarretilla,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 56),
                            ),
                            child: const Text('Agregar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Expanded(
                    child: _carretillas.isEmpty
                        ? Center(
                            child: Text('Aún no hay carretillas registradas',
                                style: TextStyle(color: Colors.grey.shade500)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _carretillas.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final c = _carretillas[_carretillas.length - 1 - index];
                              return ListTile(
                                leading: CircleAvatar(child: Text('${c.numero}')),
                                title: Text('${c.peso.toStringAsFixed(1)} kg'),
                                subtitle: widget.descuentoKg > 0
                                    ? Text(
                                        'Neto: ${(c.peso - widget.descuentoKg).toStringAsFixed(1)} kg '
                                        '(− ${widget.descuentoKg.toStringAsFixed(1)} kg tara)',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      )
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editarPesoCarretilla(c),
                                      tooltip: 'Editar peso',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _eliminarCarretilla(c),
                                      tooltip: 'Eliminar carretilla',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total peso', style: TextStyle(fontSize: 16)),
                            Text('${_totalPesoNeto.toStringAsFixed(1)} kg',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (widget.descuentoKg > 0) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Peso bruto (sin descuento)',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              Text('${_totalPesoBruto.toStringAsFixed(1)} kg',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total carretillas', style: TextStyle(fontSize: 16)),
                            Text('$_totalCarretillas',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _carretillas.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FinalizarCargaScreen(cargaId: widget.cargaId),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Finalizar carga'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF6C00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}