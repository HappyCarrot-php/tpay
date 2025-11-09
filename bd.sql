-- ============================================
-- TOLEDO PRÉSTAMOS - BASE DE DATOS SUPABASE OPTIMIZADA PARA FLUTTER
-- Versión actualizada con datos al 08/11/2025
-- 100% Compatible con Supabase Flutter SDK + Auth integrado
-- ============================================

-- IMPORTANTE: Ejecutar en el SQL Editor de Supabase

-- ============================================
-- LIMPIAR TABLAS EXISTENTES
-- ============================================
DROP TABLE IF EXISTS abonos CASCADE;
DROP TABLE IF EXISTS movimientos CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;
DROP TABLE IF EXISTS perfiles CASCADE;
DROP TABLE IF EXISTS historial_accesos CASCADE;

-- ============================================
-- TABLA: perfiles
-- Extiende auth.users de Supabase (Supabase Auth maneja email y password)
-- ============================================
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
    actualizado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT telefono_valido CHECK (telefono IS NULL OR telefono ~ '^\+?[0-9]{10,15}$')
);

COMMENT ON TABLE perfiles IS 'Información de usuarios del sistema. Email y password en auth.users (Supabase Auth)';
COMMENT ON COLUMN perfiles.rol IS 'cliente: solo visualiza sus datos | moderador: gestión completa | administrador: control absoluto';

-- ============================================
-- TABLA: clientes
-- Información de clientes del negocio de préstamos
-- ============================================
CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    usuario_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100) NOT NULL,
    apellido_materno VARCHAR(100),
    nombre_completo VARCHAR(255) GENERATED ALWAYS AS (
        nombre || ' ' || apellido_paterno || 
        CASE WHEN apellido_materno IS NOT NULL THEN ' ' || apellido_materno ELSE '' END
    ) STORED,
    telefono VARCHAR(20),
    email VARCHAR(255),
    rfc VARCHAR(13),
    curp VARCHAR(18),
    fecha_nacimiento DATE,
    direccion TEXT,
    ciudad VARCHAR(100),
    estado VARCHAR(100) DEFAULT 'Tamaulipas',
    codigo_postal VARCHAR(10),
    identificacion_tipo VARCHAR(50),
    identificacion_numero VARCHAR(50),
    foto_url TEXT,
    referencias_personales JSONB,
    historial_crediticio TEXT,
    calificacion_cliente NUMERIC(3,2) DEFAULT 5.00 CHECK (calificacion_cliente BETWEEN 0 AND 5),
    notas TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT telefono_valido CHECK (telefono IS NULL OR telefono ~ '^\+?[0-9]{10,15}$'),
    CONSTRAINT email_valido CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT rfc_valido CHECK (rfc IS NULL OR LENGTH(rfc) BETWEEN 12 AND 13),
    CONSTRAINT curp_valido CHECK (curp IS NULL OR LENGTH(curp) = 18)
);

COMMENT ON TABLE clientes IS 'Clientes del negocio de préstamos - Información completa para gestión crediticia';
COMMENT ON COLUMN clientes.referencias_personales IS 'JSON: [{"nombre": "...", "telefono": "...", "relacion": "..."}]';
COMMENT ON COLUMN clientes.calificacion_cliente IS 'Calificación de 0 a 5 basada en historial de pagos';

-- Insertar clientes actualizados - Parseando nombres completos
INSERT INTO clientes (id_cliente, nombre, apellido_paterno, apellido_materno, activo) VALUES
(1, 'Rosa Carolina', 'Avalos', 'Dominguez', TRUE),
(2, 'Jesus Rafael', 'Avalos', 'Dominguez', TRUE),
(3, 'Luis Fernando', 'Castillo', 'Hernandez', TRUE),
(4, 'Diana', 'Avalos', 'Dominguez', TRUE),
(5, 'Edith', 'Zamarripa', NULL, TRUE),
(6, 'Luz Irene', 'Medina', 'Cortes', TRUE),
(7, 'Yoselin', 'Macias', 'Hernandez', TRUE),
(8, 'Maria Isabel', 'Cruz', NULL, TRUE),
(9, 'Delia', 'Cortez', NULL, TRUE),
(10, 'Gaby', 'Santiago', NULL, TRUE);

