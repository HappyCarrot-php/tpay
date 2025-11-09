-- Eliminar trigger y función antigua
DROP TRIGGER IF EXISTS trigger_crear_perfil_usuario ON auth.users;
DROP FUNCTION IF EXISTS crear_perfil_automatico();

-- Crear función mejorada
CREATE OR REPLACE FUNCTION crear_perfil_automatico()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO perfiles (
        id, 
        nombre, 
        apellido_paterno, 
        apellido_materno,
        telefono,
        rol
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nombre', 'Usuario'),
        COALESCE(NEW.raw_user_meta_data->>'apellido_paterno', 'Nuevo'),
        NULLIF(COALESCE(NEW.raw_user_meta_data->>'apellido_materno', ''), ''),
        NULLIF(COALESCE(NEW.raw_user_meta_data->>'telefono', ''), ''),
        'cliente'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crear trigger
CREATE TRIGGER trigger_crear_perfil_usuario
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION crear_perfil_automatico();