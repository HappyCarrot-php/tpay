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
  final Map<int, Map<String, dynamic>> _movimientos = {};
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
      if (id is int) {
        if (row.containsKey('eliminado')) {
          final eliminado = row['eliminado'];
          if (eliminado is bool && eliminado) {
            _movimientos.remove(id);
            continue;
          }
        }
        _movimientos[id] = Map<String, dynamic>.from(row)..remove('nombre_cliente');
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

  void removeMovimiento(int id) => _movimientos.remove(id);

  void removeAbono(int id) => _abonos.remove(id);

  void removeCliente(int id) => _clientes.remove(id);

  bool get hasClientes => _clientes.isNotEmpty;
  bool get hasMovimientos => _movimientos.isNotEmpty;
  bool get hasAbonos => _abonos.isNotEmpty;
  bool get hasPerfiles => _perfiles.isNotEmpty;

  void clear() {
    _perfiles.clear();
    _clientes.clear();
    _movimientos.clear();
    _abonos.clear();
  }

  DatabaseSnapshotData toSnapshot() {
    return DatabaseSnapshotData(
      perfiles: _sortedValues(_perfiles),
      clientes: _sortedValues(_clientes),
      movimientos: _sortedValues(_movimientos),
      abonos: _sortedValues(_abonos),
    );
  }

  List<Map<String, dynamic>> _sortedValues<K>(Map<K, Map<String, dynamic>> source) {
    final entries = source.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    return entries.map((entry) => Map<String, dynamic>.from(entry.value)).toList();
  }

  void mergeSnapshot(DatabaseSnapshotData snapshot) {
    cachePerfiles(snapshot.perfiles);
    cacheClientes(snapshot.clientes);
    cacheMovimientos(snapshot.movimientos);
    cacheAbonos(snapshot.abonos);
  }

  bool get isEmpty =>
      _perfiles.isEmpty && _clientes.isEmpty && _movimientos.isEmpty && _abonos.isEmpty;
}
