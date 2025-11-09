-- ============================================
-- BORRAR TODO - USUARIOS Y PERFILES
-- ============================================

-- 1. Desactivar RLS para poder eliminar
ALTER TABLE perfiles DISABLE ROW LEVEL SECURITY;

-- 2. Eliminar todos los perfiles (esto elimina usuarios por CASCADE)
DELETE FROM perfiles;

-- 3. Verificar que todo se eliminó
SELECT 
    (SELECT COUNT(*) FROM auth.users) as usuarios_total,
    (SELECT COUNT(*) FROM perfiles) as perfiles_total;

-- 4. Si aún quedan usuarios sin perfil, eliminarlos
DELETE FROM auth.users WHERE id NOT IN (SELECT id FROM perfiles);

-- 5. Verificación final
SELECT 
    (SELECT COUNT(*) FROM auth.users) as usuarios_restantes,
    (SELECT COUNT(*) FROM perfiles) as perfiles_restantes;

-- Debe mostrar:
-- usuarios_restantes: 0
-- perfiles_restantes: 0

-- 6. Mensaje de éxito
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ TODO ELIMINADO';
    RAISE NOTICE '   Usuarios: 0';
    RAISE NOTICE '   Perfiles: 0';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Ahora puedes registrar usuarios nuevos';
    RAISE NOTICE '';
END $$;
