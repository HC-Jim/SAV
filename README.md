# AutoRent Perú — Frontend (Flutter)

App **Flutter** del módulo **Gestión de Órdenes de Mantenimiento**. Consume la API
Node.js (`sav_backend`) por HTTP. Actores: **Jefe de Logística** y **Mecánico**.

## Arquitectura (por capas)

```
lib/
├── main.dart              Punto de entrada + Provider (estado global)
├── theme.dart             Tema visual y colores por estado
├── config/                api_config.dart  (URL del backend)
├── models/                Clases de dominio: Usuario, Vehiculo, Repuesto,
│                          OrdenMantenimiento (+ Inspeccion, Presupuesto, ...)
├── services/              api_client (HTTP+JWT) · auth_service · mantenimiento_service
├── state/                 auth_controller (ChangeNotifier)
├── widgets/               EstadoChip (componente reutilizable)
└── views/                 Pantallas
    ├── login_screen.dart
    ├── menu_screen.dart          menú principal según rol
    ├── ordenes_list_screen.dart  lista + filtro por estado
    ├── orden_detail_screen.dart  detalle + acciones contextuales
    ├── crear_orden_screen.dart   (Jefe) crear OM
    ├── vehiculos_screen.dart     (Jefe) vehículos por mantener
    ├── repuestos_screen.dart     catálogo de repuestos
    └── dialogs/                  formularios de cada acción del flujo
```

Flujo de datos: **view → service → ApiClient → backend**. El estado de sesión
vive en `AuthController` (provider); el token JWT lo guarda `ApiClient` y se
inyecta en cada petición.

## Puesta en marcha

1. Ten el backend corriendo (`sav_backend`, `npm start`) en `http://localhost:3000`.
2. Instala dependencias y ejecuta:

```bash
flutter pub get
flutter run -d chrome
```

### Apuntar a otra URL de API

La URL por defecto es `http://localhost:3000`. Para cambiarla sin tocar código:

```bash
flutter run -d chrome --dart-define=API_URL=https://tu-servicio.onrender.com
```

- **Emulador Android:** usa `--dart-define=API_URL=http://10.0.2.2:3000`.

## Usuarios de prueba

| Rol | Correo | Contraseña |
|-----|--------|-----------|
| Jefe de Logística | `jefe@autorent.pe` | `jefe123` |
| Mecánico | `mecanico@autorent.pe` | `mecanico123` |

## Acciones por rol y estado

- **Jefe:** crear orden · comprar repuestos · autorizar/rechazar presupuesto ·
  dar conformidad / rechazar conformidad.
- **Mecánico:** registrar inspección · requerimiento de repuestos ·
  generar presupuesto · iniciar/finalizar mantenimiento · generar informe.

La app muestra en cada orden **solo** las acciones válidas para tu rol y el
estado actual (el backend las vuelve a validar con su máquina de estados).

## Despliegue web en Render

```bash
flutter build web --release --dart-define=API_URL=https://tu-backend.onrender.com
```

Publica la carpeta `build/web` como **Static Site** en Render.
