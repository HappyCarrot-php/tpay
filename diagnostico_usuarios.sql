-- ============================================
-- DIAGNÓSTICO: Ver estado actual de usuarios y perfiles
-- ============================================

-- 1. Ver todos los usuarios en auth.users
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    raw_user_meta_data
FROM auth.users
ORDER BY created_at DESC;

-- 2. Ver todos los perfiles
SELECT 
    id,
    nombre,
    apellido_paterno,
    apellido_materno,
    telefono,
    rol,
    activo,
    creado
FROM perfiles
ORDER BY creado DESC;

-- 3. Ver usuarios SIN perfil (estos causan problemas)
SELECT 
    u.id,
    u.email,
    u.created_at,
    'SIN PERFIL' as estado
FROM auth.users u
LEFT JOIN perfiles p ON u.id = p.id
WHERE p.id IS NULL;

-- 4. SOLUCIÓN: Crear perfiles para usuarios sin perfil
INSERT INTO perfiles (id, nombre, apellido_paterno, rol, activo)
SELECT 
    u.id,
    COALESCE(u.raw_user_meta_data->>'nombre', 'Usuario'),
    COALESCE(u.raw_user_meta_data->>'apellido_paterno', 'Nuevo'),
    'cliente',
    TRUE
FROM auth.users u
LEFT JOIN perfiles p ON u.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 5. Verificar que todos tengan perfil ahora
SELECT 
    COUNT(*) as usuarios_total,
    COUNT(p.id) as con_perfil,
    COUNT(*) - COUNT(p.id) as sin_perfil
FROM auth.users u
LEFT JOIN perfiles p ON u.id = p.id;
