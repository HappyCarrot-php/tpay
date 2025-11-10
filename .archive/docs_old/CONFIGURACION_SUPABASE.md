# Configuración de Supabase para TPay

## ⚠️ IMPORTANTE: Configuración Requerida en Supabase Dashboard

Para que el registro funcione correctamente **SIN verificación de email**, debes configurar lo siguiente en el dashboard de Supabase:

### 1. Desactivar Confirmación de Email

1. Ve a tu proyecto en [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Navega a **Authentication** → **Providers** → **Email**
3. Busca la sección **"Email Confirmation"**
4. **DESACTIVA** la opción: `Enable email confirmations`
5. Guarda los cambios

### 2. Configurar Timeout de Sesión (Opcional)

1. En **Authentication** → **Settings**
2. Ajusta **JWT expiry limit** según necesites (default: 3600 segundos = 1 hora)
3. Puedes aumentarlo a 86400 (24 horas) para sesiones más largas

### 3. Verificar que las Políticas RLS estén Activas

1. Ve a **Database** → **Tables**
2. Para cada tabla (`perfiles`, `clientes`, `movimientos`, `abonos`):
   - Verifica que **RLS enabled** esté en ON
   - Asegúrate que las políticas estén creadas

### 4. Ejecutar el Script bd.sql

1. Ve a **SQL Editor**
2. Copia y pega todo el contenido de `bd.sql`
3. Haz clic en **Run**
4. Verifica que aparezca el mensaje de éxito con las estadísticas

## 🔑 Configuración de Variables de Entorno

Asegúrate de tener tu archivo `.env` en la raíz del proyecto con:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
```

**¿Dónde encontrar estas credenciales?**
1. Ve a **Settings** → **API** en tu proyecto de Supabase
2. Copia la **URL** (Project URL)
3. Copia la **anon/public key**

## 📝 Notas Importantes

### Sobre el Registro de Usuarios

- ✅ **Email es OPCIONAL**: Si no se proporciona, se genera automáticamente
- ✅ **Teléfono es OPCIONAL**: No se requiere para crear cuenta
- ✅ **Apellido Materno es OPCIONAL**: Puede dejarse vacío
- ✅ **NO se requiere verificación**: Los usuarios pueden iniciar sesión inmediatamente
- ✅ **Rol por defecto**: Todos los nuevos usuarios son `cliente`

### Campos Obligatorios para Registro

1. **Nombre** ✓
2. **Apellido Paterno** ✓
3. **Contraseña** ✓ (mínimo 6 caracteres)

### Campos Opcionales

- Email (si se proporciona, debe ser válido)
- Apellido Materno
- Teléfono

## 🛠️ Solución de Problemas

### Error: "Database error saving new user"

**Causa**: El trigger de creación de perfil falló o las políticas RLS bloquearon la inserción.

**Solución**:
1. Verifica que el trigger `trigger_crear_perfil_usuario` esté creado
2. Verifica que la política de INSERT en `perfiles` permita la creación automática
3. El código ahora crea el perfil manualmente si el trigger falla

### Error: "Email confirmations are enabled"

**Causa**: La confirmación de email está activada en Supabase.

**Solución**:
1. Ve a **Authentication** → **Providers** → **Email**
2. Desactiva `Enable email confirmations`

### Error: "User already registered"

**Causa**: El email ya está en uso.

**Solución**:
- Usa un email diferente
- O elimina el usuario existente desde **Authentication** → **Users** en el dashboard

### Error: "Invalid email format"

**Causa**: El email proporcionado no tiene formato válido.

**Solución**:
- Usa un email válido (ejemplo@dominio.com)
- O déjalo vacío para que se genere automáticamente

## 🔐 Seguridad

### Políticas RLS Configuradas

1. **Perfiles**: 
   - Los usuarios pueden ver y actualizar su propio perfil
   - Admins/Moderadores pueden ver todos los perfiles

2. **Clientes**:
   - Solo Admins/Moderadores pueden gestionar clientes
   - Los clientes solo ven sus propios datos

3. **Movimientos**:
   - Solo Admins/Moderadores pueden crear/modificar
   - Los clientes solo ven sus propios préstamos

4. **Abonos**:
   - Solo Admins/Moderadores pueden registrar pagos
   - Los clientes ven los abonos de sus préstamos

### Roles del Sistema

- **cliente**: Usuario normal, solo ve sus préstamos
- **moderador**: Puede gestionar préstamos y clientes
- **administrador**: Control total del sistema

**Para cambiar el rol de un usuario**:
```sql
-- Desde SQL Editor de Supabase
SELECT cambiar_rol_usuario('uuid-del-usuario', 'moderador');
```

## 📊 Verificar que Todo Funcione

### 1. Probar Registro

```dart
await AuthRepository().register(
  nombre: 'Ricardo',
  apellidoPaterno: 'Toledo',
  apellidoMaterno: 'Avalos', // Opcional
  telefono: '8331811916', // Opcional
  email: 'ricardo@example.com', // Opcional
  password: '123456',
);
```

### 2. Verificar Perfil Creado

En SQL Editor:
```sql
SELECT * FROM perfiles ORDER BY creado DESC LIMIT 5;
```

### 3. Probar Login

```dart
await AuthRepository().login(
  email: 'ricardo@example.com',
  password: '123456',
);
```

## 🚀 Siguientes Pasos Después de Configurar

1. ✅ Ejecutar `bd.sql` en Supabase
2. ✅ Desactivar confirmación de email
3. ✅ Configurar `.env` con credenciales
4. ✅ Probar registro desde la app
5. ✅ Verificar que el perfil se cree correctamente
6. ✅ Probar login con el usuario creado

---
**Última actualización**: Noviembre 2025  
**Estado**: ✅ Registro funcional sin verificación de email
