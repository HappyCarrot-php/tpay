-- =====================================================
-- SOLUCIÓN RÁPIDA PARA ERROR DE PERMISOS
-- =====================================================
-- Ejecuta estos comandos UNO POR UNO en el SQL Editor de Supabase
-- =====================================================

-- OPCIÓN 1: DESACTIVAR RLS TEMPORALMENTE (SOLO PARA TESTING)
-- =====================================================
-- IMPORTANTE: Esto permitirá que CUALQUIER usuario vea TODOS los datos
-- Solo úsalo para verificar que la app funciona, luego activa RLS de nuevo

ALTER TABLE clientes DISABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos DISABLE ROW LEVEL SECURITY;
ALTER TABLE abonos DISABLE ROW LEVEL SECURITY;
ALTER TABLE perfiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE historial_accesos DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- OPCIÓN 2: VERIFICAR QUE TIENES UN PERFIL CREADO
-- =====================================================
-- Ejecuta esto para ver tu UUID de usuario:
SELECT auth.uid();

-- Ejecuta esto para ver si tienes un perfil:
SELECT * FROM perfiles WHERE id = auth.uid();

-- Si NO tienes un perfil, créalo (reemplaza 'TU_UUID' con el resultado del primer query):
-- INSERT INTO perfiles (id, rol, nombre, email)
-- VALUES ('TU_UUID', 'administrador', 'Admin', 'tu_email@example.com');

-- =====================================================
-- OPCIÓN 3: HABILITAR RLS + CREAR POLÍTICAS PERMISIVAS (RECOMENDADO)
-- =====================================================
-- Primero habilita RLS:
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE abonos ENABLE ROW LEVEL SECURITY;
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;

-- Luego crea políticas que permitan todo a usuarios autenticados:

-- CLIENTES: Todos los usuarios autenticados pueden ver/editar
DROP POLICY IF EXISTS "allow_all_authenticated_clientes" ON clientes;
CREATE POLICY "allow_all_authenticated_clientes"
ON clientes
FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- MOVIMIENTOS: Todos los usuarios autenticados pueden ver/editar
DROP POLICY IF EXISTS "allow_all_authenticated_movimientos" ON movimientos;
CREATE POLICY "allow_all_authenticated_movimientos"
ON movimientos
FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- ABONOS: Todos los usuarios autenticados pueden ver/editar
DROP POLICY IF EXISTS "allow_all_authenticated_abonos" ON abonos;
CREATE POLICY "allow_all_authenticated_abonos"
ON abonos
FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- PERFILES: Todos los usuarios autenticados pueden ver/editar
DROP POLICY IF EXISTS "allow_all_authenticated_perfiles" ON perfiles;
CREATE POLICY "allow_all_authenticated_perfiles"
ON perfiles
FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- =====================================================
-- VERIFICACIÓN
-- =====================================================
-- Ejecuta esto para verificar que las políticas se crearon:
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('clientes', 'movimientos', 'abonos', 'perfiles')
ORDER BY tablename;

-- =====================================================
-- RECOMENDACIÓN:
-- =====================================================
-- Para solucionar INMEDIATAMENTE el problema, ejecuta la OPCIÓN 1
-- (desactivar RLS temporalmente)
-- 
-- Una vez que verifiques que la app funciona, ejecuta la OPCIÓN 3
-- (políticas permisivas para usuarios autenticados)
--
-- Más adelante, cuando quieras seguridad granular, usa el archivo
-- SUPABASE_RLS_POLICIES.sql que tiene políticas por rol
-- =====================================================
