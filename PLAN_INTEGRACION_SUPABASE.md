# 🎯 PLAN DE INTEGRACIÓN CON SUPABASE - TPay

## 📋 RESUMEN DE REQUERIMIENTOS

### 🔐 AUTENTICACIÓN Y ROLES
- ✅ Login con perfil existente (email + password)
- ✅ Registro automático crea perfil como **cliente** por defecto
- ✅ Rol NO puede cambiarse desde la app
- ✅ Solo desde BD se puede cambiar a **moderador** o **administrador**

### 👤 VISTA CLIENTE
**Permisos:**
- ❌ NO puede solicitar préstamos
- ✅ Solo VISUALIZAR sus préstamos (activos y pagados)
- ✅ Ver gráfica en **Finanzas** (Perfil → Finanzas):
  - Total pedido
  - Total pagado
  - Total por pagar (descontando abonos)

**Acciones permitidas:**
- ✅ Ver recibo de préstamo (con opción de guardar como imagen)
- ❌ NO puede abonar, editar, eliminar o marcar como pagado

### 👨‍💼 VISTA ADMINISTRADOR/MODERADOR
**Dashboard con 4 gráficas:**
1. **Capital Total** - $10,000 (100%)
2. **Capital Trabajando** - Préstamos sin pagar - abonos
3. **Capital Liberado** - Préstamos pagados + abonos
4. **Ganancia** - Intereses generados

**Movimientos:**
- ✅ Listado de 10 en 10 con paginación
- ✅ Mostrar: ID Préstamo, Cliente, Info existente
- ✅ Estado: **ACTIVO** (verde) o **FINALIZADO** (rojo)

**Registrar Préstamo:**
- ✅ Buscar cliente por **ID** o **Nombre** (scroll dropdown)
- ✅ Si nombre no existe → crear en tabla `clientes`
- ✅ Campos:
  1. Cliente (scroll option: ID / Nombre)
  2. Monto
  3. Interés (scroll option):
     - 3% mensual
     - 5% mensual
     - 10% mensual
     - Manual $ (input numérico)
  4. Fecha Inicio
  5. Fecha Pago

**Acciones en cada préstamo (5 botones):**
1. 📄 **Recibo** - Ver/Guardar como imagen con:
   - Monto
   - Interés
   - Total a Pagar
   - Deuda Actual
   - Información completa
2. ✅ **Marcar Pagado** - Abonos pasan a 0, deuda = $0
3. 💰 **Abonar** - Registrar pago parcial
4. ✏️ **Editar** - Modificar préstamo
5. 🗑️ **Eliminar** - Borrar préstamo (soft delete)

### 🧮 CALCULADORAS
**Calculadora Básica/Avanzada:**
- ✅ Funcional completa
- ✅ Básica: ± × ÷ %
- ✅ Avanzada: sin cos tan π e ( )

**Calcular Inversión:**
- ✅ Funcional completa
- ✅ Tabla año por año
- ✅ Gráfica de pastel

---

## 🗂️ ESTRUCTURA DE LA BD

### Tablas Principales:
1. **perfiles** - Usuarios del sistema (extends auth.users)
2. **clientes** - Clientes del negocio
3. **movimientos** - Préstamos registrados
4. **abonos** - Pagos parciales

### Funciones RPC:
- `obtener_perfil_actual()` - Info del usuario logueado
- `obtener_rol_usuario()` - Verificar rol
- `tiene_permisos_admin()` - Check permisos
- `registrar_movimiento(...)` - Crear préstamo
- `registrar_abono(...)` - Registrar pago

---

## 📦 ARCHIVOS A CREAR/MODIFICAR

### 1️⃣ MODELOS DE DATOS (lib/features/*/domain/entities/)
```
✅ perfil_entity.dart
✅ cliente_entity.dart
✅ movimiento_entity.dart (préstamo)
✅ abono_entity.dart
✅ estadisticas_entity.dart
```

### 2️⃣ MODELOS DE SUPABASE (lib/features/*/data/models/)
```
✅ perfil_model.dart
✅ cliente_model.dart
✅ movimiento_model.dart
✅ abono_model.dart
✅ estadisticas_model.dart
```

### 3️⃣ REPOSITORIOS (lib/features/*/data/repositories/)
```
✅ auth_repository.dart (login, register, logout)
✅ perfil_repository.dart
✅ cliente_repository.dart
✅ movimiento_repository.dart
✅ abono_repository.dart
```

### 4️⃣ CASOS DE USO (lib/features/*/domain/usecases/)
```
Auth:
✅ login_usecase.dart
✅ register_usecase.dart
✅ logout_usecase.dart
✅ get_current_user_usecase.dart

Clientes:
✅ get_clientes_usecase.dart
✅ create_cliente_usecase.dart
✅ search_cliente_usecase.dart

Movimientos:
✅ get_movimientos_usecase.dart
✅ create_movimiento_usecase.dart
✅ update_movimiento_usecase.dart
✅ delete_movimiento_usecase.dart
✅ marcar_pagado_usecase.dart

Abonos:
✅ create_abono_usecase.dart
✅ get_abonos_usecase.dart

Estadísticas:
✅ get_estadisticas_dashboard_usecase.dart
✅ get_estadisticas_cliente_usecase.dart
```

### 5️⃣ PÁGINAS A MODIFICAR
```
Auth:
✅ login_page.dart - Integrar con Supabase Auth
✅ register_page.dart - Crear nueva

Admin:
✅ admin_home_page.dart - 4 gráficas de estadísticas
✅ admin_movements_page.dart - Paginación + 5 botones
✅ create_loan_page.dart - Dropdown clientes + intereses
✅ admin_profile_page.dart - Añadir sección Finanzas

Cliente:
✅ client_home_page.dart - Nueva página
✅ client_loans_page.dart - Lista de préstamos
✅ client_profile_page.dart - Con sección Finanzas

Común:
✅ loan_receipt_page.dart - Recibo con opción guardar imagen
✅ add_payment_page.dart - Formulario abonar
```

