# 🧪 Guía de Testing End-to-End - TPay

## 📊 Estado del Proyecto

**✅ COMPLETADO (100%)**
- ✅ Arquitectura de datos (Entities, Models, Repositories)
- ✅ CreateLoanPage con búsqueda y creación inline de clientes
- ✅ LoanActionButtons (5 botones funcionales con seguridad)
- ✅ AdminDashboardPage con estadísticas reales y gráficas
- ✅ AdminClientsPage con lista y edición completa
- ✅ Errores de compilación corregidos (0 errores)

**🎯 Objetivo**: Probar el flujo completo de gestión de préstamos

---

## 🔐 Prerequisitos

### 1. Base de Datos Supabase
Asegúrate de que las siguientes tablas existan y tengan datos:

```sql
-- Verificar tablas
SELECT * FROM clientes LIMIT 5;
SELECT * FROM movimientos LIMIT 5;
SELECT * FROM abonos LIMIT 5;
SELECT * FROM perfiles LIMIT 5;
```

### 2. Usuario de Prueba
Crear un usuario moderador/administrador en Supabase Auth:
- Email: `test@tpay.com`
- Password: `Test123456`
- Rol en tabla `perfiles`: `administrador` o `moderador`

---

## 🧭 Flujo de Testing Completo

### **Paso 1: Login y Navegación**

1. **Iniciar la aplicación**
   ```bash
   flutter run
   ```

2. **Login**
   - Email: `test@tpay.com`
   - Password: `Test123456`
   - ✅ Verificar: Redirección a AdminHomePage

3. **Navegar al Dashboard**
   - ✅ Ver 3 KPIs: Clientes, Activos, Pagados
   - ✅ Ver gráfica de estado de préstamos (Pie Chart)
   - ✅ Ver gráfica de montos (Bar Chart)
   - ✅ Ver tasa de recuperación (Gauge Chart)
   - ✅ Ver métricas de clientes
   - 🔄 Probar botón "Refresh" en AppBar

---

### **Paso 2: Ver Lista de Clientes**

1. **Ir a pestaña "Clientes"** (Bottom Navigation)
   - ✅ Ver lista de clientes con:
     - Avatar con iniciales
     - Nombre completo
     - ID del cliente
     - Email y teléfono
     - Contador de préstamos activos

2. **Probar búsqueda**
   - Buscar por ID: `1`
   - Buscar por nombre: `Juan`
   - Buscar por email: `@example.com`
   - ✅ Verificar que el contador de resultados funcione

3. **Editar un cliente**
   - Tap en cualquier cliente
   - Modificar nombre, apellidos, email, teléfono
   - Agregar RFC y CURP
   - ✅ Click "Guardar Cambios"
   - ✅ Verificar SnackBar de éxito
   - ✅ Verificar que los cambios se reflejen en la lista

4. **Desactivar cliente**
   - Editar un cliente sin préstamos activos
   - Click en ícono de eliminar (AppBar)
   - ✅ Confirmar diálogo de desactivación
   - ✅ Verificar que el cliente desaparezca de la lista

---

### **Paso 3: Registrar Nuevo Préstamo**

1. **Abrir Drawer**
   - ☰ Menu → "Registrar Préstamo"

2. **Buscar cliente existente**
   - Escribir ID: `1` o nombre: `Juan`
   - ✅ Ver dropdown con resultados filtrados
   - ✅ Seleccionar cliente
   - ✅ Ver card verde con cliente seleccionado

3. **Crear cliente nuevo (inline)**
   - Escribir nombre que NO existe: `Carlos Nuevo Pérez`
   - ✅ Ver card naranja "Crear Nuevo Cliente"
   - ✅ Verificar auto-completado en campos (Carlos → Nombre, Nuevo → Apellido Paterno, Pérez → Apellido Materno)
   - Agregar teléfono: `5512345678`
   - Agregar email: `carlos@test.com`

