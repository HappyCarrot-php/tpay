-- ============================================
-- FUNCIÓN RPC PARA CREAR PERFIL MANUALMENTE
-- Ejecutar en SQL Editor de Supabase
-- ============================================

-- Crear función para insertar perfil manualmente (bypass RLS)
CREATE OR REPLACE FUNCTION crear_perfil_manual(
    p_id UUID,
    p_nombre VARCHAR,
    p_apellido_paterno VARCHAR,
    p_apellido_materno VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Intentar insertar, si ya existe no hacer nada
    INSERT INTO perfiles (
        id,
        nombre,
        apellido_paterno,
        apellido_materno,
        telefono,
        rol,
        activo
    )
    VALUES (
        p_id,
        p_nombre,
        p_apellido_paterno,
        NULLIF(p_apellido_materno, ''),
        NULLIF(p_telefono, ''),
        'cliente',
        TRUE
    )
    ON CONFLICT (id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Dar permisos de ejecución
GRANT EXECUTE ON FUNCTION crear_perfil_manual TO authenticated, anon;

-- Verificar
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ Función crear_perfil_manual creada exitosamente';
    RAISE NOTICE '   Ahora la app puede crear perfiles manualmente si el trigger falla';
    RAISE NOTICE '';
END $$;
