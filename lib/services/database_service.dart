import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/carga.dart';
import '../models/carretilla.dart';
import '../models/comerciante.dart';

/// Servicio singleton que maneja toda la persistencia local.
/// Todo se guarda en SQLite en el celular, por lo que la app funciona
/// perfectamente sin conexión a internet. Los campos "sincronizada"
/// quedan listos para cuando se conecte con el servidor.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'papayas_app.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE comerciantes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            telefono TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE cargas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            comerciante_id INTEGER NOT NULL,
            precio_kg REAL NOT NULL,
            descuento_kg REAL NOT NULL DEFAULT 0,
            fecha TEXT NOT NULL,
            finalizada INTEGER NOT NULL DEFAULT 0,
            sincronizada INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (comerciante_id) REFERENCES comerciantes (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE carretillas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            carga_id INTEGER NOT NULL,
            numero INTEGER NOT NULL,
            peso REAL NOT NULL,
            FOREIGN KEY (carga_id) REFERENCES cargas (id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Las cargas creadas antes de este cambio quedan con descuento 0 (sin afectar sus totales).
          await db.execute('ALTER TABLE cargas ADD COLUMN descuento_kg REAL NOT NULL DEFAULT 0');
        }
      },
    );
  }

  // ---------------- COMERCIANTES ----------------

  Future<int> insertComerciante(Comerciante c) async {
    final db = await database;
    return db.insert('comerciantes', c.toMap()..remove('id'));
  }

  Future<List<Comerciante>> getComerciantes() async {
    final db = await database;
    final maps = await db.query('comerciantes', orderBy: 'nombre ASC');
    return maps.map((m) => Comerciante.fromMap(m)).toList();
  }

  Future<void> updateComerciante(Comerciante c) async {
    final db = await database;
    await db.update('comerciantes', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteComerciante(int id) async {
    final db = await database;
    await db.delete('comerciantes', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- CARGAS ----------------

  Future<int> insertCarga(Carga carga) async {
    final db = await database;
    return db.insert('cargas', carga.toMap()..remove('id'));
  }

  Future<Carga> getCargaById(int id) async {
    final db = await database;
    final maps = await db.query('cargas', where: 'id = ?', whereArgs: [id]);
    return Carga.fromMap(maps.first);
  }


  

  Future<void> finalizarCarga(int id) async {
    final db = await database;
    await db.update('cargas', {'finalizada': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> marcarSincronizada(int id) async {
    final db = await database;
    await db.update('cargas', {'sincronizada': 1}, where: 'id = ?', whereArgs: [id]);
  }

  /// Historial: cargas finalizadas con nombre del comerciante y totales ya calculados.
  Future<List<CargaResumen>> getHistorial() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        cargas.*,
        comerciantes.nombre AS comerciante_nombre,
        COALESCE(SUM(carretillas.peso), 0) AS peso_bruto_total,
        COUNT(carretillas.id) AS total_carretillas
      FROM cargas
      JOIN comerciantes ON comerciantes.id = cargas.comerciante_id
      LEFT JOIN carretillas ON carretillas.carga_id = cargas.id
      WHERE cargas.finalizada = 1
      GROUP BY cargas.id
      ORDER BY cargas.fecha DESC
    ''');

    return rows.map((row) {
      final carga = Carga.fromMap(row);
      final pesoBruto = (row['peso_bruto_total'] as num).toDouble();
      final totalCarretillas = row['total_carretillas'] as int;
      final pesoNeto = pesoBruto - (carga.descuentoKg * totalCarretillas);
      return CargaResumen(
        carga: carga,
        comercianteNombre: row['comerciante_nombre'] as String,
        pesoBrutoTotal: pesoBruto,
        pesoTotal: pesoNeto < 0 ? 0 : pesoNeto,
        totalCarretillas: totalCarretillas,
      );
    }).toList();
  }

  Future<CargaResumen> getResumenCarga(int cargaId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        cargas.*,
        comerciantes.nombre AS comerciante_nombre,
        COALESCE(SUM(carretillas.peso), 0) AS peso_bruto_total,
        COUNT(carretillas.id) AS total_carretillas
      FROM cargas
      JOIN comerciantes ON comerciantes.id = cargas.comerciante_id
      LEFT JOIN carretillas ON carretillas.carga_id = cargas.id
      WHERE cargas.id = ?
      GROUP BY cargas.id
    ''', [cargaId]);

    final row = rows.first;
    final carga = Carga.fromMap(row);
    final pesoBruto = (row['peso_bruto_total'] as num).toDouble();
    final totalCarretillas = row['total_carretillas'] as int;
    final pesoNeto = pesoBruto - (carga.descuentoKg * totalCarretillas);
    return CargaResumen(
      carga: carga,
      comercianteNombre: row['comerciante_nombre'] as String,
      pesoBrutoTotal: pesoBruto,
      pesoTotal: pesoNeto < 0 ? 0 : pesoNeto,
      totalCarretillas: totalCarretillas,
    );
  }


Future<void> updateCarretilla(Carretilla carretilla) async {
  final db = await database;
  await db.update(
    'carretillas',
    {
      'carga_id': carretilla.cargaId,
      'numero': carretilla.numero,
      'peso': carretilla.peso,
    },
    where: 'id = ?',
    whereArgs: [carretilla.id],
  );
}

// En database_service.dart
Future<void> updateCargaDescuento(int cargaId, double nuevoDescuento) async {
  final db = await database;
  await db.update(
    'cargas',
    {'descuento_kg': nuevoDescuento},
    where: 'id = ?',
    whereArgs: [cargaId],
  );
}

  // ---------------- CARRETILLAS ----------------

  Future<int> insertCarretilla(Carretilla carretilla) async {
    final db = await database;
    return db.insert('carretillas', carretilla.toMap()..remove('id'));
  }

  Future<List<Carretilla>> getCarretillasByCarga(int cargaId) async {
    final db = await database;
    final maps = await db.query(
      'carretillas',
      where: 'carga_id = ?',
      whereArgs: [cargaId],
      orderBy: 'numero ASC',
    );
    return maps.map((m) => Carretilla.fromMap(m)).toList();
  }

  Future<void> deleteCarretilla(int id) async {
    final db = await database;
    await db.delete('carretillas', where: 'id = ?', whereArgs: [id]);
  }
}