4. **Llenar datos del préstamo**
   - Monto: `10000`
   - Interés: `1500`
   - Fecha Inicio: Hoy
   - Fecha Pago: +30 días
   - ✅ Verificar cálculo automático de días (debe mostrar "30 días")
   - Notas: `Préstamo de prueba`

5. **Guardar préstamo**
   - ✅ Click "Guardar Préstamo"
   - ✅ Ver loading en botón
   - ✅ Ver SnackBar verde "Préstamo registrado exitosamente"
   - ✅ Verificar redirección automática

---

### **Paso 4: Ver Préstamo en Lista de Movimientos**

1. **Ir a pestaña "Préstamos"**
   - ✅ Ver el préstamo recién creado en la lista
   - ✅ Verificar datos:
     - ID del préstamo
     - Nombre del cliente (del JOIN)
     - Monto, Interés, Total
     - Abonos: $0
     - Saldo Pendiente: $11,500
     - Estado: Activo
     - Fecha de pago

2. **Probar filtros**
   - Cambiar a "Todos"
   - Cambiar a "Activos"
   - Cambiar a "Pagados"
   - Cambiar a "Vencidos"
   - ✅ Verificar que el contador de resultados sea correcto

3. **Probar búsqueda**
   - Buscar por ID de préstamo
   - Buscar por ID de cliente
   - Buscar por nombre de cliente
   - ✅ Verificar resultados filtrados

---

### **Paso 5: Probar 5 Botones de Acción**

#### **5.1 Botón RECIBO**
1. Click en ícono de recibo (primer botón)
2. ✅ Ver dialog con toda la información:
   - ID, Cliente, Monto, Interés, Total, Abonos, Saldo, Estado
3. ✅ Ver botón "Descargar PDF" (placeholder)
4. Cerrar dialog

#### **5.2 Botón ABONAR**
1. Click en botón "$" (Abonar)
2. Llenar formulario:
   - Monto: `5000`
   - Método de Pago: `Efectivo`
   - Notas: `Primer abono`
3. ✅ Click "Registrar Abono"
4. ✅ Ver SnackBar "Abono registrado exitosamente"
5. ✅ Verificar que Abonos cambió de $0 a $5,000
6. ✅ Verificar que Saldo Pendiente cambió de $11,500 a $6,500

#### **5.3 Botón EDITAR**
1. Click en ícono de editar (lápiz)
2. Modificar datos:
   - Cambiar Monto: `12000`
   - Cambiar Interés: `1800`
   - Cambiar Fecha de Pago: +60 días
   - Modificar Notas: `Préstamo editado`
3. ✅ Click "Guardar Cambios"
4. ✅ Ver SnackBar de éxito
5. ✅ Verificar que Total cambió a $13,800
6. ✅ Verificar que Saldo Pendiente se recalculó correctamente

#### **5.4 Botón ABONAR (Segunda vez)**
1. Realizar otro abono de `6500` (el saldo restante)
2. ✅ Verificar que Saldo Pendiente = $0
3. ✅ Verificar que el estado cambia a "Pagado" automáticamente
4. ✅ Verificar notificación de préstamo completado

#### **5.5 Botón MARCAR PAGADO**
1. Crear un nuevo préstamo de prueba
2. Click en botón de check (Marcar Pagado)
3. ✅ Ver dialog de confirmación
4. Confirmar
5. ✅ Verificar que Abonos se establezcan en $0 (según requerimiento)
6. ✅ Verificar que Estado = Pagado
7. ✅ Verificar notificación al admin

#### **5.6 Botón ELIMINAR (con password)**
1. Click en botón de eliminar (basura roja)
2. ✅ Ver container rojo de advertencia
3. Llenar formulario:
   - Motivo: `Préstamo duplicado por error`
   - Password: `Test123456` (password del moderador)
4. ✅ Click "Eliminar Préstamo"
5. ✅ Ver mensaje de confirmación
6. ✅ Verificar que el préstamo desaparece de la lista (soft delete)

