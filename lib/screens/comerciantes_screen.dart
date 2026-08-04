import 'package:flutter/material.dart';

import '../models/comerciante.dart';
import '../services/database_service.dart';

class ComerciantesScreen extends StatefulWidget {
  const ComerciantesScreen({super.key});

  @override
  State<ComerciantesScreen> createState() => _ComerciantesScreenState();
}

class _ComerciantesScreenState extends State<ComerciantesScreen> {
  final _db = DatabaseService.instance;
  List<Comerciante> _comerciantes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await _db.getComerciantes();
    setState(() {
      _comerciantes = lista;
      _cargando = false;
    });
  }

  Future<void> _mostrarFormulario({Comerciante? existente}) async {
    final nombreController = TextEditingController(text: existente?.nombre ?? '');
    final telefonoController = TextEditingController(text: existente?.telefono ?? '');

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existente == null ? 'Nuevo comerciante' : 'Editar comerciante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefonoController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (guardar == true && nombreController.text.trim().isNotEmpty) {
      if (existente == null) {
        await _db.insertComerciante(Comerciante(
          nombre: nombreController.text.trim(),
          telefono: telefonoController.text.trim().isEmpty ? null : telefonoController.text.trim(),
        ));
      } else {
        await _db.updateComerciante(existente.copyWith(
          nombre: nombreController.text.trim(),
          telefono: telefonoController.text.trim(),
        ));
      }
      await _cargar();
    }
  }

  Future<void> _eliminar(Comerciante c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comerciante'),
        content: Text('¿Eliminar a ${c.nombre}? Esto no borra sus cargas anteriores.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _db.deleteComerciante(c.id!);
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comerciantes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _comerciantes.isEmpty
              ? Center(
                  child: Text('No hay comerciantes registrados',
                      style: TextStyle(color: Colors.grey.shade500)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _comerciantes.length,
                  itemBuilder: (context, index) {
                    final c = _comerciantes[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                        title: Text(c.nombre),
                        subtitle: c.telefono != null && c.telefono!.isNotEmpty
                            ? Text(c.telefono!)
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _mostrarFormulario(existente: c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _eliminar(c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
