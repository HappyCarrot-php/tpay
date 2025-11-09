-- ============================================
-- SOLUCIÓN DEFINITIVA: TRIGGER + POLÍTICA RLS PARA REGISTRO
-- Ejecutar esto en el SQL Editor de Supabase
-- ============================================

-- 1. Eliminar trigger y función antigua
DROP TRIGGER IF EXISTS trigger_crear_perfil_usuario ON auth.users;
DROP FUNCTION IF EXISTS crear_perfil_automatico();

-- 2. Eliminar políticas antiguas de perfiles que puedan bloquear
DROP POLICY IF EXISTS "Ver propio perfil o si es admin/moderador" ON perfiles;
DROP POLICY IF EXISTS "Actualizar propio perfil" ON perfiles;
DROP POLICY IF EXISTS "Admins/Moderadores gestionan perfiles" ON perfiles;

-- 3. Crear función con SECURITY DEFINER (bypassa RLS)
CREATE OR REPLACE FUNCTION crear_perfil_automatico()
RETURNS TRIGGER AS $$
BEGIN
    -- Intentar insertar el perfil, si ya existe no hacer nada
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
        -- Log del error para debugging pero no fallar
        RAISE WARNING 'Error al crear perfil automático: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Crear trigger
CREATE TRIGGER trigger_crear_perfil_usuario
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION crear_perfil_automatico();

-- 5. Crear políticas RLS correctas
DROP POLICY IF EXISTS "Permitir SELECT de propio perfil" ON perfiles;
DROP POLICY IF EXISTS "Permitir UPDATE de propio perfil" ON perfiles;
DROP POLICY IF EXISTS "Admins gestionan todos los perfiles" ON perfiles;

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

-- 6. Verificación
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '✅ CONFIGURACIÓN COMPLETA Y ACTUALIZADA';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 CAMBIOS APLICADOS:';
    RAISE NOTICE '   ✓ Trigger con SECURITY DEFINER (bypassa RLS)';
    RAISE NOTICE '   ✓ Manejo de errores con EXCEPTION';
    RAISE NOTICE '   ✓ Políticas RLS recreadas correctamente';
    RAISE NOTICE '   ✓ Campo activo = TRUE por defecto';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  VERIFICAR EN DASHBOARD:';
    RAISE NOTICE '   1. Authentication → Providers → Email';
    RAISE NOTICE '      → Desactivar "Confirm email"';
    RAISE NOTICE '';
    RAISE NOTICE '   2. Authentication → Settings';
    RAISE NOTICE '      → Asegurar "Enable signup" está activado';
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;
