-- ============================================
-- LIMPIEZA TOTAL - EJECUTAR PRIMERO
-- ============================================

-- 1. Desactivar RLS temporalmente
ALTER TABLE perfiles DISABLE ROW LEVEL SECURITY;

-- 2. Eliminar todas las políticas
DROP POLICY IF EXISTS "Ver propio perfil o si es admin/moderador" ON perfiles;
DROP POLICY IF EXISTS "Actualizar propio perfil" ON perfiles;
DROP POLICY IF EXISTS "Admins/Moderadores gestionan perfiles" ON perfiles;
DROP POLICY IF EXISTS "Permitir SELECT de propio perfil" ON perfiles;
DROP POLICY IF EXISTS "Permitir UPDATE de propio perfil" ON perfiles;
DROP POLICY IF EXISTS "Admins gestionan todos los perfiles" ON perfiles;

-- 3. Eliminar triggers
DROP TRIGGER IF EXISTS trigger_crear_perfil_usuario ON auth.users;
DROP TRIGGER IF EXISTS trigger_perfiles_actualizado ON perfiles;

-- 4. Eliminar funciones
DROP FUNCTION IF EXISTS crear_perfil_automatico();
DROP FUNCTION IF EXISTS crear_perfil_manual(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR);

-- 5. ELIMINAR LA TABLA PERFILES COMPLETAMENTE
DROP TABLE IF EXISTS perfiles CASCADE;

-- 6. RECREAR LA TABLA PERFILES
CREATE TABLE perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100) NOT NULL,
    apellido_materno VARCHAR(100),
    nombre_completo VARCHAR(255) GENERATED ALWAYS AS (
        nombre || ' ' || apellido_paterno || 
        CASE WHEN apellido_materno IS NOT NULL THEN ' ' || apellido_materno ELSE '' END
    ) STORED,
    telefono VARCHAR(20),
    rol VARCHAR(20) NOT NULL DEFAULT 'cliente' CHECK (rol IN ('administrador', 'moderador', 'cliente')),
    avatar_url TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_acceso TIMESTAMP,
    creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Crear función de actualización de timestamp
CREATE OR REPLACE FUNCTION actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_perfiles_actualizado
    BEFORE UPDATE ON perfiles
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- 8. Crear función para crear perfil automáticamente
CREATE OR REPLACE FUNCTION crear_perfil_automatico()
RETURNS TRIGGER AS $$
BEGIN
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
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nombre', 'Usuario'),
        COALESCE(NEW.raw_user_meta_data->>'apellido_paterno', 'Nuevo'),
        NULLIF(COALESCE(NEW.raw_user_meta_data->>'apellido_materno', ''), ''),
        NULLIF(COALESCE(NEW.raw_user_meta_data->>'telefono', ''), ''),
        'cliente',
        TRUE
    )
    ON CONFLICT (id) DO UPDATE SET
        nombre = EXCLUDED.nombre,
        apellido_paterno = EXCLUDED.apellido_paterno,
        apellido_materno = EXCLUDED.apellido_materno,
        telefono = EXCLUDED.telefono,
        actualizado = CURRENT_TIMESTAMP;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error al crear perfil automático: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_crear_perfil_usuario
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION crear_perfil_automatico();

-- 9. Crear función RPC para crear perfil manualmente
CREATE OR REPLACE FUNCTION crear_perfil_manual(
    p_id UUID,
    p_nombre VARCHAR,
    p_apellido_paterno VARCHAR,
    p_apellido_materno VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO perfiles (
        id, nombre, apellido_paterno, apellido_materno,
        telefono, rol, activo
    )
    VALUES (
        p_id, p_nombre, p_apellido_paterno,
        NULLIF(p_apellido_materno, ''),
        NULLIF(p_telefono, ''),
        'cliente', TRUE
    )
    ON CONFLICT (id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION crear_perfil_manual TO authenticated, anon;

-- 10. ACTIVAR RLS
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;

-- 11. Crear políticas RLS
CREATE POLICY "Permitir SELECT de propio perfil" ON perfiles
    FOR SELECT USING (
        auth.uid() = id OR 
        EXISTS (SELECT 1 FROM perfiles WHERE id = auth.uid() AND rol IN ('administrador', 'moderador'))
    );

CREATE POLICY "Permitir UPDATE de propio perfil" ON perfiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins gestionan todos los perfiles" ON perfiles
    FOR ALL USING (
        EXISTS (SELECT 1 FROM perfiles WHERE id = auth.uid() AND rol IN ('administrador', 'moderador'))
    );

-- 12. Verificación final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '✅ TABLA PERFILES RECREADA COMPLETAMENTE';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE '✓ Tabla perfiles eliminada y recreada';
    RAISE NOTICE '✓ Trigger de creación automática activado';
    RAISE NOTICE '✓ Función RPC crear_perfil_manual disponible';
    RAISE NOTICE '✓ Políticas RLS configuradas';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 IMPORTANTE:';
    RAISE NOTICE '   1. Authentication → Settings → Confirm email = OFF';
    RAISE NOTICE '   2. Authentication → Settings → Enable signup = ON';
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;
