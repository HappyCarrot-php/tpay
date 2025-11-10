-- =====================================================
-- PASO 1: VERIFICAR SI LAS COLUMNAS YA EXISTEN
-- =====================================================

-- Ver TODAS las columnas de clientes (puede haber más de las que ves en pantalla)
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'clientes'
ORDER BY ordinal_position;

-- Contar cuántas columnas tiene la tabla
SELECT COUNT(*) as total_columnas 
FROM information_schema.columns 
WHERE table_name = 'clientes';

-- =====================================================
-- RESULTADO:
-- Si ves más de 10 columnas, probablemente ya existen
-- Si solo ves 5-6 columnas, necesitas ejecutar AGREGAR_COLUMNAS_FALTANTES.sql
-- =====================================================

-- Buscar columnas específicas que necesitamos
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'clientes' 
AND column_name IN (
    'nombre', 
    'apellido_paterno', 
    'apellido_materno', 
    'nombre_completo',
    'telefono',
    'email'
);

-- =====================================================
-- Si el query anterior NO devuelve ninguna fila:
-- EJECUTA AGREGAR_COLUMNAS_FALTANTES.sql
-- =====================================================
