-- ============================================
-- ARREGLAR POLÍTICAS RLS - EJECUTAR AHORA
-- ============================================

-- 1. Eliminar todas las políticas conflictivas
DROP POLICY IF EXISTS "Permitir SELECT de propio perfil" ON perfiles;
DROP POLICY IF EXISTS "Permitir UPDATE de propio perfil" ON perfiles;
DROP POLICY IF EXISTS "Admins gestionan todos los perfiles" ON perfiles;
DROP POLICY IF EXISTS "Ver propio perfil o si es admin/moderador" ON perfiles;
DROP POLICY IF EXISTS "Actualizar propio perfil" ON perfiles;

-- 2. Crear políticas SIN recursión
-- Política para SELECT (ver propio perfil)
CREATE POLICY "select_propio_perfil" ON perfiles
    FOR SELECT 
    USING (auth.uid() = id);

-- Política para UPDATE (actualizar propio perfil)
CREATE POLICY "update_propio_perfil" ON perfiles
    FOR UPDATE 
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Política para INSERT (permite que el trigger inserte)
CREATE POLICY "insert_perfil_trigger" ON perfiles
    FOR INSERT
    WITH CHECK (true);

-- Política para admins ver todos (sin subconsulta recursiva)
CREATE POLICY "admin_select_all" ON perfiles
    FOR SELECT
    USING (
        (SELECT rol FROM perfiles WHERE id = auth.uid() LIMIT 1) IN ('administrador', 'moderador')
    );

-- Política para admins actualizar todos
CREATE POLICY "admin_update_all" ON perfiles
    FOR UPDATE
    USING (
        (SELECT rol FROM perfiles WHERE id = auth.uid() LIMIT 1) IN ('administrador', 'moderador')
    );

-- 3. Verificación
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ POLÍTICAS RLS CORREGIDAS';
    RAISE NOTICE '   Sin recursión infinita';
    RAISE NOTICE '';
END $$;
