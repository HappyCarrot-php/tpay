-- =====================================================
-- POLÍTICAS RLS (Row Level Security) PARA TPAY
-- =====================================================
-- Ejecuta este script en el SQL Editor de Supabase
-- para configurar los permisos correctamente
-- =====================================================

-- PASO 1: HABILITAR RLS EN TODAS LAS TABLAS
-- =====================================================
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE abonos ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_accesos ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICAS PARA TABLA: perfiles
-- =====================================================

-- Política: Los usuarios pueden ver su propio perfil
CREATE POLICY "Los usuarios pueden ver su propio perfil"
ON perfiles FOR SELECT
USING (auth.uid() = id);

-- Política: Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Los usuarios pueden actualizar su propio perfil"
ON perfiles FOR UPDATE
USING (auth.uid() = id);

-- Política: Los admins pueden ver todos los perfiles
CREATE POLICY "Los admins pueden ver todos los perfiles"
ON perfiles FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- Política: Los admins pueden actualizar cualquier perfil
CREATE POLICY "Los admins pueden actualizar cualquier perfil"
ON perfiles FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol = 'administrador'
  )
);

-- Política: Insertar perfil al registrarse (público)
CREATE POLICY "Insertar perfil al registrarse"
ON perfiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- =====================================================
-- POLÍTICAS PARA TABLA: clientes
-- =====================================================

-- Política: Los admins y moderadores pueden ver todos los clientes
CREATE POLICY "Admins y moderadores pueden ver todos los clientes"
ON clientes FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- Política: Los clientes solo pueden ver su propio registro
CREATE POLICY "Los clientes pueden ver su propio registro"
ON clientes FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol = 'cliente'
    AND auth.uid() = clientes.usuario_id
  )
);

-- Política: Los admins y moderadores pueden insertar clientes
CREATE POLICY "Admins y moderadores pueden insertar clientes"
ON clientes FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- Política: Los admins y moderadores pueden actualizar clientes
CREATE POLICY "Admins y moderadores pueden actualizar clientes"
ON clientes FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- Política: Los admins pueden eliminar clientes (soft delete)
CREATE POLICY "Admins pueden desactivar clientes"
ON clientes FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol = 'administrador'
  )
);

-- =====================================================
-- POLÍTICAS PARA TABLA: movimientos
-- =====================================================

-- Política: Los admins y moderadores pueden ver todos los movimientos
CREATE POLICY "Admins y moderadores pueden ver todos los movimientos"
ON movimientos FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- Política: Los clientes solo pueden ver sus propios movimientos
CREATE POLICY "Los clientes pueden ver sus propios movimientos"
ON movimientos FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM perfiles p
    INNER JOIN clientes c ON c.usuario_id = p.id
    WHERE p.id = auth.uid() 
    AND p.rol = 'cliente'
    AND c.id_cliente = movimientos.id_cliente
  )
);

-- Política: Los admins y moderadores pueden insertar movimientos
CREATE POLICY "Admins y moderadores pueden insertar movimientos"
ON movimientos FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- Política: Los admins y moderadores pueden actualizar movimientos
CREATE POLICY "Admins y moderadores pueden actualizar movimientos"
ON movimientos FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- Política: Los admins pueden eliminar movimientos (soft delete)
CREATE POLICY "Admins pueden eliminar movimientos"
ON movimientos FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- =====================================================
-- POLÍTICAS PARA TABLA: abonos
-- =====================================================

-- Política: Los admins y moderadores pueden ver todos los abonos
CREATE POLICY "Admins y moderadores pueden ver todos los abonos"
ON abonos FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- Política: Los clientes pueden ver sus propios abonos
CREATE POLICY "Los clientes pueden ver sus propios abonos"
ON abonos FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM perfiles p
    INNER JOIN clientes c ON c.usuario_id = p.id
    INNER JOIN movimientos m ON m.id_cliente = c.id_cliente
    WHERE p.id = auth.uid() 
    AND p.rol = 'cliente'
    AND m.id = abonos.id_movimiento
  )
);

-- Política: Los admins y moderadores pueden insertar abonos
CREATE POLICY "Admins y moderadores pueden insertar abonos"
ON abonos FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- Política: Los admins y moderadores pueden actualizar abonos
CREATE POLICY "Admins y moderadores pueden actualizar abonos"
ON abonos FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol IN ('administrador', 'moderador')
  )
);

-- =====================================================
-- POLÍTICAS PARA TABLA: historial_accesos
-- =====================================================

-- Política: Los admins pueden ver todo el historial
CREATE POLICY "Los admins pueden ver todo el historial"
ON historial_accesos FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid() AND rol = 'administrador'
  )
);

-- Política: Los usuarios pueden ver su propio historial
CREATE POLICY "Los usuarios pueden ver su propio historial"
ON historial_accesos FOR SELECT
USING (auth.uid() = usuario_id);

-- Política: Todos pueden insertar en historial (para registrar accesos)
CREATE POLICY "Todos pueden insertar en historial"
ON historial_accesos FOR INSERT
WITH CHECK (auth.uid() = usuario_id);

-- =====================================================
-- VERIFICACIÓN DE POLÍTICAS
-- =====================================================
-- Ejecuta esto para verificar que las políticas se crearon correctamente:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
-- FROM pg_policies 
-- WHERE schemaname = 'public' 
-- ORDER BY tablename, policyname;

-- =====================================================
-- NOTAS IMPORTANTES:
-- =====================================================
-- 1. Después de ejecutar este script, verifica que el usuario
--    que inició sesión tenga un registro en la tabla 'perfiles'
--    con el rol correcto (administrador, moderador, cliente)
--
-- 2. Si el error persiste, verifica que auth.uid() retorna
--    un valor válido ejecutando: SELECT auth.uid();
--
-- 3. Para testing inicial, puedes DESACTIVAR temporalmente RLS:
--    ALTER TABLE clientes DISABLE ROW LEVEL SECURITY;
--    ALTER TABLE movimientos DISABLE ROW LEVEL SECURITY;
--    (NO RECOMENDADO EN PRODUCCIÓN)
--
-- 4. Asegúrate de que el usuario que inició sesión tenga un
--    perfil creado con: INSERT INTO perfiles (id, rol) 
--    VALUES ('USER_UUID', 'administrador');
-- =====================================================
