-- ============================================
-- PASO 1: DESACTIVAR RLS Y LIMPIAR TODO
-- ============================================

-- Desactivar RLS
ALTER TABLE perfiles DISABLE ROW LEVEL SECURITY;

-- Eliminar TODAS las políticas (sin importar errores)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'perfiles')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON perfiles';
    END LOOP;
END $$;

-- Verificar que no hay políticas
SELECT COUNT(*) as total_policies FROM pg_policies WHERE tablename = 'perfiles';

-- ============================================
-- PASO 2: CREAR POLÍTICAS SIMPLES
-- ============================================

-- Activar RLS
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;

-- Política 1: SELECT propio perfil
CREATE POLICY "select_propio_perfil" ON perfiles
    FOR SELECT 
    USING (auth.uid() = id);

-- Política 2: UPDATE propio perfil
CREATE POLICY "update_propio_perfil" ON perfiles
    FOR UPDATE 
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Política 3: INSERT (para el trigger)
CREATE POLICY "insert_perfil_trigger" ON perfiles
    FOR INSERT
    WITH CHECK (true);

-- Verificación final
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'perfiles';

-- Mensaje de éxito
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE '✅ POLÍTICAS RLS CONFIGURADAS';
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE 'Total: 3 políticas';
    RAISE NOTICE '  ✓ SELECT: propio perfil';
    RAISE NOTICE '  ✓ UPDATE: propio perfil';
    RAISE NOTICE '  ✓ INSERT: permite trigger';
    RAISE NOTICE '';
END $$;
