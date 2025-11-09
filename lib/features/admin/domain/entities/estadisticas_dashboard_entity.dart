class EstadisticasDashboardEntity {
  final int totalClientes;
  final int clientesActivos;
  final int totalPrestamos;
  final int prestamosActivos;
  final int prestamosPagados;
  final int prestamosVencidos;
  final double capitalCirculacion;
  final double interesesGanados;
  final double capitalVencido;

  const EstadisticasDashboardEntity({
    required this.totalClientes,
    required this.clientesActivos,
    required this.totalPrestamos,
    required this.prestamosActivos,
    required this.prestamosPagados,
    required this.prestamosVencidos,
    required this.capitalCirculacion,
    required this.interesesGanados,
    required this.capitalVencido,
  });

  /// Capital Total = Capital en circulación + Capital vencido
  double get capitalTotal => capitalCirculacion + capitalVencido;

  /// Capital Trabajando = Préstamos activos (monto - abonos)
  double get capitalTrabajando => capitalCirculacion;

  /// Capital Liberado = Préstamos pagados + abonos hechos
  double get capitalLiberado {
    // Se calcula como el total menos lo que está en circulación
    return 0; // TODO: Calcular desde abonos
  }

  /// Ganancia = Intereses cobrados
  double get ganancia => interesesGanados;

  /// Porcentajes para gráficas
  double get porcentajeCapitalTotal => 100.0;
  
  double get porcentajeCapitalTrabajando {
    if (capitalTotal == 0) return 0;
    return (capitalTrabajando / capitalTotal) * 100;
  }

  double get porcentajeCapitalLiberado {
    if (capitalTotal == 0) return 0;
    return (capitalLiberado / capitalTotal) * 100;
  }

  double get porcentajeGanancia {
    if (capitalTotal == 0) return 0;
    return (ganancia / capitalTotal) * 100;
  }
}