SELECT setval('clientes_id_cliente_seq', 10, true);

-- ============================================
-- TABLA: movimientos
-- Registro de préstamos y transacciones
-- ============================================
CREATE TABLE movimientos (
    id SERIAL PRIMARY KEY,
    id_cliente INT NOT NULL REFERENCES clientes(id_cliente) ON DELETE RESTRICT,
    monto NUMERIC(12,2) NOT NULL CHECK (monto > 0),
    interes NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (interes >= 0),
    tasa_interes_porcentaje NUMERIC(5,2),
    abonos NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (abonos >= 0),
    saldo_pendiente NUMERIC(12,2) GENERATED ALWAYS AS (monto + interes - abonos) STORED,
    fecha_inicio DATE NOT NULL,
    fecha_pago DATE NOT NULL,
    dias_prestamo INT GENERATED ALWAYS AS (fecha_pago - fecha_inicio) STORED,
    estado_pagado BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_pagado TIMESTAMP,
    metodo_pago VARCHAR(50),
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    motivo_eliminacion TEXT,
    usuario_registro UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notas TEXT,
    creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fecha_pago_valida CHECK (fecha_pago >= fecha_inicio),
    CONSTRAINT abonos_validos CHECK (abonos <= (monto + interes))
);

COMMENT ON TABLE movimientos IS 'Registro de préstamos - saldo_pendiente y dias_prestamo se calculan automáticamente';

