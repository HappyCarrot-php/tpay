-- =====================================================
-- SOLUCIÓN DEFINITIVA: Dar todos los permisos necesarios
-- =====================================================
-- Ejecuta este script completo en SQL Editor de Supabase
-- Esto da permisos a nivel PostgreSQL (no RLS)
-- =====================================================

-- PASO 1: Dar permisos al rol 'authenticated' (usuarios logueados)
-- =====================================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- PASO 2: Dar permisos al rol 'anon' (API pública)
-- =====================================================
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO anon;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;

-- PASO 3: Dar permisos explícitos a tablas específicas
-- =====================================================
GRANT ALL ON clientes TO authenticated;
GRANT ALL ON movimientos TO authenticated;
GRANT ALL ON abonos TO authenticated;
GRANT ALL ON perfiles TO authenticated;
GRANT ALL ON historial_accesos TO authenticated;

GRANT SELECT, INSERT, UPDATE ON clientes TO anon;
GRANT SELECT, INSERT, UPDATE ON movimientos TO anon;
GRANT SELECT, INSERT, UPDATE ON abonos TO anon;
GRANT SELECT, INSERT, UPDATE ON perfiles TO anon;

-- PASO 4: Dar permisos a sequences (para IDs autoincrementales)
-- =====================================================
GRANT USAGE, SELECT ON SEQUENCE clientes_id_cliente_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE clientes_id_cliente_seq TO anon;

GRANT USAGE, SELECT ON SEQUENCE movimientos_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE movimientos_id_seq TO anon;

GRANT USAGE, SELECT ON SEQUENCE abonos_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE abonos_id_seq TO anon;

-- PASO 5: Establecer permisos por defecto para futuras tablas
-- =====================================================
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT ALL ON TABLES TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT SELECT, INSERT, UPDATE ON TABLES TO anon;

-- =====================================================
-- VERIFICACIÓN
-- =====================================================
-- Ejecuta esto para verificar que los permisos se aplicaron:

-- Ver permisos en tabla clientes
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name='clientes'
ORDER BY grantee, privilege_type;

-- Ver estado de RLS
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('clientes', 'movimientos', 'abonos', 'perfiles');

-- Probar SELECT
SELECT COUNT(*) FROM clientes;
SELECT COUNT(*) FROM movimientos;
SELECT COUNT(*) FROM abonos;

-- =====================================================
-- RESULTADO ESPERADO:
-- =====================================================
-- Deberías ver:
-- - 'authenticated' y 'anon' con permisos SELECT, INSERT, UPDATE, DELETE
-- - rowsecurity = false (RLS desactivado)
-- - Los COUNT(*) deben ejecutarse sin error (aunque devuelvan 0)
--
-- Después de ejecutar esto, RECARGA LA APP y debería funcionar
-- =====================================================
