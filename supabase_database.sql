-- ============================================
-- TOLEDO PRÉSTAMOS - BD ACTUALIZADA COMPLETA
-- Versión actualizada: 09/11/2025
-- Compatible con tu estructura actual de Supabase
-- ============================================

-- IMPORTANTE: Ejecutar en SQL Editor de Supabase

-- ============================================
-- PASO 1: LIMPIAR DATOS EXISTENTES (OPCIONAL)
-- ============================================
-- Si quieres empezar desde cero, descomenta estas líneas:
-- TRUNCATE TABLE abonos CASCADE;
-- TRUNCATE TABLE movimientos CASCADE;
-- TRUNCATE TABLE clientes CASCADE;

-- ============================================
-- PASO 2: INSERTAR CLIENTES DE PRUEBA
-- ============================================

-- Resetear secuencia para empezar desde 1
SELECT setval('clientes_id_cliente_seq', 1, false);

INSERT INTO clientes (nombre, apellido_paterno, apellido_materno, telefono, email, activo) VALUES
('Rosa Carolina', 'Avalos', 'Dominguez', '5551234567', 'rosa.avalos@test.com', TRUE),
('Jesus Rafael', 'Avalos', 'Dominguez', '5559876543', 'jesus.avalos@test.com', TRUE),
('Luis Fernando', 'Castillo', 'Hernandez', '5551112222', 'luis.castillo@test.com', TRUE),
('Diana', 'Avalos', 'Dominguez', '5553334444', 'diana.avalos@test.com', TRUE),
('Edith', 'Zamarripa', NULL, '5555556666', 'edith.zamarripa@test.com', TRUE),
('Luz Irene', 'Medina', 'Cortes', '5557778888', 'luz.medina@test.com', TRUE),
('Yoselin', 'Macias', 'Hernandez', '5559990000', 'yoselin.macias@test.com', TRUE),
('Maria Isabel', 'Cruz', NULL, '5552223333', 'maria.cruz@test.com', TRUE),
('Delia', 'Cortez', NULL, '5554445555', 'delia.cortez@test.com', TRUE),
('Gaby', 'Santiago', NULL, '5556667777', 'gaby.santiago@test.com', TRUE)
ON CONFLICT (id_cliente) DO NOTHING;

-- ============================================
-- PASO 3: INSERTAR MOVIMIENTOS (PRÉSTAMOS)
-- ============================================

-- Resetear secuencia
SELECT setval('movimientos_id_seq', 1, false);

INSERT INTO movimientos (id_cliente, monto, interes, fecha_inicio, fecha_pago, estado_pagado, eliminado, abonos) VALUES
-- Préstamos de Rosa Carolina Avalos Dominguez (id_cliente: 1)
(1, 1000.00, 2620.00, '2025-07-02', '2026-05-16', FALSE, FALSE, 20.00),
(1, 250.00, 20.00, '2025-07-06', '2025-07-15', TRUE, FALSE, 0.00),
(1, 150.00, 20.00, '2025-07-12', '2025-07-15', TRUE, FALSE, 0.00),
(1, 50.00, 10.00, '2025-07-14', '2025-07-15', TRUE, FALSE, 0.00),
(1, 500.00, 50.00, '2025-07-17', '2025-08-15', TRUE, FALSE, 0.00),
(1, 300.00, 15.00, '2025-07-18', '2025-07-30', TRUE, FALSE, 0.00),
(1, 800.00, 400.00, '2025-07-19', '2026-05-16', FALSE, FALSE, 0.00),
(1, 1200.00, 330.00, '2025-07-25', '2026-05-16', FALSE, FALSE, 0.00),
(1, 100.00, 3.00, '2025-07-29', '2025-07-30', TRUE, FALSE, 0.00),
(1, 500.00, 100.00, '2025-08-16', '2026-05-16', FALSE, FALSE, 0.00),
(1, 1000.00, 250.00, '2025-08-16', '2026-05-16', FALSE, FALSE, 0.00),
(1, 250.00, 50.00, '2025-08-26', '2026-05-16', FALSE, FALSE, 0.00),
(1, 500.00, 25.00, '2025-09-01', '2025-09-30', TRUE, FALSE, 0.00),
(1, 500.00, 25.00, '2025-09-06', '2025-09-15', TRUE, FALSE, 0.00),
(1, 100.00, 2.00, '2025-09-23', '2025-09-30', TRUE, FALSE, 0.00),
(1, 500.00, 25.00, '2025-09-24', '2025-09-30', TRUE, FALSE, 0.00),
(1, 250.00, 12.50, '2025-09-26', '2025-09-30', TRUE, FALSE, 0.00),
(1, 1500.00, 75.00, '2025-09-28', '2026-05-16', FALSE, FALSE, 75.00),
(1, 200.00, 20.00, '2025-10-09', '2025-10-15', TRUE, FALSE, 0.00),
(1, 1500.00, 0.00, '2025-10-23', '2025-10-30', TRUE, FALSE, 0.00),
(1, 500.00, 50.00, '2025-10-26', '2025-11-15', FALSE, FALSE, 50.00),
(1, 300.00, 30.00, '2025-11-03', '2025-11-15', FALSE, FALSE, 0.00),

