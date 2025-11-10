# 📦 Archivo Histórico - TPay

## 🗂️ Contenido del Directorio `.archive/`

Este directorio contiene archivos históricos del proyecto que fueron movidos durante la reorganización del 10/11/2025.

### **Estructura**
```
.archive/
├── sql_old/          ← 18+ archivos SQL históricos
└── docs_old/         ← 17+ archivos de documentación antigua
```

---

## 📄 SQL Históricos (`sql_old/`)

Archivos SQL obsoletos utilizados durante el desarrollo y debugging:

### **Políticas y Permisos RLS**
- `SUPABASE_RLS_POLICIES.sql` - Políticas de Row Level Security
- `FIX_RLS_FINAL.sql` - Fix final de RLS
- `ARREGLAR_RLS.sql` - Corrección de RLS
- `DESHABILITAR_RLS.sql` - Deshabilitación de RLS
- `FIX_PERMISOS_RAPIDO.sql` - Fix rápido de permisos
- `FIX_PERMISOS_POSTGRESQL.sql` - Fix de permisos PostgreSQL

### **Mantenimiento de Datos**
- `RESET_COMPLETO_PERFILES.sql` - Reset de tabla perfiles
- `limpiar_usuarios.sql` - Limpieza de usuarios
- `BORRAR_TODO.sql` - Script de borrado completo
- `diagnostico_usuarios.sql` - Diagnóstico de usuarios

### **Estructura y Configuración**
- `VERIFICAR_ESTRUCTURA_BD.sql` - Verificación de estructura
- `CHECK_COLUMNAS_EXISTEN.sql` - Verificación de columnas
- `AGREGAR_COLUMNAS_FALTANTES.sql` - Agregar columnas
- `bd_update_trigger.sql` - Triggers de actualización

### **Funciones y Procedimientos**
- `dar_moderador_last_user.sql` - Asignar rol moderador
- `crear_perfil_manual_rpc.sql` - Crear perfil manualmente
- `bd_funcion_supabase_fix.sql` - Fix de función Supabase

### **Versiones Antiguas**
- `bd.sql` - Versión antigua de la base de datos

**Total**: ~18 archivos SQL

---

## 📚 Documentación Antigua (`docs_old/`)

Documentación obsoleta, redundante o superada por el README.md principal:

### **Guías Técnicas**
- `TESTING_GUIDE.md` - Guía de testing (integrada en README)
- `GETTING_STARTED.md` - Guía de inicio (integrada en README)
- `CONFIGURACION_SUPABASE.md` - Configuración de Supabase
- `PLAN_INTEGRACION_SUPABASE.md` - Plan de integración

### **Documentación de Errores y Soluciones**
- `SOLUCION_ERROR_PERMISOS.md` - Solución de errores de permisos
- `DIAGNOSTICO_ERROR_PERMISOS.md` - Diagnóstico de permisos
- `GUIA_SOLUCION_COLUMNAS.md` - Guía de solución de columnas

### **Status y Progreso**
- `PROJECT_STATUS.md` - Status del proyecto (obsoleto)
- `PROGRESO_IMPLEMENTACION.md` - Progreso de implementación
- `IMPLEMENTATION_SUMMARY.md` - Resumen de implementación
- `CHANGES_SUMMARY.md` - Resumen de cambios

### **Características y Funcionalidades**
- `ADMIN_FEATURES.md` - Características de admin
- `NUEVAS_FUNCIONALIDADES.md` - Nuevas funcionalidades
- `NOTIFICACIONES_GUIA.md` - Guía de notificaciones
- `WIDGETS_MODULARES.md` - Widgets modulares
- `ACTUALIZACIONES_UI.md` - Actualizaciones de UI

### **Backups**
- `BACKUP_README.md` - Backup del README anterior

**Total**: ~17 archivos de documentación

---

## 🔄 Razón de Archivo

Estos archivos fueron movidos a `.archive/` por las siguientes razones:

1. **Consolidación**: Toda la información necesaria está ahora en:
   - `README.md` (principal)
   - `supabase_database.sql` (BD completa)
   - `database_schema.sql` (esquema)

2. **Mantenibilidad**: Reducir el desorden en la raíz del proyecto

3. **Preservación**: Mantener el historial por si se necesita referencia futura

4. **Limpieza**: Facilitar la navegación y comprensión del proyecto

---

## ⚠️ Nota Importante

**NO eliminar este directorio sin verificar primero.**

Aunque la mayoría de estos archivos son obsoletos, pueden contener información útil para:
- Debugging de problemas históricos
- Referencias de configuración antigua
- Comprensión de la evolución del proyecto
- Recuperación de datos en caso de emergencia

---

## 📅 Historial de Cambios

**10/11/2025** - Reorganización inicial
- Movidos 18+ archivos SQL de debugging/fixes
- Movidos 17 archivos .md de documentación
- Creado este archivo de referencia

---

**Para consultas sobre archivos específicos, contactar al equipo de desarrollo.**
