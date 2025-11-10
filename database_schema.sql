-- T-Pay Database Schema
-- Generated: 2025-11-09
-- ========================================
-- Este es un archivo de ejemplo con la estructura de la base de datos
-- Los backups reales se generan desde la aplicación en la opción "Actualizar BD"
-- ========================================

-- Tabla: perfiles
-- Almacena los perfiles de usuario (admin, moderador, cliente)
-- ========================================
CREATE TABLE IF NOT EXISTS public.perfiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre_completo VARCHAR(255) NOT NULL,
    rol VARCHAR(50) DEFAULT 'cliente',
    fecha_registro TIMESTAMP DEFAULT NOW(),
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT perfiles_user_id_key UNIQUE (user_id)
);

-- Índices para perfiles
CREATE INDEX idx_perfiles_user_id ON public.perfiles(user_id);
CREATE INDEX idx_perfiles_rol ON public.perfiles(rol);

-- ========================================
-- Tabla: clientes
-- Almacena información de los clientes que solicitan préstamos
-- ========================================
CREATE TABLE IF NOT EXISTS public.clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100) NOT NULL,
    apellido_materno VARCHAR(100),
    telefono VARCHAR(20),
    email VARCHAR(255),
    direccion TEXT,
    fecha_registro TIMESTAMP DEFAULT NOW(),
    activo BOOLEAN DEFAULT TRUE,
    notas TEXT
);

-- Índices para clientes
CREATE INDEX idx_clientes_nombre ON public.clientes(nombre, apellido_paterno);
CREATE INDEX idx_clientes_telefono ON public.clientes(telefono);
CREATE INDEX idx_clientes_email ON public.clientes(email);

-- ========================================
-- Tabla: movimientos (préstamos)
-- Almacena todos los préstamos registrados
-- ========================================
CREATE TABLE IF NOT EXISTS public.movimientos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES public.clientes(id) ON DELETE CASCADE,
    monto NUMERIC(12, 2) NOT NULL,
    interes NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total NUMERIC(12, 2) NOT NULL,
    saldo_restante NUMERIC(12, 2) NOT NULL,
    fecha_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_pago DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'activo',
    tipo_interes VARCHAR(20) DEFAULT 'mensual',
    porcentaje_interes NUMERIC(5, 2),
    notas TEXT,
    fecha_registro TIMESTAMP DEFAULT NOW(),
    fecha_completado TIMESTAMP,
    creado_por UUID REFERENCES auth.users(id)
);

-- Índices para movimientos
CREATE INDEX idx_movimientos_cliente_id ON public.movimientos(cliente_id);
CREATE INDEX idx_movimientos_estado ON public.movimientos(estado);
CREATE INDEX idx_movimientos_fecha_inicio ON public.movimientos(fecha_inicio);
CREATE INDEX idx_movimientos_fecha_pago ON public.movimientos(fecha_pago);

-- ========================================
-- Tabla: abonos
-- Almacena los pagos/abonos realizados a los préstamos
-- ========================================
CREATE TABLE IF NOT EXISTS public.abonos (
    id SERIAL PRIMARY KEY,
    movimiento_id INTEGER REFERENCES public.movimientos(id) ON DELETE CASCADE,
    monto NUMERIC(12, 2) NOT NULL,
    fecha_abono TIMESTAMP DEFAULT NOW(),
    tipo_abono VARCHAR(50) DEFAULT 'efectivo',
    notas TEXT,
    registrado_por UUID REFERENCES auth.users(id)
);

-- Índices para abonos
CREATE INDEX idx_abonos_movimiento_id ON public.abonos(movimiento_id);
CREATE INDEX idx_abonos_fecha ON public.abonos(fecha_abono);

-- ========================================
-- Políticas de seguridad (Row Level Security)
-- ========================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.abonos ENABLE ROW LEVEL SECURITY;

-- Política para perfiles
CREATE POLICY "Usuarios pueden ver su propio perfil" ON public.perfiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden actualizar su propio perfil" ON public.perfiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para clientes (admin y moderador acceso completo)
CREATE POLICY "Admin y moderador pueden ver todos los clientes" ON public.clientes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.perfiles 
            WHERE user_id = auth.uid() 
            AND rol IN ('administrador', 'moderador')
        )
    );

CREATE POLICY "Admin y moderador pueden insertar clientes" ON public.clientes
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.perfiles 
            WHERE user_id = auth.uid() 
            AND rol IN ('administrador', 'moderador')
        )
    );

CREATE POLICY "Admin y moderador pueden actualizar clientes" ON public.clientes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.perfiles 
            WHERE user_id = auth.uid() 
            AND rol IN ('administrador', 'moderador')
        )
    );

-- Políticas similares para movimientos y abonos
CREATE POLICY "Admin y moderador pueden ver todos los movimientos" ON public.movimientos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.perfiles 
            WHERE user_id = auth.uid() 
            AND rol IN ('administrador', 'moderador')
        )
    );

CREATE POLICY "Admin y moderador pueden gestionar movimientos" ON public.movimientos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.perfiles 
            WHERE user_id = auth.uid() 
            AND rol IN ('administrador', 'moderador')
        )
    );

CREATE POLICY "Admin y moderador pueden gestionar abonos" ON public.abonos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.perfiles 
            WHERE user_id = auth.uid() 
            AND rol IN ('administrador', 'moderador')
        )
    );

-- ========================================
-- Funciones útiles
-- ========================================

-- Función para actualizar saldo restante después de un abono
CREATE OR REPLACE FUNCTION actualizar_saldo_movimiento()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.movimientos
    SET saldo_restante = total - (
        SELECT COALESCE(SUM(monto), 0)
        FROM public.abonos
        WHERE movimiento_id = NEW.movimiento_id
    )
    WHERE id = NEW.movimiento_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar saldo automáticamente
CREATE TRIGGER trigger_actualizar_saldo
AFTER INSERT OR UPDATE OR DELETE ON public.abonos
FOR EACH ROW
EXECUTE FUNCTION actualizar_saldo_movimiento();

-- ========================================
-- Datos de ejemplo (comentados)
-- ========================================
/*
-- Usuario administrador (debes crearlo desde Supabase Auth primero)
INSERT INTO public.perfiles (user_id, nombre_completo, rol)
VALUES ('UUID-DEL-USUARIO', 'Administrador Principal', 'administrador');

-- Cliente de ejemplo
INSERT INTO public.clientes (nombre, apellido_paterno, telefono, email)
VALUES ('Juan', 'Pérez', '5551234567', 'juan.perez@example.com');

-- Préstamo de ejemplo
INSERT INTO public.movimientos (cliente_id, monto, interes, total, saldo_restante, fecha_pago, porcentaje_interes)
VALUES (1, 10000, 1000, 11000, 11000, CURRENT_DATE + INTERVAL '30 days', 10.0);

-- Abono de ejemplo
INSERT INTO public.abonos (movimiento_id, monto, notas)
VALUES (1, 2000, 'Primer abono');
*/

-- ========================================
-- FIN DEL SCRIPT
-- ========================================
-- Para generar un backup completo con datos reales:
-- 1. Inicia sesión en la aplicación como moderador
-- 2. Ve al menú lateral → "Actualizar BD"
-- 3. Presiona "Generar Nuevo Backup"
-- 4. El archivo .sql se descargará automáticamente
-- ========================================