### 6️⃣ WIDGETS A CREAR
```
✅ finance_chart_widget.dart - Gráfica finanzas cliente
✅ dashboard_stats_widget.dart - 4 gráficas admin
✅ loan_action_buttons_widget.dart - 5 botones de acción
✅ client_selector_widget.dart - Dropdown buscar cliente
✅ interest_selector_widget.dart - Dropdown intereses
```

### 7️⃣ SERVICIOS
```
✅ supabase_service.dart - Cliente Supabase configurado
✅ image_generator_service.dart - Guardar recibo como imagen
```

---

## 🔧 CONFIGURACIÓN SUPABASE

### Archivo: lib/core/config/supabase_config.dart
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'TU_SUPABASE_URL';
  static const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
}
```

---

## 🎨 CAMBIOS EN UI

### Navegación según Rol:
```
CLIENTE:
/ (splash) → /login → /client/home
  ├─ Préstamos (lista con estados)
  └─ Perfil
     └─ Finanzas (gráfica)

ADMIN/MODERADOR:
/ (splash) → /login → /admin/home
  ├─ Dashboard (4 gráficas)
  ├─ Préstamos (con 5 botones)
  ├─ Clientes
  ├─ Movimientos (paginados)
  ├─ Registrar Préstamo
  ├─ Calculadoras
  └─ Perfil
```

### Estados Visuales:
```
Cliente ve: 🟢 ACTIVO | 🔴 FINALIZADO
Admin ve: ACTIVO | FINALIZADO (texto)
```

---

## 📊 CÁLCULOS IMPORTANTES

### Capital Trabajando:
```dart
capitalTrabajando = sumaMontosActivos - sumaAbonos
```

### Capital Liberado:
```dart
capitalLiberado = sumaMontosPagados + sumaAbonos
```

### Ganancia:
```dart
ganancia = sumaInteresesPagados
```

### Deuda Actual (por préstamo):
```dart
deudaActual = (monto + interes) - abonos
```

### Interés según porcentaje:
```dart
// 3% mensual
interes = monto * 0.03 * meses

// 5% mensual
interes = monto * 0.05 * meses

// 10% mensual
interes = monto * 0.10 * meses

// Meses = días entre fecha_inicio y fecha_pago / 30
meses = (fecha_pago - fecha_inicio).inDays / 30
```

---

## 🚀 ORDEN DE IMPLEMENTACIÓN

### Fase 1: Configuración Base (30 min)
1. ✅ Configurar Supabase client
2. ✅ Crear modelos de datos
3. ✅ Crear repositorios base

### Fase 2: Autenticación (1 hora)
1. ✅ Login funcional
2. ✅ Register con rol cliente
3. ✅ Verificación de rol
4. ✅ Navegación según rol

### Fase 3: Vista Cliente (1 hora)
1. ✅ Lista de préstamos
2. ✅ Gráfica de finanzas
3. ✅ Recibo visualizable

### Fase 4: Vista Admin (2 horas)
1. ✅ Dashboard con 4 gráficas
2. ✅ Movimientos paginados
3. ✅ 5 botones de acción
4. ✅ Formulario registrar préstamo

### Fase 5: Funcionalidades Adicionales (1 hora)
1. ✅ Abonar préstamo
2. ✅ Editar préstamo
3. ✅ Marcar como pagado
4. ✅ Eliminar préstamo
5. ✅ Guardar recibo como imagen

### Fase 6: Correcciones y Pulido (30 min)
1. ✅ Validaciones
2. ✅ Mensajes de error
3. ✅ Loading states
4. ✅ Testing manual

**TIEMPO TOTAL ESTIMADO: 6 horas**

---

## 🧪 CASOS DE PRUEBA

### Login:
- [ ] Login con email existente
- [ ] Login con credenciales incorrectas
- [ ] Registro nuevo usuario → rol cliente
- [ ] Navegación según rol después de login

### Cliente:
- [ ] Ver solo sus préstamos
- [ ] Ver gráfica de finanzas correcta
- [ ] Ver recibo completo
- [ ] NO puede abonar/editar/eliminar

### Admin:
- [ ] Ver 4 gráficas con datos correctos
- [ ] Crear préstamo con cliente existente
- [ ] Crear préstamo con cliente nuevo
- [ ] Calcular interés automático (3%, 5%, 10%)
- [ ] Abonar a préstamo
- [ ] Editar préstamo
- [ ] Marcar como pagado (abonos → 0, deuda → 0)
- [ ] Eliminar préstamo
- [ ] Guardar recibo como imagen

---

## ⚠️ NOTAS IMPORTANTES

1. **Todos los números son enteros** - Sin decimales en la UI
2. **Interés automático** - Según % mensual y días del préstamo
3. **Marcar pagado** - Resetea abonos y marca deuda en 0
4. **Cliente nuevo** - Si nombre no existe, se crea automáticamente
5. **Rol cliente** - NO puede cambiarse desde app
6. **Paginación** - 10 movimientos por página
7. **Estado visual** - Verde/Rojo para cliente, texto para admin
8. **Recibo imagen** - Debe guardarse en dispositivo local

---

## 🔒 SEGURIDAD

- ✅ RLS habilitado en todas las tablas
- ✅ Clientes solo ven sus datos
- ✅ Admin/Moderador acceso completo
- ✅ Passwords encriptados por Supabase Auth
- ✅ Tokens JWT automáticos

---

¿TODO CORRECTO? 
**Confirma para empezar la implementación** 🚀
