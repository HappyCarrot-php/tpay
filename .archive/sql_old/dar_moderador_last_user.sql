-- ============================================
-- HACER MODERADOR AL ÚLTIMO USUARIO REGISTRADO
-- ============================================

-- Hacer moderador al último usuario registrado
UPDATE perfiles 
SET rol = 'moderador' 
WHERE id = (
    SELECT id FROM perfiles 
    ORDER BY creado DESC 
    LIMIT 1
);

-- Verificar el cambio
SELECT 
    u.email,
    p.nombre,
    p.apellido_paterno,
    p.rol,
    p.activo,
    p.creado
FROM perfiles p
JOIN auth.users u ON p.id = u.id
ORDER BY p.creado DESC
LIMIT 1;

-- Mensaje de éxito
DO $$
DECLARE
    v_nombre VARCHAR;
    v_email VARCHAR;
BEGIN
    SELECT p.nombre || ' ' || p.apellido_paterno, u.email 
    INTO v_nombre, v_email
    FROM perfiles p
    JOIN auth.users u ON p.id = u.id
    ORDER BY p.creado DESC
    LIMIT 1;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ USUARIO ACTUALIZADO A MODERADOR';
    RAISE NOTICE '   Nombre: %', v_nombre;
    RAISE NOTICE '   Email: %', v_email;
    RAISE NOTICE '   Rol: moderador';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 Cierra sesión e inicia de nuevo para aplicar cambios';
    RAISE NOTICE '';
END $$;
