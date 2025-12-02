class DatabaseSnapshotData {
  final List<Map<String, dynamic>> perfiles;
  final List<Map<String, dynamic>> clientes;
  final List<Map<String, dynamic>> movimientos;
  final List<Map<String, dynamic>> abonos;

  const DatabaseSnapshotData({
    this.perfiles = const [],
    this.clientes = const [],
    this.movimientos = const [],
    this.abonos = const [],
  });

  bool get isEmpty =>
      perfiles.isEmpty && clientes.isEmpty && movimientos.isEmpty && abonos.isEmpty;

  bool get hasAnyData => !isEmpty;

  DatabaseSnapshotData copyWith({
    List<Map<String, dynamic>>? perfiles,
    List<Map<String, dynamic>>? clientes,
    List<Map<String, dynamic>>? movimientos,
    List<Map<String, dynamic>>? abonos,
  }) {
    return DatabaseSnapshotData(
      perfiles: perfiles ?? this.perfiles,
      clientes: clientes ?? this.clientes,
      movimientos: movimientos ?? this.movimientos,
      abonos: abonos ?? this.abonos,
    );
  }
}

class AppDataCache {
  AppDataCache._internal();
  static final AppDataCache _instance = AppDataCache._internal();
  factory AppDataCache() => _instance;

  final Map<String, Map<String, dynamic>> _perfiles = {};
  final Map<int, Map<String, dynamic>> _clientes = {};
  final Map<int, Map<String, dynamic>> _movimientosActivos = {};
  final List<Map<String, dynamic>> _movimientosEliminados = [];
  final Map<int, Map<String, dynamic>> _abonos = {};

  void cachePerfiles(Iterable<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final id = row['id'] ?? row['usuario_id'];
      if (id is String) {
        _perfiles[id] = Map<String, dynamic>.from(row);
      }
    }
  }

  void cachePerfil(Map<String, dynamic> row) {
    cachePerfiles([row]);
  }

  void cacheClientes(Iterable<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final id = row['id_cliente'] ?? row['id'];
      if (id is int) {
        _clientes[id] = Map<String, dynamic>.from(row);
      }
    }
  }

  void cacheCliente(Map<String, dynamic> row) {
    cacheClientes([row]);
  }

  void cacheMovimientos(Iterable<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final id = row['id'];
      if (id is! int) {
        continue;
      }

      final sanitized = Map<String, dynamic>.from(row)
        ..remove('nombre_cliente');

      sanitized['eliminado'] = sanitized['eliminado'] == true;
      final eliminado = sanitized['eliminado'] == true;

      if (eliminado) {
        _storeEliminadoSnapshot(sanitized);
        _movimientosActivos.remove(id);
      } else {
        _movimientosActivos[id] = sanitized;
      }
    }
  }

  void cacheMovimiento(Map<String, dynamic> row) {
    cacheMovimientos([row]);
  }

  void cacheAbonos(Iterable<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final id = row['id'];
      if (id is int) {
        _abonos[id] = Map<String, dynamic>.from(row);
      }
    }
  }

  void cacheAbono(Map<String, dynamic> row) {
    cacheAbonos([row]);
  }

  void removeMovimiento(
    int id, {
    bool keepHistory = false,
    String? motivo,
  }) {
    final removed = _movimientosActivos.remove(id);

    if (!keepHistory) {
      return;
    }

    if (removed != null) {
      final snapshot = Map<String, dynamic>.from(removed)
        ..['eliminado'] = true;

      if (motivo != null && motivo.isNotEmpty) {
        snapshot['motivo_eliminacion'] = motivo;
      } else if (!snapshot.containsKey('motivo_eliminacion')) {
        snapshot['motivo_eliminacion'] = 'Sin motivo registrado';
      }

      _storeEliminadoSnapshot(snapshot);
    }
  }

  void removeAbono(int id) => _abonos.remove(id);

  void removeCliente(int id) => _clientes.remove(id);

  bool get hasClientes => _clientes.isNotEmpty;
  bool get hasMovimientos =>
      _movimientosActivos.isNotEmpty || _movimientosEliminados.isNotEmpty;
  bool get hasAbonos => _abonos.isNotEmpty;
  bool get hasPerfiles => _perfiles.isNotEmpty;

  void clear() {
    _perfiles.clear();
    _clientes.clear();
    _movimientosActivos.clear();
    _movimientosEliminados.clear();
    _abonos.clear();
  }

  DatabaseSnapshotData toSnapshot() {
    return DatabaseSnapshotData(
      perfiles: _sortedValues(_perfiles),
      clientes: _sortedValues(_clientes),
      movimientos: _collectMovimientosSnapshot(),
      abonos: _sortedValues(_abonos),
    );
  }

  List<Map<String, dynamic>> _sortedValues<K>(Map<K, Map<String, dynamic>> source) {
    final entries = source.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    return entries.map((entry) => Map<String, dynamic>.from(entry.value)).toList();
  }

  List<Map<String, dynamic>> _collectMovimientosSnapshot() {
    final activos = _sortedValues(_movimientosActivos);

    if (_movimientosEliminados.isEmpty) {
      return activos;
    }

    final eliminados = _movimientosEliminados
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
      ..sort((a, b) {
        final idA = a['id'];
        final idB = b['id'];
        if (idA is int && idB is int && idA != idB) {
          return idA.compareTo(idB);
        }

        final updatedA = a['actualizado']?.toString() ?? '';
        final updatedB = b['actualizado']?.toString() ?? '';
        return updatedA.compareTo(updatedB);
      });

    return [...activos, ...eliminados];
  }

  void mergeSnapshot(DatabaseSnapshotData snapshot) {
    cachePerfiles(snapshot.perfiles);
    cacheClientes(snapshot.clientes);
    cacheMovimientos(snapshot.movimientos);
    cacheAbonos(snapshot.abonos);
  }

  bool get isEmpty =>
      _perfiles.isEmpty &&
      _clientes.isEmpty &&
      _movimientosActivos.isEmpty &&
      _movimientosEliminados.isEmpty &&
      _abonos.isEmpty;

  void _storeEliminadoSnapshot(Map<String, dynamic> row) {
    final clone = Map<String, dynamic>.from(row);
    final signature = _movementSignature(clone);
    final alreadyStored = _movimientosEliminados.any(
      (existing) => _movementSignature(existing) == signature,
    );

    if (!alreadyStored) {
      _movimientosEliminados.add(clone);
    }
  }

  String _movementSignature(Map<String, dynamic> row) {
    final keys = row.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in keys) {
      buffer.write('$key=${row[key]};');
    }
    return buffer.toString();
  }
}