-- Préstamos de Jesus Rafael Avalos Dominguez (id_cliente: 2)
(2, 1000.00, 500.00, '2025-07-10', '2025-12-10', FALSE, FALSE, 0.00),

-- Préstamos de Luis Fernando Castillo Hernandez (id_cliente: 3)
(3, 2000.00, 500.00, '2025-07-19', '2025-11-04', FALSE, FALSE, 0.00),

-- Préstamos de Diana Avalos Dominguez (id_cliente: 4)
(4, 1100.00, 550.00, '2025-07-19', '2025-12-19', FALSE, FALSE, 0.00),

-- Préstamos de Edith Zamarripa (id_cliente: 5)
(5, 1000.00, 400.00, '2025-08-03', '2025-11-16', FALSE, FALSE, 0.00),
(5, 1200.00, 60.00, '2025-09-17', '2025-09-30', TRUE, FALSE, 0.00),
(5, 1000.00, 50.00, '2025-10-02', '2025-10-15', TRUE, FALSE, 0.00),

-- Préstamos de Luz Irene Medina Cortes (id_cliente: 6)
(6, 400.00, 20.00, '2025-09-08', '2025-10-30', TRUE, FALSE, 0.00),

-- Préstamos de Yoselin Macias Hernandez (id_cliente: 7)
(7, 120.00, 0.00, '2025-09-28', '2025-10-04', TRUE, FALSE, 0.00),
(7, 129.00, 0.00, '2025-10-05', '2025-10-31', TRUE, FALSE, 0.00),

-- Préstamos de Maria Isabel Cruz (id_cliente: 8)
(8, 2200.00, 100.00, '2025-10-07', '2025-10-17', TRUE, FALSE, 2300.00),

-- Préstamos de Delia Cortez (id_cliente: 9)
(9, 300.00, 50.00, '2025-10-09', '2025-10-15', TRUE, FALSE, 0.00),
(9, 2000.00, 200.00, '2025-10-29', '2025-11-30', FALSE, FALSE, 0.00),

-- Préstamos de Gaby Santiago (id_cliente: 10)
(10, 1300.00, 100.00, '2025-10-12', '2025-10-30', TRUE, FALSE, 0.00)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- PASO 4: INSERTAR ALGUNOS ABONOS DE EJEMPLO
-- ============================================

INSERT INTO abonos (id_movimiento, monto_abono, metodo_pago, notas) VALUES
-- Abonos al préstamo 1 (Rosa Carolina - $1000 + $2620 interés)
(1, 20.00, 'efectivo', 'Primer abono'),

-- Abonos al préstamo 18 (Rosa Carolina - $1500 + $75 interés)
(18, 75.00, 'transferencia', 'Abono parcial'),

-- Abonos al préstamo 21 (Rosa Carolina - $500 + $50 interés)
(21, 50.00, 'efectivo', 'Abono inicial'),

-- Abonos al préstamo 28 (Maria Isabel - $2200 + $100 interés = $2300 total)
(28, 1000.00, 'transferencia', 'Primer abono'),
(28, 1300.00, 'efectivo', 'Liquidación total')
ON CONFLICT DO NOTHING;

-- ============================================
-- PASO 5: ACTUALIZAR SECUENCIAS
-- ============================================

-- Ajustar secuencias a los últimos IDs insertados
SELECT setval('clientes_id_cliente_seq', (SELECT MAX(id_cliente) FROM clientes), true);
SELECT setval('movimientos_id_seq', (SELECT MAX(id) FROM movimientos), true);
SELECT setval('abonos_id_seq', (SELECT MAX(id) FROM abonos), true);

-- ============================================
-- PASO 6: VERIFICAR DATOS INSERTADOS
-- ============================================

-- Ver resumen de clientes
SELECT 
    id_cliente,
    nombre_completo,
    telefono,
    email,
    activo
FROM clientes
ORDER BY id_cliente;

-- Ver resumen de movimientos
SELECT 
    m.id,
    m.id_cliente,
    c.nombre_completo as cliente,
    m.monto,
    m.interes,
    m.abonos,
    m.saldo_pendiente,
    m.fecha_inicio,
    m.fecha_pago,
    m.estado_pagado
FROM movimientos m
JOIN clientes c ON m.id_cliente = c.id_cliente
ORDER BY m.id;