**⚠️ CASO DE ERROR: Password Incorrecta**
1. Intentar eliminar con password incorrecta
2. ✅ Ver SnackBar rojo "Contraseña incorrecta"
3. ✅ Verificar que el préstamo NO se eliminó

---

### **Paso 6: Verificar Integridad de Datos**

1. **Volver al Dashboard**
   - ✅ Verificar que los KPIs se actualizaron
   - ✅ Verificar que las gráficas reflejan los cambios

2. **Volver a Clientes**
   - ✅ Verificar que el contador de "préstamos activos" sea correcto
   - ✅ Verificar que el cliente creado aparece en la lista

3. **Probar RefreshIndicator**
   - Pull-to-refresh en cada pantalla
   - ✅ Verificar que los datos se recargan

---

## 🧪 Casos de Prueba Adicionales

### **Test de Validaciones**

1. **CreateLoanPage**
   - ❌ Intentar guardar sin seleccionar cliente
   - ❌ Intentar guardar con monto = 0
   - ❌ Intentar guardar con interés negativo
   - ❌ Crear cliente nuevo sin nombre
   - ❌ Crear cliente nuevo sin apellido paterno

2. **LoanActionButtons - Abonar**
   - ❌ Intentar abonar $0
   - ❌ Intentar abonar más del saldo pendiente
   - ❌ Intentar abonar número negativo

3. **AdminClientsPage - Editar**
   - ❌ Dejar nombre vacío
   - ❌ Dejar apellido paterno vacío
   - ❌ Email con formato incorrecto
   - ❌ Teléfono con menos de 10 dígitos

---

## 📊 Verificación en Base de Datos

Después de completar el flujo, verificar en Supabase:

```sql
-- Verificar cliente creado
SELECT * FROM clientes WHERE email = 'carlos@test.com';

-- Verificar préstamo creado
SELECT * FROM movimientos WHERE id_cliente = [ID_CLIENTE];

-- Verificar abonos registrados
SELECT * FROM abonos WHERE id_movimiento = [ID_PRESTAMO];

-- Verificar que saldo_pendiente se calculó correctamente
SELECT 
  id,
  monto,
  interes,
  abonos,
  saldo_pendiente,
  (monto + interes - abonos) as calculo_manual
FROM movimientos
WHERE id = [ID_PRESTAMO];

-- Verificar soft delete
SELECT * FROM movimientos WHERE eliminado = true;
```

---

## ✅ Checklist Final

- [ ] Login exitoso como administrador/moderador
- [ ] Dashboard muestra estadísticas reales
- [ ] Lista de clientes carga correctamente
- [ ] Búsqueda de clientes funciona
- [ ] Editar cliente actualiza datos
- [ ] Desactivar cliente funciona (soft delete)
- [ ] Registrar préstamo con cliente existente
- [ ] Crear cliente nuevo inline
- [ ] Préstamo aparece en lista de movimientos
- [ ] Botón Recibo muestra información completa
- [ ] Botón Abonar registra abonos correctamente
- [ ] Saldo pendiente se recalcula automáticamente
- [ ] Botón Editar actualiza préstamo
- [ ] Botón Marcar Pagado funciona correctamente
- [ ] Botón Eliminar solicita password
- [ ] Password incorrecta rechaza eliminación
- [ ] Password correcta elimina (soft delete)
- [ ] Notificaciones se envían correctamente
- [ ] RefreshIndicator recarga datos
- [ ] KPIs y gráficas se actualizan

---

## 🐛 Reporte de Bugs

Si encuentras algún bug durante el testing, documentarlo aquí:

### Formato:
```
**Bug #X**: [Título breve]
**Ubicación**: [Página/Widget]
**Pasos para reproducir**:
1. ...
2. ...
**Comportamiento esperado**: ...
**Comportamiento actual**: ...
**Prioridad**: Alta/Media/Baja
```

---

## 🎉 ¡Testing Completado!

Si todos los checks están marcados, el sistema está listo para producción.

**Próximos pasos**:
1. Documentar API
2. Configurar CI/CD
3. Preparar para deployment
4. Capacitar usuarios finales
