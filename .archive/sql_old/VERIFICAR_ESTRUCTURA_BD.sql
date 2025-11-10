-- =====================================================
-- VERIFICAR ESTRUCTURA DE TABLAS EN SUPABASE
-- =====================================================
-- Ejecuta estos comandos en SQL Editor de Supabase
-- para ver la estructura real de tus tablas
-- =====================================================

-- 1. Ver estructura de tabla CLIENTES
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'clientes'
ORDER BY ordinal_position;

-- 2. Ver estructura de tabla MOVIMIENTOS
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'movimientos'
ORDER BY ordinal_position;

-- 3. Ver estructura de tabla ABONOS
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'abonos'
ORDER BY ordinal_position;

-- 4. Ver estructura de tabla PERFILES
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'perfiles'
ORDER BY ordinal_position;

-- =====================================================
-- PRUEBA SIMPLE: Intentar obtener 1 cliente
-- =====================================================
SELECT * FROM clientes LIMIT 1;

-- =====================================================
-- Si el query anterior falla, ejecuta esto para ver qué columnas existen:
-- =====================================================
SELECT * FROM information_schema.columns WHERE table_name = 'clientes';