-- Ver estadísticas generales
SELECT 
    COUNT(DISTINCT c.id_cliente) as total_clientes,
    COUNT(m.id) as total_movimientos,
    COUNT(CASE WHEN m.estado_pagado = FALSE AND m.eliminado = FALSE THEN 1 END) as prestamos_activos,
    COUNT(CASE WHEN m.estado_pagado = TRUE THEN 1 END) as prestamos_pagados,
    COALESCE(SUM(CASE WHEN m.estado_pagado = FALSE AND m.eliminado = FALSE THEN m.saldo_pendiente END), 0) as capital_circulacion,
    COALESCE(SUM(CASE WHEN m.estado_pagado = TRUE THEN m.monto + m.interes END), 0) as capital_recuperado
FROM clientes c
LEFT JOIN movimientos m ON c.id_cliente = m.id_cliente;

-- ============================================
-- PASO 7: CONFIGURAR PERMISOS (SI AÚN NO LO HICISTE)
-- ============================================

-- Dar permisos completos a usuarios autenticados
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Dar permisos a rol anon
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Permisos explícitos en cada tabla
GRANT ALL ON clientes TO authenticated, anon;
GRANT ALL ON movimientos TO authenticated, anon;
GRANT ALL ON abonos TO authenticated, anon;
GRANT ALL ON perfiles TO authenticated, anon;

-- Sequences
GRANT USAGE, SELECT ON SEQUENCE clientes_id_cliente_seq TO authenticated, anon;
GRANT USAGE, SELECT ON SEQUENCE movimientos_id_seq TO authenticated, anon;
GRANT USAGE, SELECT ON SEQUENCE abonos_id_seq TO authenticated, anon;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================

DO $$
DECLARE
    total_clientes INTEGER;
    total_movimientos INTEGER;
    prestamos_activos INTEGER;
    prestamos_pagados INTEGER;
    capital_circulacion NUMERIC;
BEGIN
    SELECT COUNT(*) INTO total_clientes FROM clientes;
    SELECT COUNT(*) INTO total_movimientos FROM movimientos;
    SELECT COUNT(*) INTO prestamos_activos FROM movimientos WHERE estado_pagado = FALSE AND eliminado = FALSE;
    SELECT COUNT(*) INTO prestamos_pagados FROM movimientos WHERE estado_pagado = TRUE;
    SELECT COALESCE(SUM(saldo_pendiente), 0) INTO capital_circulacion FROM movimientos WHERE estado_pagado = FALSE AND eliminado = FALSE;
    
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║        TOLEDO PRÉSTAMOS - DATOS INSERTADOS            ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Datos insertados exitosamente';
    RAISE NOTICE '';
    RAISE NOTICE '📊 ESTADÍSTICAS:';
    RAISE NOTICE '   • Clientes: %', total_clientes;
    RAISE NOTICE '   • Total movimientos: %', total_movimientos;
    RAISE NOTICE '   • Préstamos activos: %', prestamos_activos;
    RAISE NOTICE '   • Préstamos pagados: %', prestamos_pagados;
    RAISE NOTICE '   • Capital en circulación: $%', capital_circulacion;
    RAISE NOTICE '';
    RAISE NOTICE '🚀 SIGUIENTE PASO:';
    RAISE NOTICE '   Recarga la app Flutter para ver los datos';
    RAISE NOTICE '';
    RAISE NOTICE '════════════════════════════════════════════════════════';
END $$;

-- ============================================
-- QUERIES ÚTILES PARA VERIFICAR
-- ============================================

-- Ver préstamos activos con información del cliente
/*
SELECT 
    m.id,
    c.nombre_completo as cliente,
    m.monto,
    m.interes,
    m.saldo_pendiente,
    m.fecha_inicio,
    m.fecha_pago,
    (m.fecha_pago - CURRENT_DATE) as dias_restantes
FROM movimientos m
JOIN clientes c ON m.id_cliente = c.id_cliente
WHERE m.estado_pagado = FALSE 
AND m.eliminado = FALSE
ORDER BY m.fecha_pago;
*/

-- Ver deuda total por cliente
/*
SELECT 
    c.id_cliente,
    c.nombre_completo,
    COUNT(m.id) as total_prestamos,
    COUNT(CASE WHEN m.estado_pagado = FALSE AND m.eliminado = FALSE THEN 1 END) as prestamos_activos,
    COALESCE(SUM(CASE WHEN m.estado_pagado = FALSE AND m.eliminado = FALSE THEN m.saldo_pendiente END), 0) as deuda_total
FROM clientes c
LEFT JOIN movimientos m ON c.id_cliente = m.id_cliente
GROUP BY c.id_cliente, c.nombre_completo
ORDER BY deuda_total DESC;
*/

-- Ver historial de abonos
/*
SELECT 
    a.id,
    c.nombre_completo as cliente,
    m.monto as monto_prestamo,
    a.monto_abono,
    a.metodo_pago,
    a.fecha_abono,
    a.notas
FROM abonos a
JOIN movimientos m ON a.id_movimiento = m.id
JOIN clientes c ON m.id_cliente = c.id_cliente
ORDER BY a.fecha_abono DESC;
*/
