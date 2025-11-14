-- Nota este si sirvio
-- 1. Limpiar TODOS los datos de prueba
DELETE FROM abonos WHERE id_movimiento IN (SELECT id FROM movimientos WHERE id > 35);
DELETE FROM movimientos WHERE id > 35;
DELETE FROM clientes WHERE id_cliente > 10;

-- 2. Verificar que no quede nada
SELECT 'Clientes MAX:' as info, MAX(id_cliente) as valor FROM clientes
UNION ALL
SELECT 'Movimientos MAX:', MAX(id) FROM movimientos;

-- 3. FORZAR secuencias directamente
ALTER SEQUENCE clientes_id_cliente_seq RESTART WITH 11;
ALTER SEQUENCE movimientos_id_seq RESTART WITH 36;

-- 4. Verificar secuencias
SELECT 'clientes_id_cliente_seq' as secuencia, last_value FROM clientes_id_cliente_seq
UNION ALL
SELECT 'movimientos_id_seq', last_value FROM movimientos_id_seq;