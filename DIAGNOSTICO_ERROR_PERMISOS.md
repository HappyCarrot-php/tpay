# 🔍 DIAGNÓSTICO: Error de Permisos Persiste

## Estado Actual
- ✅ RLS desactivado en Supabase
- ❌ Error persiste: "permission denied for table clientes"
- ✅ Código actualizado con manejo flexible de columnas timestamp

## 🎯 Posibles Causas

### 1. **El nombre de la tabla está mal**
- Verificar si la tabla se llama `clientes` o `cliente`
- Verificar si hay mayúsculas: `Clientes`, `CLIENTES`

### 2. **La tabla no existe en el schema público**
- La tabla puede estar en otro schema (no `public`)

### 3. **El usuario no tiene permisos GRANT**
- Aunque RLS esté desactivado, el usuario puede no tener SELECT permission

### 4. **El anon key está bloqueado**
- El API key anon puede estar restringido

---

## 🧪 QUERIES DE DIAGNÓSTICO

### Ejecuta estos queries UNO POR UNO en Supabase SQL Editor:

### 1️⃣ Verificar que la tabla existe
```sql
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name = 'clientes'
);
```
**Resultado esperado**: `true`
**Si es false**: La tabla no existe con ese nombre

---

### 2️⃣ Ver TODAS las tablas disponibles
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```
**Busca**: ¿Está `clientes` en la lista? ¿O se llama diferente?

---

### 3️⃣ Ver el estado de RLS
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('clientes', 'movimientos', 'abonos', 'perfiles');
```
**Resultado esperado**: `rowsecurity = false` (RLS desactivado)

---

### 4️⃣ Verificar permisos del usuario
```sql
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name='clientes';
```
**Busca**: ¿Aparece `anon` o `authenticated` con `SELECT`?

---

### 5️⃣ GRANT permisos manualmente (SOLUCIÓN)
Si los permisos no están, ejecútalos:

```sql
-- Dar todos los permisos a usuarios autenticados
GRANT ALL ON clientes TO authenticated;
GRANT ALL ON movimientos TO authenticated;
GRANT ALL ON abonos TO authenticated;
GRANT ALL ON perfiles TO authenticated;

-- Dar permisos de lectura al usuario anon
GRANT SELECT ON clientes TO anon;
GRANT SELECT ON movimientos TO anon;
GRANT SELECT ON abonos TO anon;
GRANT SELECT ON perfiles TO anon;
```

---

### 6️⃣ Intentar SELECT directo
```sql
SELECT COUNT(*) FROM clientes;
```
**Si falla**: El problema es de permisos a nivel PostgreSQL
**Si funciona**: El problema es con el API key o la conexión desde Flutter

---

### 7️⃣ Ver columnas de la tabla clientes
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'clientes'
ORDER BY ordinal_position;
```
**Busca columnas importantes**:
- `id_cliente` (debe existir)
- `nombre_completo` (debe existir)
- `created_at` o `creado` (para timestamps)

---

## 🔧 SOLUCIONES RÁPIDAS

### Solución A: Dar permisos explícitos
```sql
-- Ejecuta esto en SQL Editor
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
```

### Solución B: Verificar API Key
1. Ve a **Settings** → **API** en Supabase Dashboard
2. Copia el **anon key** (público)
3. Verifica que coincida con el que tienes en `supabase_constants.dart`

Tu key actual:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0YXlva29wZ2F1bGludWxra2JmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2OTM4MzYsImV4cCI6MjA3ODI2OTgzNn0.S56hklAapHCNcbe5i7hDsqxVUA71opnq0Wt0tUhdaDU
```

### Solución C: Recrear la tabla con permisos correctos
```sql
-- SOLO si todo lo demás falla
-- CUIDADO: Esto borra los datos

DROP TABLE IF EXISTS clientes CASCADE;

CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    usuario_id UUID REFERENCES auth.users(id),
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100) NOT NULL,
    apellido_materno VARCHAR(100),
    nombre_completo TEXT GENERATED ALWAYS AS (
        nombre || ' ' || apellido_paterno || ' ' || COALESCE(apellido_materno, '')
    ) STORED,
    telefono VARCHAR(20),
    email VARCHAR(255),
    rfc VARCHAR(13),
    curp VARCHAR(18),
    fecha_nacimiento DATE,
    direccion TEXT,
    ciudad VARCHAR(100),
    estado VARCHAR(100),
    codigo_postal VARCHAR(10),
    identificacion_tipo VARCHAR(50),
    identificacion_numero VARCHAR(100),
    foto_url TEXT,
    calificacion_cliente DECIMAL(3,2),
    notas TEXT,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dar permisos
GRANT ALL ON clientes TO authenticated;
GRANT SELECT ON clientes TO anon;
```

---

## 📊 QUÉ HACER AHORA

1. **Ejecuta los queries 1-4** para diagnosticar
2. **Ejecuta la Solución A** (GRANT ALL) para dar permisos
3. **Recarga la app**
4. **Si funciona**: Continúa con testing
5. **Si NO funciona**: Manda captura de pantalla de los resultados de los queries

---

## 🎯 ACTUALIZACIÓN DEL CÓDIGO

He modificado 2 archivos para manejar nombres flexibles de columnas:

### `cliente_model.dart`
- Ahora busca timestamps en: `creado`, `created_at`, `fecha_creacion`
- Si no encuentra ninguno, usa `DateTime.now()`

### `movimiento_model.dart`
- Mismo manejo flexible de timestamps

Esto evita errores si tus columnas se llaman `created_at` en lugar de `creado`.

---

## 📝 RESULTADO ESPERADO

Después de ejecutar la Solución A (GRANT), deberías ver:
- ✅ Dashboard carga con KPIs (aunque sean 0)
- ✅ No más error "permission denied"
- ✅ Gráficas se muestran (vacías si no hay datos)

---

**Siguiente paso**: Ejecuta los queries de diagnóstico y comparte los resultados si el problema persiste.
