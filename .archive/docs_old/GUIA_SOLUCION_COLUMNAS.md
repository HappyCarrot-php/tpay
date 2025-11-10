# 🔍 DIAGNÓSTICO: Estructura de Tablas

## ✅ Hallazgos en Supabase

### Tabla `clientes` - Columnas Visibles:
1. ✅ `id_cliente` (SERIAL PRIMARY KEY)
2. ✅ `usuario_id` (UUID)
3. ✅ `fecha_nacimiento` (DATE)
4. ✅ `referencias_personales` (JSONB)
5. ✅ `calificacion_cliente` (NUMERIC)
6. ✅ `activo` (BOOLEAN)
7. ✅ `creado` (TIMESTAMP) - DEFAULT CURRENT_TIMESTAMP
8. ✅ `actualizado` (TIMESTAMP) - DEFAULT CURRENT_TIMESTAMP
9. ✅ `rfc` (CHARACTER VARYING)

### ❌ Problema Identificado
La tabla tiene **solo 25 filas** visibles, pero puede haber más columnas que no se muestran en la captura. Sin embargo, **faltan columnas críticas**:

- ❌ `nombre`
- ❌ `apellido_paterno`
- ❌ `apellido_materno`
- ❌ `nombre_completo` (GENERATED)
- ❌ `telefono`
- ❌ `email`

---

## 🎯 SOLUCIÓN PASO A PASO

### **PASO 1**: Verificar si las columnas ya existen
Ejecuta el archivo `CHECK_COLUMNAS_EXISTEN.sql` en Supabase SQL Editor.

**Resultado esperado**:
- Si devuelve **6 filas** con los nombres: `nombre`, `apellido_paterno`, etc. → ✅ **Las columnas YA EXISTEN**
- Si devuelve **0 filas** → ❌ **Necesitas agregarlas**

---

### **PASO 2a**: Si las columnas NO EXISTEN
Ejecuta el archivo `AGREGAR_COLUMNAS_FALTANTES.sql` completo.

Este script hace:
```sql
ALTER TABLE clientes 
ADD COLUMN IF NOT EXISTS nombre VARCHAR(100),
ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100),
ADD COLUMN IF NOT EXISTS nombre_completo TEXT 
GENERATED ALWAYS AS (
    nombre || ' ' || apellido_paterno || ' ' || COALESCE(apellido_materno, '')
) STORED;
-- ... y más columnas
```

---

### **PASO 2b**: Si las columnas SÍ EXISTEN
El problema es con los **nombres de timestamps**. La tabla usa:
- ✅ `creado` (visto en captura)
- ✅ `actualizado` (visto en captura)

**¡Perfecto!** El código ya está actualizado para manejar esto gracias al método `_parseTimestamp()` que busca en: `creado`, `created_at`, `fecha_creacion`.

En este caso:
1. ✅ **No hagas nada más en la BD**
2. ✅ **Ejecuta solo los permisos GRANT** (ya hecho)
3. ✅ **Recarga la app**

---

### **PASO 3**: Dar permisos GRANT (si aún no lo hiciste)
```sql
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
```

---

### **PASO 4**: Probar consulta simple
```sql
SELECT COUNT(*) FROM clientes;
```
**Debe retornar**: `0` (o el número de clientes que tengas)
**Si falla**: Problema de permisos aún

---

### **PASO 5**: Insertar un cliente de prueba
```sql
INSERT INTO clientes (nombre, apellido_paterno, apellido_materno, telefono, email, activo)
VALUES ('Juan', 'Pérez', 'García', '5551234567', 'juan@test.com', true);
```

**Si falla con "columna nombre no existe"**:
→ Ejecuta `AGREGAR_COLUMNAS_FALTANTES.sql`

**Si funciona**:
→ Ahora verifica que lo puedes leer:
```sql
SELECT * FROM clientes;
```

---

## 📋 DECISIÓN RÁPIDA

### Opción A: **Tienes datos existentes en clientes**
Ejecuta primero:
```sql
SELECT COUNT(*) FROM clientes;
SELECT * FROM clientes LIMIT 1;
```

Si devuelve datos, significa que las columnas YA EXISTEN (solo que no las ves todas en la captura).

### Opción B: **La tabla está vacía (COUNT = 0)**
Perfecto! Ejecuta `AGREGAR_COLUMNAS_FALTANTES.sql` sin miedo. No perderás datos.

---

## 🚀 QUÉ HACER AHORA

### 1️⃣ Ejecuta esto en SQL Editor:
```sql
-- Ver total de columnas
SELECT COUNT(*) as total_columnas 
FROM information_schema.columns 
WHERE table_name = 'clientes';
```

### 2️⃣ Interpreta el resultado:

| Total Columnas | Acción |
|---------------|--------|
| 25+ columnas | ✅ Las columnas YA EXISTEN. Solo ejecuta permisos GRANT y recarga app |
| 8-10 columnas | ❌ Faltan columnas. Ejecuta AGREGAR_COLUMNAS_FALTANTES.sql |

### 3️⃣ Después de agregar columnas (si fue necesario):
```sql
-- Insertar cliente de prueba
INSERT INTO clientes (nombre, apellido_paterno, telefono, email, activo)
VALUES ('Test', 'Usuario', '5551234567', 'test@test.com', true)
RETURNING *;
```

### 4️⃣ Recarga la app
- Hot restart de Flutter
- Dashboard debe cargar

---

## 🎯 RESPUESTA RÁPIDA

**¿Cuántas columnas tiene la tabla clientes?**

Ejecuta:
```sql
SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'clientes';
```

- **Si es < 15**: Ejecuta `AGREGAR_COLUMNAS_FALTANTES.sql`
- **Si es >= 15**: Solo ejecuta permisos GRANT y recarga app

---

## 📊 SIGUIENTE MENSAJE

Por favor ejecuta SOLO este query y compárteme el resultado:

```sql
SELECT COUNT(*) as total_columnas 
FROM information_schema.columns 
WHERE table_name = 'clientes';
```

Con ese número sabré exactamente qué hacer a continuación.