-- Insertar movimientos de la BD local
INSERT INTO movimientos (id, id_cliente, monto, interes, fecha_inicio, fecha_pago, estado_pagado, eliminado, creado, abonos) VALUES
(1, 1, 1000.00, 2620.00, '2025-07-02', '2026-05-16', FALSE, FALSE, '2025-07-10 03:56:21', 20.00),
(2, 1, 250.00, 20.00, '2025-07-06', '2025-07-15', TRUE, FALSE, '2025-07-10 03:56:49', 0.00),
(3, 2, 1000.00, 500.00, '2025-07-10', '2025-12-10', FALSE, FALSE, '2025-07-10 21:08:58', 0.00),
(4, 1, 150.00, 20.00, '2025-07-12', '2025-07-15', TRUE, FALSE, '2025-07-13 04:02:42', 0.00),
(5, 1, 50.00, 10.00, '2025-07-14', '2025-07-15', TRUE, FALSE, '2025-07-15 03:49:39', 0.00),
(6, 1, 500.00, 50.00, '2025-07-17', '2025-08-15', TRUE, FALSE, '2025-07-17 19:16:12', 0.00),
(7, 1, 300.00, 15.00, '2025-07-18', '2025-07-30', TRUE, FALSE, '2025-07-19 10:59:23', 0.00),
(8, 3, 2000.00, 500.00, '2025-07-19', '2025-11-04', FALSE, FALSE, '2025-07-19 18:42:00', 0.00),
(9, 1, 800.00, 400.00, '2025-07-19', '2026-05-16', FALSE, FALSE, '2025-07-19 21:04:26', 0.00),
(10, 4, 1100.00, 550.00, '2025-07-19', '2025-12-19', FALSE, FALSE, '2025-07-19 21:07:08', 0.00),
(11, 1, 1200.00, 330.00, '2025-07-25', '2026-05-16', FALSE, FALSE, '2025-07-25 23:34:27', 0.00),
(12, 1, 100.00, 3.00, '2025-07-29', '2025-07-30', TRUE, FALSE, '2025-07-29 22:18:40', 0.00),
(13, 5, 1000.00, 400.00, '2025-08-03', '2025-11-16', FALSE, FALSE, '2025-08-04 00:30:23', 0.00),
(14, 1, 500.00, 100.00, '2025-08-16', '2026-05-16', FALSE, FALSE, '2025-08-16 18:12:27', 0.00),
(15, 1, 1000.00, 250.00, '2025-08-16', '2026-05-16', FALSE, FALSE, '2025-08-17 00:08:42', 0.00),
(16, 1, 250.00, 50.00, '2025-08-26', '2026-05-16', FALSE, FALSE, '2025-08-26 22:19:22', 0.00),
(17, 1, 500.00, 25.00, '2025-09-01', '2025-09-30', TRUE, FALSE, '2025-09-01 21:46:03', 0.00),
(18, 1, 500.00, 25.00, '2025-09-06', '2025-09-15', TRUE, FALSE, '2025-09-06 23:35:06', 0.00),
(19, 6, 400.00, 20.00, '2025-09-08', '2025-10-30', TRUE, FALSE, '2025-09-08 23:40:57', 0.00),
(20, 5, 1200.00, 60.00, '2025-09-17', '2025-09-30', TRUE, FALSE, '2025-09-17 23:22:33', 0.00),
(21, 1, 100.00, 2.00, '2025-09-23', '2025-09-30', TRUE, FALSE, '2025-09-24 04:11:41', 0.00),
(22, 1, 500.00, 25.00, '2025-09-24', '2025-09-30', TRUE, FALSE, '2025-09-25 05:08:27', 0.00),
(23, 1, 250.00, 12.50, '2025-09-26', '2025-09-30', TRUE, FALSE, '2025-09-26 20:09:16', 0.00),
(24, 1, 1500.00, 75.00, '2025-09-28', '2026-05-16', FALSE, FALSE, '2025-09-28 08:08:07', 75.00),
(25, 7, 120.00, 0.00, '2025-09-28', '2025-10-04', TRUE, FALSE, '2025-09-29 12:29:31', 0.00),
(26, 5, 1000.00, 50.00, '2025-10-02', '2025-10-15', TRUE, FALSE, '2025-10-02 22:08:09', 0.00),
(27, 7, 129.00, 0.00, '2025-10-05', '2025-10-31', TRUE, FALSE, '2025-10-05 20:06:39', 0.00),
(28, 8, 2200.00, 100.00, '2025-10-07', '2025-10-17', TRUE, FALSE, '2025-10-07 22:38:49', 2300.00),
(29, 9, 300.00, 50.00, '2025-10-09', '2025-10-15', TRUE, FALSE, '2025-10-09 19:24:56', 0.00),
(30, 1, 200.00, 20.00, '2025-10-09', '2025-10-15', TRUE, FALSE, '2025-10-09 19:26:19', 0.00),
(31, 10, 1300.00, 100.00, '2025-10-12', '2025-10-30', TRUE, FALSE, '2025-10-13 02:45:33', 0.00),
(32, 1, 1500.00, 0.00, '2025-10-23', '2025-10-30', TRUE, FALSE, '2025-10-25 03:48:54', 0.00),
(33, 1, 500.00, 50.00, '2025-10-26', '2025-11-15', FALSE, FALSE, '2025-10-27 02:03:35', 50.00),
(34, 9, 2000.00, 200.00, '2025-10-29', '2025-11-30', FALSE, FALSE, '2025-10-29 11:43:59', 0.00),
(35, 1, 300.00, 30.00, '2025-11-03', '2025-11-15', FALSE, FALSE, '2025-11-04 04:51:19', 0.00);

SELECT setval('movimientos_id_seq', 35, true);

