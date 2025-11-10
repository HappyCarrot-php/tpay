-- ============================================
-- LIMPIAR USUARIOS Y PERFILES DE PRUEBA
-- Ejecutar en SQL Editor de Supabase
-- ============================================

-- 1. Ver usuarios que se van a eliminar (opcional - para verificar)
SELECT 
    u.id,
    u.email,
    u.created_at,
    p.nombre,
    p.apellido_paterno
FROM auth.users u
LEFT JOIN perfiles p ON u.id = p.id
ORDER BY u.created_at DESC;

-- 2. ELIMINAR TODOS LOS PERFILES (esto también elimina los usuarios de auth.users por CASCADE)
DELETE FROM perfiles;

-- 3. Verificar que todo se eliminó
SELECT COUNT(*) as total_usuarios FROM auth.users;
SELECT COUNT(*) as total_perfiles FROM perfiles;

-- ============================================
-- Si solo quieres eliminar un usuario específico por email:
-- ============================================
-- DELETE FROM auth.users WHERE email = 'toledo.avalos.ricardo@gmail.com';

-- ============================================
-- NOTA: 
-- Al eliminar de 'perfiles', los usuarios en auth.users también 
-- se eliminan automáticamente por el ON DELETE CASCADE
-- ============================================
