-- =====================================================
-- AGREGAR COLUMNAS FALTANTES A TABLA CLIENTES
-- =====================================================
-- Ejecuta este script en SQL Editor de Supabase
-- =====================================================

-- Primero, ver TODAS las columnas actuales (scroll completo)
SELECT column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_name = 'clientes'
ORDER BY ordinal_position;

-- =====================================================
-- Si las columnas NO existen, agrégalas:
-- =====================================================

-- Agregar columnas de nombre
ALTER TABLE clientes 
ADD COLUMN IF NOT EXISTS nombre VARCHAR(100),
ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

-- Agregar columnas de contacto
ALTER TABLE clientes 
ADD COLUMN IF NOT EXISTS telefono VARCHAR(20),
ADD COLUMN IF NOT EXISTS email VARCHAR(255);

-- Agregar columnas de identificación
ALTER TABLE clientes 
ADD COLUMN IF NOT EXISTS rfc VARCHAR(13),
ADD COLUMN IF NOT EXISTS curp VARCHAR(18),
ADD COLUMN IF NOT EXISTS fecha_nacimiento DATE;

-- Agregar columnas de dirección
ALTER TABLE clientes 
ADD COLUMN IF NOT EXISTS direccion TEXT,
ADD COLUMN IF NOT EXISTS ciudad VARCHAR(100),
ADD COLUMN IF NOT EXISTS estado VARCHAR(100),
ADD COLUMN IF NOT EXISTS codigo_postal VARCHAR(10);

-- Agregar columnas de identificación oficial
ALTER TABLE clientes 
ADD COLUMN IF NOT EXISTS identificacion_tipo VARCHAR(50),
ADD COLUMN IF NOT EXISTS identificacion_numero VARCHAR(100);

-- Agregar columnas adicionales
ALTER TABLE clientes 
ADD COLUMN IF NOT EXISTS foto_url TEXT,
ADD COLUMN IF NOT EXISTS notas TEXT;

-- =====================================================
-- IMPORTANTE: Agregar columna GENERATED para nombre_completo
-- =====================================================
ALTER TABLE clientes 
ADD COLUMN IF NOT EXISTS nombre_completo TEXT 
GENERATED ALWAYS AS (
    nombre || ' ' || apellido_paterno || ' ' || COALESCE(apellido_materno, '')
) STORED;

-- =====================================================
-- Establecer valores NOT NULL después de verificar datos
-- =====================================================
-- SOLO ejecuta esto si ya tienes datos y quieres hacer campos obligatorios
-- ALTER TABLE clientes ALTER COLUMN nombre SET NOT NULL;
-- ALTER TABLE clientes ALTER COLUMN apellido_paterno SET NOT NULL;

-- =====================================================
-- VERIFICAR que las columnas se agregaron
-- =====================================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'clientes'
ORDER BY ordinal_position;

-- =====================================================
-- AHORA HACER LO MISMO PARA TABLA MOVIMIENTOS
-- =====================================================

-- Ver columnas actuales de movimientos
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'movimientos'
ORDER BY ordinal_position;

-- Agregar columnas faltantes en movimientos
ALTER TABLE movimientos 
ADD COLUMN IF NOT EXISTS id_cliente INTEGER REFERENCES clientes(id_cliente),
ADD COLUMN IF NOT EXISTS monto NUMERIC(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS interes NUMERIC(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS abonos NUMERIC(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS tasa_interes_porcentaje NUMERIC(5,2);

-- Agregar columnas de fechas
ALTER TABLE movimientos 
ADD COLUMN IF NOT EXISTS fecha_inicio DATE,
ADD COLUMN IF NOT EXISTS fecha_pago DATE,
ADD COLUMN IF NOT EXISTS fecha_pagado TIMESTAMPTZ;

-- Agregar columna GENERATED para saldo_pendiente
ALTER TABLE movimientos 
ADD COLUMN IF NOT EXISTS saldo_pendiente NUMERIC(12,2) 
GENERATED ALWAYS AS ((monto + interes) - abonos) STORED;

-- Agregar columna GENERATED para dias_prestamo
ALTER TABLE movimientos 
ADD COLUMN IF NOT EXISTS dias_prestamo INTEGER 
GENERATED ALWAYS AS (fecha_pago - fecha_inicio) STORED;

-- Agregar columnas de estado
ALTER TABLE movimientos 
ADD COLUMN IF NOT EXISTS estado_pagado BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS eliminado BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS motivo_eliminacion TEXT,
ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(50),
ADD COLUMN IF NOT EXISTS notas TEXT,
ADD COLUMN IF NOT EXISTS usuario_registro UUID REFERENCES auth.users(id);

-- Agregar timestamps si no existen
ALTER TABLE movimientos 
ADD COLUMN IF NOT EXISTS creado TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS actualizado TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- =====================================================
-- VERIFICAR movimientos
-- =====================================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'movimientos'
ORDER BY ordinal_position;

-- =====================================================
-- TABLA ABONOS
-- =====================================================

-- Ver columnas actuales de abonos
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'abonos'
ORDER BY ordinal_position;

-- Agregar columnas faltantes en abonos
ALTER TABLE abonos 
ADD COLUMN IF NOT EXISTS id_movimiento INTEGER REFERENCES movimientos(id),
ADD COLUMN IF NOT EXISTS monto_abono NUMERIC(12,2) NOT NULL,
ADD COLUMN IF NOT EXISTS fecha_abono TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(50),
ADD COLUMN IF NOT EXISTS notas TEXT;

-- Agregar timestamps
ALTER TABLE abonos 
ADD COLUMN IF NOT EXISTS creado TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- =====================================================
-- VERIFICAR abonos
-- =====================================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'abonos'
ORDER BY ordinal_position;

-- =====================================================
-- RESULTADO ESPERADO:
-- =====================================================
-- Después de ejecutar este script:
-- 1. Tabla clientes tendrá: nombre, apellido_paterno, apellido_materno, nombre_completo (GENERATED)
-- 2. Tabla movimientos tendrá: saldo_pendiente (GENERATED), dias_prestamo (GENERATED)
-- 3. Tabla abonos tendrá: todas las columnas necesarias
--
-- DESPUÉS DE ESTO, RECARGA LA APP y debería funcionar
-- =====================================================
