# SAV — Frontend (Flutter)

App **Flutter (web)** del **Sistema de Alquiler de Vehículos — AutoRent Perú**.
Consume la API Node.js (`sav_backend`) por HTTP con **JWT**. El menú **ramifica por rol**:
Cliente · Asesor de Ventas · Cajero · Jefe de Logística · Mecánico · Administrador.

---

## 1. Stack

| Área | Tecnología |
|------|-----------|
| Framework | Flutter / Dart (build **web**) |
| Estado | `provider` (ChangeNotifier) |
| HTTP | `http` + `ApiClient` (inyecta el Bearer token) |
| Despliegue | Render (Static Site, `build/web` prebuilt) |

---

## 2. Organización (`lib/`)

```
lib/
├── main.dart              Punto de entrada + Provider (estado global)
├── theme.dart             Tema visual (blanco y negro)
├── config/
│   └── api_config.dart    URL del backend (--dart-define=API_URL)
├── models/                Clases de dominio
│   ├── usuario.dart · cliente.dart · vehiculo.dart
│   ├── cotizacion.dart · reserva.dart · seguro.dart
│   ├── repuesto.dart · orden_mantenimiento.dart
├── services/              Un servicio por módulo del backend (ver §3)
│   ├── api_client.dart          HTTP + JWT (base de todos)
│   ├── auth_service.dart        /api/auth
│   ├── ventas_service.dart      /api/ventas   (cotización)
│   ├── alquiler_service.dart    /api/alquiler (reservas, pagos, caja)
│   ├── gestion_service.dart     /api/gestion  (flota, precios, clientes, seguros)
│   └── mantenimiento_service.dart  /api/mantenimiento
├── state/
│   └── auth_controller.dart     Sesión (usuario + rol) con ChangeNotifier
├── widgets/
│   └── estado_chip.dart         Chip reutilizable de estado
└── views/                 Pantallas, agrupadas por rol
    ├── login_screen.dart
    ├── menu_screen.dart              Menú principal según rol
    ├── cliente/                      (Cliente)
    │   ├── catalogo_screen.dart
    │   ├── detalle_vehiculo_screen.dart
    │   ├── mis_cotizaciones_screen.dart
    │   └── mis_reservas_screen.dart
    ├── asesor/                       (Asesor de Ventas)
    │   └── cotizaciones_screen.dart
    ├── gestion/                      (Administrador / Cajero / Asesor)
    │   ├── vehiculos_admin_screen.dart   CRUD flota (Admin)
    │   ├── precios_screen.dart           Lista de precios (Admin)
    │   ├── clientes_admin_screen.dart    CRUD cliente (Asesor/Admin)
    │   ├── seguros_screen.dart           Seguros + por vencer (Admin)
    │   └── reservas_internas_screen.dart Reservas + acciones del Cajero
    ├── ordenes_list_screen.dart      (Mantenimiento) lista + filtro
    ├── orden_detail_screen.dart      detalle + acciones por rol/estado
    ├── crear_orden_screen.dart       (Jefe) crear OM
    ├── vehiculos_screen.dart         (Jefe) vehículos por mantener
    ├── repuestos_screen.dart         catálogo de repuestos
    └── dialogs/                      formularios del flujo de mantenimiento
        ├── inspeccion_dialog.dart · requerimiento_dialog.dart
        ├── presupuesto_dialog.dart · decision_dialog.dart · informe_dialog.dart
```

**Flujo de datos:** `view → service → ApiClient → backend`.
La sesión vive en `AuthController` (provider); el token JWT lo guarda `ApiClient` y se
inyecta en cada petición.

---

## 3. Servicios → endpoints que consumen

| Servicio | Base | Métodos principales |
|----------|------|---------------------|
| `AuthService` | `/api/auth` | `login`, `me` |
| `VentasService` | `/api/ventas` | generar/listar cotización, solicitar garantía, generar reserva, decidir, pagar garantía |
| `AlquilerService` | `/api/alquiler` | `catalogo`, `disponibilidad`, `misReservas`, `listarTodas`, `pagarAlquiler`, `cancelar`, **`devolverGarantia`**, **`gestionarCancelacion`**, **`emitirComprobante`**, **`comprobantes`** |
| `GestionService` | `/api/gestion` | CRUD vehículos, `actualizarPrecioVehiculo`, CRUD clientes, seguros (crear/renovar/por-vencer) |
| `MantenimientoService` | `/api/mantenimiento` | órdenes, inspección, requerimiento, presupuesto, iniciar/finalizar, informe, conformidad |

> **Nuevo (Cajero):** en la pantalla **Reservas** (`views/gestion/reservas_internas_screen.dart`)
> el Cajero ve acciones según el estado de la reserva:
> - **CONFIRMADA** → *Registrar pago de alquiler*, *Gestionar cancelación*
> - **EN_CURSO** → *Devolver garantía* (con deducciones), *Emitir comprobante*, *Gestionar cancelación*
> - **FINALIZADA / CANCELADA** → *Emitir comprobante* / *Ver comprobantes*

---

## 4. Vistas por rol (menú)

| Rol | Accede a |
|-----|----------|
| **Cliente** | Catálogo, detalle, mis cotizaciones, mis reservas |
| **Asesor de Ventas** | Cotizaciones, CRUD cliente |
| **Cajero** | Reservas (pagos, devolución de garantía, cancelación, comprobantes) |
| **Jefe de Logística** | Órdenes de mantenimiento, vehículos por mantener |
| **Mecánico** | Órdenes asignadas (inspección, presupuesto, ejecución, informe) |
| **Administrador** | Vehículos, precios, seguros, clientes |

---

## 5. Puesta en marcha (local)

1. Ten el backend corriendo (`sav_backend`, `npm start`) en `http://localhost:3000`.
2. Instala dependencias y ejecuta apuntando al backend:

```bash
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

> La URL del backend se inyecta con `--dart-define=API_URL=...` y se lee en
> `config/api_config.dart` (por defecto `http://localhost:3000`).

**Usuarios de prueba:** ver el README del backend (uno por rol; p. ej. `cajero@autorent.pe / cajero123`).

---

## 6. Build y despliegue (Render)

El sitio se despliega como **Static Site** con el `build/web` **prebuilt** (versionado en el repo).
Para publicar cambios:

```bash
flutter build web --release --dart-define=API_URL=https://backend-sav-mantenimiento.onrender.com
git add -A && git commit -m "build web"
git push origin main      # Render redespliega automáticamente
```

- **Publish directory** en Render: `build/web`.
- URL de producción: `https://sav-6hs3.onrender.com`.

---

## 7. Calidad

```bash
flutter analyze     # sin issues
flutter test        # pruebas base
```
