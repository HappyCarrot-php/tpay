# 🚨 SOLUCIÓN INMEDIATA: Error de Permisos en Supabase

## 🔍 Diagnóstico del Error

El error que estás viendo:
```
Error al obtener clientes: PostgrestException(message: permission denied for table clientes, code: 42501, details: Forbidden, hint: null)
```

**Causa**: Las tablas de Supabase tienen RLS (Row Level Security) activado pero NO tienen políticas configuradas, por lo que NADIE puede acceder a los datos.

---

## ✅ SOLUCIÓN RÁPIDA (2 minutos)

### Paso 1: Abre Supabase Dashboard
1. Ve a [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto: `ktayokopgaulinulkkbf`
3. En el menú lateral, haz clic en **"SQL Editor"**

### Paso 2: Desactiva RLS Temporalmente
Copia y pega este código en el SQL Editor y haz clic en **"Run"**:

```sql
ALTER TABLE clientes DISABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos DISABLE ROW LEVEL SECURITY;
ALTER TABLE abonos DISABLE ROW LEVEL SECURITY;
ALTER TABLE perfiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE historial_accesos DISABLE ROW LEVEL SECURITY;
```

### Paso 3: Verifica en la App
1. Cierra y vuelve a abrir la app
2. El Dashboard ahora debería cargar correctamente

---

## 🔐 SOLUCIÓN SEGURA (5 minutos) - Recomendada después de verificar

Una vez que confirmes que la app funciona, activa RLS de nuevo con políticas permisivas:

### Paso 1: Activa RLS
```sql
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE abonos ENABLE ROW LEVEL SECURITY;
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
```

### Paso 2: Crea Políticas Permisivas
```sql
-- CLIENTES
CREATE POLICY "allow_all_authenticated_clientes"
ON clientes FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- MOVIMIENTOS
CREATE POLICY "allow_all_authenticated_movimientos"
ON movimientos FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- ABONOS
CREATE POLICY "allow_all_authenticated_abonos"
ON abonos FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- PERFILES
CREATE POLICY "allow_all_authenticated_perfiles"
ON perfiles FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');
```

Estas políticas permiten que **cualquier usuario autenticado** pueda:
- Ver todos los datos (SELECT)
- Crear registros (INSERT)
- Actualizar registros (UPDATE)
- Eliminar registros (DELETE)

---

## 📂 Archivos Creados

He creado 2 archivos SQL en tu proyecto:

1. **`FIX_PERMISOS_RAPIDO.sql`** 
   - Solución rápida con 3 opciones
   - Incluye comandos para desactivar/activar RLS
   - Incluye políticas permisivas

2. **`SUPABASE_RLS_POLICIES.sql`** 
   - Políticas granulares por rol (admin, moderador, cliente)
   - Para implementar cuando quieras seguridad avanzada
   - 150+ líneas con políticas detalladas

---

## 🎯 Qué Hacer AHORA

### Opción A: Solo quiero que funcione YA (1 minuto)
1. Abre **SQL Editor** en Supabase
2. Ejecuta:
   ```sql
   ALTER TABLE clientes DISABLE ROW LEVEL SECURITY;
   ALTER TABLE movimientos DISABLE ROW LEVEL SECURITY;
   ALTER TABLE abonos DISABLE ROW LEVEL SECURITY;
   ```
3. Recarga la app

### Opción B: Quiero seguridad básica (3 minutos)
1. Abre el archivo **`FIX_PERMISOS_RAPIDO.sql`**
2. Copia toda la sección **"OPCIÓN 3"**
3. Pégala en el SQL Editor de Supabase
4. Haz clic en **"Run"**
5. Recarga la app

### Opción C: Quiero seguridad avanzada por roles (10 minutos)
1. Abre el archivo **`SUPABASE_RLS_POLICIES.sql`**
2. Copia y pega en el SQL Editor
3. Ejecuta todo el script
4. **IMPORTANTE**: Asegúrate de tener un registro en `perfiles` con rol 'administrador'
5. Recarga la app

---

## 🐛 Si Aún No Funciona

### Verifica que tienes un perfil de administrador:

```sql
-- 1. Obtén tu UUID de usuario
SELECT auth.uid();

-- 2. Verifica si tienes un perfil
SELECT * FROM perfiles WHERE id = auth.uid();

-- 3. Si NO existe, créalo (reemplaza 'TU_UUID' con el resultado del paso 1)
INSERT INTO perfiles (id, rol, nombre, email)
VALUES ('TU_UUID', 'administrador', 'Admin', 'tu@email.com');
```

---

## 📊 Verificar Políticas Creadas

Para ver todas las políticas activas:

```sql
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('clientes', 'movimientos', 'abonos', 'perfiles')
ORDER BY tablename;
```

---

## ⚠️ IMPORTANTE

- **RLS DESACTIVADO** = Sin seguridad, todos ven todo (solo para desarrollo local)
- **RLS ACTIVADO con políticas permisivas** = Usuarios autenticados ven todo (OK para testing)
- **RLS ACTIVADO con políticas por rol** = Seguridad granular (recomendado para producción)

---

## 🚀 Siguiente Paso

Una vez que la app cargue correctamente:
1. ✅ Verifica que el Dashboard muestre los KPIs
2. ✅ Verifica que puedas ver la lista de clientes
3. ✅ Verifica que puedas crear un préstamo
4. ✅ Continúa con el testing según **TESTING_GUIDE.md**

---

**¿Necesitas ayuda?** 
Si después de ejecutar la OPCIÓN A (desactivar RLS) aún no funciona, el problema es otro (probablemente estructura de tablas o nombres de columnas).