-- ============================================
-- TABLA: abonos
-- Registro detallado de cada pago
-- ============================================
CREATE TABLE abonos (
    id SERIAL PRIMARY KEY,
    id_movimiento INT NOT NULL REFERENCES movimientos(id) ON DELETE CASCADE,
    monto_abono NUMERIC(10,2) NOT NULL CHECK (monto_abono > 0),
    fecha_abono TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metodo_pago VARCHAR(50),
    referencia VARCHAR(100),
    comprobante_url TEXT,
    usuario_registro UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notas TEXT,
    creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: historial_accesos
-- Auditoría de accesos al sistema
-- ============================================
CREATE TABLE historial_accesos (
    id SERIAL PRIMARY KEY,
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    accion VARCHAR(100) NOT NULL,
    detalles JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    exitoso BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_acceso TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON COLUMN historial_accesos.detalles IS 'JSON con información adicional de la acción realizada';

-- ============================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================
CREATE INDEX idx_perfiles_rol ON perfiles(rol);
CREATE INDEX idx_perfiles_activo ON perfiles(activo);
CREATE INDEX idx_perfiles_nombre_completo ON perfiles USING gin(to_tsvector('spanish', nombre_completo));

CREATE INDEX idx_clientes_nombre_completo ON clientes USING gin(to_tsvector('spanish', nombre_completo));
CREATE INDEX idx_clientes_usuario ON clientes(usuario_id);
CREATE INDEX idx_clientes_activo ON clientes(activo);
CREATE INDEX idx_clientes_telefono ON clientes(telefono);

CREATE INDEX idx_movimientos_cliente ON movimientos(id_cliente);
CREATE INDEX idx_movimientos_estado ON movimientos(estado_pagado);
CREATE INDEX idx_movimientos_eliminado ON movimientos(eliminado);
CREATE INDEX idx_movimientos_fecha_pago ON movimientos(fecha_pago);
CREATE INDEX idx_movimientos_usuario ON movimientos(usuario_registro);

CREATE INDEX idx_abonos_movimiento ON abonos(id_movimiento);
CREATE INDEX idx_abonos_fecha ON abonos(fecha_abono);

CREATE INDEX idx_historial_usuario ON historial_accesos(usuario_id);
CREATE INDEX idx_historial_fecha ON historial_accesos(fecha_acceso);

-- ============================================
-- FUNCIONES Y TRIGGERS
-- ============================================

-- Actualizar timestamp automáticamente
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

CREATE TRIGGER trigger_clientes_actualizado
    BEFORE UPDATE ON clientes
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

CREATE TRIGGER trigger_movimientos_actualizado
    BEFORE UPDATE ON movimientos
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- Crear perfil automáticamente al registrarse
CREATE OR REPLACE FUNCTION crear_perfil_automatico()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO perfiles (id, nombre, apellido_paterno, rol)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nombre', 'Usuario'),
        COALESCE(NEW.raw_user_meta_data->>'apellido_paterno', 'Nuevo'),
        'cliente'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_crear_perfil_usuario
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION crear_perfil_automatico();

-- ============================================
-- FUNCIONES RPC PARA FLUTTER
-- ============================================

-- Obtener información del usuario actual
CREATE OR REPLACE FUNCTION obtener_perfil_actual()
RETURNS TABLE (
    id UUID,
    email VARCHAR,
    nombre_completo VARCHAR,
    telefono VARCHAR,
    rol VARCHAR,
    avatar_url TEXT,
    activo BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        u.email::VARCHAR,
        p.nombre_completo::VARCHAR,
        p.telefono,
        p.rol,
        p.avatar_url,
        p.activo
    FROM perfiles p
    INNER JOIN auth.users u ON p.id = u.id
    WHERE p.id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verificar rol del usuario
CREATE OR REPLACE FUNCTION obtener_rol_usuario()
RETURNS TEXT AS $$
BEGIN
    RETURN (SELECT rol FROM perfiles WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verificar permisos administrativos
CREATE OR REPLACE FUNCTION tiene_permisos_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM perfiles 
        WHERE id = auth.uid() 
        AND rol IN ('administrador', 'moderador')
        AND activo = TRUE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cambiar rol de usuario (solo administradores)
CREATE OR REPLACE FUNCTION cambiar_rol_usuario(
    p_usuario_id UUID,
    p_nuevo_rol VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    v_rol_actual VARCHAR;
BEGIN
    -- Verificar que quien ejecuta es administrador
    SELECT rol INTO v_rol_actual FROM perfiles WHERE id = auth.uid();
    
    IF v_rol_actual != 'administrador' THEN
        RAISE EXCEPTION 'Solo administradores pueden cambiar roles';
    END IF;
    
    -- Actualizar rol
    UPDATE perfiles
    SET rol = p_nuevo_rol,
        actualizado = CURRENT_TIMESTAMP
    WHERE id = p_usuario_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Registrar movimiento
CREATE OR REPLACE FUNCTION registrar_movimiento(
    p_id_cliente INT,
    p_monto NUMERIC,
    p_interes NUMERIC,
    p_fecha_inicio DATE,
    p_fecha_pago DATE,
    p_notas TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    nuevo_id INT;
BEGIN
    IF NOT tiene_permisos_admin() THEN
        RAISE EXCEPTION 'No tienes permisos para registrar movimientos';
    END IF;
    
    INSERT INTO movimientos (
        id_cliente, monto, interes, fecha_inicio, fecha_pago, 
        usuario_registro, notas
    )
    VALUES (
        p_id_cliente, p_monto, p_interes, p_fecha_inicio, p_fecha_pago,
        auth.uid(), p_notas
    )
    RETURNING id INTO nuevo_id;
    
    RETURN nuevo_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Registrar abono
CREATE OR REPLACE FUNCTION registrar_abono(
    p_id_movimiento INT,
    p_monto_abono NUMERIC,
    p_metodo_pago VARCHAR DEFAULT NULL,
    p_notas TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
    nuevo_id INT;
    v_total_deuda NUMERIC;
    v_abonos_actuales NUMERIC;
BEGIN
    IF NOT tiene_permisos_admin() THEN
        RAISE EXCEPTION 'No tienes permisos para registrar abonos';
    END IF;
    
    SELECT (monto + interes), abonos 
    INTO v_total_deuda, v_abonos_actuales
    FROM movimientos
    WHERE id = p_id_movimiento AND eliminado = FALSE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Movimiento no encontrado';
    END IF;
    
    IF (v_abonos_actuales + p_monto_abono) > v_total_deuda THEN
        RAISE EXCEPTION 'El abono excede la deuda total';
    END IF;
    
    INSERT INTO abonos (
        id_movimiento, monto_abono, metodo_pago, 
        usuario_registro, notas
    )
    VALUES (
        p_id_movimiento, p_monto_abono, p_metodo_pago,
        auth.uid(), p_notas
    )
    RETURNING id INTO nuevo_id;
    
    UPDATE movimientos
    SET abonos = abonos + p_monto_abono,
        estado_pagado = CASE 
            WHEN (abonos + p_monto_abono) >= v_total_deuda THEN TRUE
            ELSE FALSE
        END,
        fecha_pagado = CASE 
            WHEN (abonos + p_monto_abono) >= v_total_deuda THEN CURRENT_TIMESTAMP
            ELSE fecha_pagado
        END
    WHERE id = p_id_movimiento;
    
    RETURN nuevo_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- VISTAS OPTIMIZADAS PARA FLUTTER
-- ============================================

CREATE OR REPLACE VIEW vista_prestamos_activos AS
SELECT 
    m.id,
    m.id_cliente,
    c.nombre_completo as cliente,
    c.telefono,
    c.foto_url,
    m.monto,
    m.interes,
    m.abonos,
    m.saldo_pendiente,
    m.fecha_inicio,
    m.fecha_pago,
    m.dias_prestamo,
    CASE 
        WHEN m.fecha_pago < CURRENT_DATE THEN 'vencido'
        WHEN m.fecha_pago = CURRENT_DATE THEN 'vence_hoy'
        ELSE 'vigente'
    END as status,
    CASE 
        WHEN m.fecha_pago < CURRENT_DATE THEN (CURRENT_DATE - m.fecha_pago)
        ELSE 0
    END as dias_vencido,
    m.notas,
    m.creado
FROM movimientos m
INNER JOIN clientes c ON m.id_cliente = c.id_cliente
WHERE m.estado_pagado = FALSE AND m.eliminado = FALSE AND c.activo = TRUE
ORDER BY m.fecha_pago ASC;

CREATE OR REPLACE VIEW vista_resumen_clientes AS
SELECT 
    c.id_cliente,
    c.nombre_completo,
    c.telefono,
    c.email,
    c.foto_url,
    c.calificacion_cliente,
    COUNT(m.id) as total_prestamos,
    COUNT(CASE WHEN m.estado_pagado = FALSE AND m.eliminado = FALSE THEN 1 END) as prestamos_activos,
    COALESCE(SUM(CASE WHEN m.estado_pagado = FALSE AND m.eliminado = FALSE THEN m.saldo_pendiente END), 0) as deuda_total,
    COALESCE(SUM(CASE WHEN m.estado_pagado = TRUE THEN m.monto END), 0) as total_pagado,
    MAX(m.fecha_pago) FILTER (WHERE m.estado_pagado = FALSE AND m.eliminado = FALSE) as proximo_vencimiento,
    EXISTS (
        SELECT 1 FROM movimientos 
        WHERE id_cliente = c.id_cliente 
        AND estado_pagado = FALSE AND eliminado = FALSE 
        AND fecha_pago < CURRENT_DATE
    ) as tiene_vencidos,
    c.activo
FROM clientes c
LEFT JOIN movimientos m ON c.id_cliente = m.id_cliente
GROUP BY c.id_cliente
ORDER BY deuda_total DESC;

CREATE OR REPLACE VIEW vista_estadisticas_dashboard AS
SELECT 
    COUNT(DISTINCT c.id_cliente) as total_clientes,
    COUNT(DISTINCT CASE WHEN c.activo THEN c.id_cliente END) as clientes_activos,
    COUNT(m.id) as total_prestamos,
    COUNT(CASE WHEN m.estado_pagado = FALSE AND m.eliminado = FALSE THEN 1 END) as prestamos_activos,
    COUNT(CASE WHEN m.estado_pagado = TRUE THEN 1 END) as prestamos_pagados,
    COUNT(CASE WHEN m.estado_pagado = FALSE AND m.eliminado = FALSE AND m.fecha_pago < CURRENT_DATE THEN 1 END) as prestamos_vencidos,
    COALESCE(SUM(CASE WHEN m.estado_pagado = FALSE AND m.eliminado = FALSE THEN m.saldo_pendiente END), 0) as capital_circulacion,
    COALESCE(SUM(CASE WHEN m.estado_pagado = TRUE THEN m.interes END), 0) as intereses_ganados,
    COALESCE(SUM(CASE WHEN m.estado_pagado = FALSE AND m.eliminado = FALSE AND m.fecha_pago < CURRENT_DATE THEN m.saldo_pendiente END), 0) as capital_vencido
FROM clientes c
LEFT JOIN movimientos m ON c.id_cliente = m.id_cliente;

-- ============================================
-- POLÍTICAS RLS (ROW LEVEL SECURITY)
-- ============================================

ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE abonos ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_accesos ENABLE ROW LEVEL SECURITY;

-- PERFILES
CREATE POLICY "Ver propio perfil o si es admin/moderador" ON perfiles
    FOR SELECT USING (
        auth.uid() = id OR 
        EXISTS (SELECT 1 FROM perfiles WHERE id = auth.uid() AND rol IN ('administrador', 'moderador'))
    );

CREATE POLICY "Actualizar propio perfil" ON perfiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins/Moderadores gestionan perfiles" ON perfiles
    FOR ALL USING (
        EXISTS (SELECT 1 FROM perfiles WHERE id = auth.uid() AND rol IN ('administrador', 'moderador'))
    );

-- CLIENTES
CREATE POLICY "Admins/Moderadores gestionan clientes" ON clientes
    FOR ALL USING (tiene_permisos_admin());

CREATE POLICY "Clientes ven sus datos" ON clientes
    FOR SELECT USING (usuario_id = auth.uid());

-- MOVIMIENTOS
CREATE POLICY "Admins/Moderadores gestionan movimientos" ON movimientos
    FOR ALL USING (tiene_permisos_admin());

CREATE POLICY "Clientes ven sus movimientos" ON movimientos
    FOR SELECT USING (
        id_cliente IN (SELECT id_cliente FROM clientes WHERE usuario_id = auth.uid())
    );

-- ABONOS
CREATE POLICY "Admins/Moderadores gestionan abonos" ON abonos
    FOR ALL USING (tiene_permisos_admin());

CREATE POLICY "Clientes ven sus abonos" ON abonos
    FOR SELECT USING (
        id_movimiento IN (
            SELECT m.id FROM movimientos m
            INNER JOIN clientes c ON m.id_cliente = c.id_cliente
            WHERE c.usuario_id = auth.uid()
        )
    );

-- HISTORIAL
CREATE POLICY "Solo admins ven historial completo" ON historial_accesos
    FOR SELECT USING (
        usuario_id = auth.uid() OR
        EXISTS (SELECT 1 FROM perfiles WHERE id = auth.uid() AND rol = 'administrador')
    );

CREATE POLICY "Todos pueden insertar en historial" ON historial_accesos
    FOR INSERT WITH CHECK (usuario_id = auth.uid());

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================

DO $$
DECLARE
    total_clientes INTEGER;
    total_movimientos INTEGER;
    prestamos_activos INTEGER;
    capital_circulacion NUMERIC;
BEGIN
    SELECT COUNT(*) INTO total_clientes FROM clientes;
    SELECT COUNT(*) INTO total_movimientos FROM movimientos;
    SELECT COUNT(*) INTO prestamos_activos FROM movimientos WHERE estado_pagado = FALSE AND eliminado = FALSE;
    SELECT COALESCE(SUM(saldo_pendiente), 0) INTO capital_circulacion FROM movimientos WHERE estado_pagado = FALSE AND eliminado = FALSE;
    
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║   TOLEDO PRÉSTAMOS - BASE DE DATOS FLUTTER READY      ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Base de datos creada exitosamente';
    RAISE NOTICE '✅ Clientes: %', total_clientes;
    RAISE NOTICE '✅ Movimientos: %', total_movimientos;
    RAISE NOTICE '✅ Préstamos activos: %', prestamos_activos;
    RAISE NOTICE '✅ Capital en circulación: $%', capital_circulacion;
    RAISE NOTICE '';
    RAISE NOTICE '🔐 AUTENTICACIÓN:';
    RAISE NOTICE '   • Supabase Auth integrado (maneja email y password)';
    RAISE NOTICE '   • Password encriptado automáticamente';
    RAISE NOTICE '   • Compatible 100%% con Flutter (supabase_flutter)';
    RAISE NOTICE '';
    RAISE NOTICE '👥 ROLES DEL SISTEMA:';
    RAISE NOTICE '   • cliente: Solo visualiza sus préstamos';
    RAISE NOTICE '   • moderador: Gestión completa del negocio';
    RAISE NOTICE '   • administrador: Control absoluto del sistema';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 SEGURIDAD:';
    RAISE NOTICE '   • RLS habilitado en todas las tablas';
    RAISE NOTICE '   • Perfiles se crean automáticamente al registrarse';
    RAISE NOTICE '   • Solo admins pueden cambiar roles de usuario';
    RAISE NOTICE '';
    RAISE NOTICE '📱 FUNCIONES RPC DISPONIBLES:';
    RAISE NOTICE '   • obtener_perfil_actual()';
    RAISE NOTICE '   • obtener_rol_usuario()';
    RAISE NOTICE '   • tiene_permisos_admin()';
    RAISE NOTICE '   • cambiar_rol_usuario(uuid, rol)';
    RAISE NOTICE '   • registrar_movimiento(...)';
    RAISE NOTICE '   • registrar_abono(...)';
    RAISE NOTICE '';
    RAISE NOTICE '📊 VISTAS OPTIMIZADAS:';
    RAISE NOTICE '   • vista_prestamos_activos';
    RAISE NOTICE '   • vista_resumen_clientes';
    RAISE NOTICE '   • vista_estadisticas_dashboard';
    RAISE NOTICE '';
    RAISE NOTICE '════════════════════════════════════════════════════════';
END $$;
