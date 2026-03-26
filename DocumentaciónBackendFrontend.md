# 📚 Documentación Técnica — Control de Inventario TWS2

> **Autor:** Alexis Ramírez  
> **Fecha:** 2026-03-25  
> **Tecnologías:** Spring Boot 3.2.4 (WebFlux) + Flutter 3.x + MySQL + Resilience4j  
> **Arquitectura:** BFF (Backend For Frontend) + Microservicio Satélite

---

## 📐 Arquitectura General

```
┌──────────────────────────────────────────────────────────────────┐
│                       FLUTTER FRONTEND                          │
│            (Puerto dinámico — Android/Web/Desktop)               │
│                                                                  │
│  ┌──────────┐  ┌──────────────┐  ┌────────────┐  ┌───────────┐ │
│  │  Auth     │  │  Producto    │  │ Historial  │  │ Factura   │ │
│  │ Provider  │  │  Provider    │  │  Provider  │  │ Provider  │ │
│  └────┬─────┘  └─────┬────────┘  └─────┬──────┘  └─────┬─────┘ │
│       │              │                 │                │       │
│       └──────────────┴─────────────────┴────────────────┘       │
│                              │                                   │
│                   HTTP + Bearer Token                            │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │   NGROK TUNNEL      │
                    │   (Puerto 3000)     │
                    └──────────┬──────────┘
                               │
         ┌─────────────────────▼─────────────────────────┐
         │            BACKEND PRINCIPAL                   │
         │         Spring Boot WebFlux                    │
         │              (Puerto 3000)                     │
         │                                                │
         │  ┌────────────────┐  ┌───────────────────┐    │
         │  │ IpRateLimiter  │  │  SecurityConfig   │    │
         │  │   WebFilter    │  │  (JWT + CORS)     │    │
         │  └───────┬────────┘  └───────────────────┘    │
         │          │                                     │
         │  ┌───────▼───────────────────────────────┐    │
         │  │           CONTROLLERS                  │    │
         │  │  Auth │ Producto │ Historial │ Factura │    │
         │  └───────┬───────────────────────┬────────┘    │
         │          │                       │             │
         │  ┌───────▼──────┐   ┌────────────▼──────────┐ │
         │  │ ProductoSvc  │   │ FacturaIntegrationSvc │ │
         │  │ (JPA MySQL)  │   │ (WebClient + CB)      │ │
         │  └──────────────┘   └────────────┬──────────┘ │
         │                                  │             │
         └──────────────────────────────────┼─────────────┘
                                            │
                              HTTP (localhost:8081)
                                            │
                    ┌───────────────────────▼─────────────┐
                    │     MICROSERVICIO SATELLITE         │
                    │     facturas_service                │
                    │     Spring Boot WebFlux             │
                    │          (Puerto 8081)              │
                    │                                     │
                    │    FacturaController                │
                    │    GET /facturas (datos ficticios)  │
                    └─────────────────────────────────────┘
```

---

## 🗄️ Base de Datos MySQL

**Nombre:** `control_inventario`

### Tabla: `productos`
| Campo | Tipo | Restricciones |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| nombre | VARCHAR(255) | NOT NULL |
| descripcion | TEXT | — |
| precioUnitarioVenta | DOUBLE | NOT NULL |
| precioUnitarioCompra | DOUBLE | NOT NULL |
| cantidadEnStock | INT | NOT NULL, DEFAULT 0 |
| createdAt | DATETIME | NOT NULL |
| updatedAt | DATETIME | — |
| deletedAt | DATETIME | NULL (soft delete) |

### Tabla: `usuarios`
| Campo | Tipo | Restricciones |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| nombre | VARCHAR(255) | NOT NULL, UNIQUE |
| password | VARCHAR(255) | NOT NULL (BCrypt) |
| rol | VARCHAR(255) | NOT NULL (ADMIN / VISTA) |
| createdAt | DATETIME | NOT NULL |
| updatedAt | DATETIME | — |

### Tabla: `historial`
| Campo | Tipo | Restricciones |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| accion | VARCHAR(255) | NOT NULL |
| detalles | VARCHAR(255) | NOT NULL |
| usuarioId | BIGINT | NOT NULL (FK lógica) |
| createdAt | DATETIME | NOT NULL |
| updatedAt | DATETIME | — |

### Tabla: `movimientos_inventario`
| Campo | Tipo | Restricciones |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| tipoMovimiento | VARCHAR(255) | NOT NULL (ENTRADA/SALIDA) |
| cantidad | INT | NOT NULL |
| motivo | VARCHAR(255) | — |
| productoId | BIGINT | NOT NULL (FK lógica) |
| usuarioId | BIGINT | NOT NULL (FK lógica) |
| createdAt | DATETIME | NOT NULL |
| updatedAt | DATETIME | — |

---

## 🔗 Mapa de Rutas Backend → Frontend

### Autenticación (`/api/auth`)
| Método | Ruta Backend | Frontend (Dart) | Descripción |
|---|---|---|---|
| POST | `/api/auth/login` | `AuthService.login()` → `AuthProvider` | Autenticación con JWT |
| POST | `/api/auth/registrar` | `AuthService.register()` → `AuthProvider` | Registro de usuario |

### Productos (`/api`)
| Método | Ruta Backend | Frontend (Dart) | Descripción |
|---|---|---|---|
| GET | `/api/obtener/productos` | `ProductoService.getProductos()` → `ProductoProvider` | Listar productos activos |
| POST | `/api/crear/producto` | `ProductoService.addProducto()` → `ProductoProvider` | Crear producto nuevo |
| PUT | `/api/actualizar/producto/{id}` | `ProductoService.updateProducto()` → `ProductoProvider` | Editar producto |
| DELETE | `/api/eliminar/producto/{id}` | `ProductoService.deleteProducto()` → `ProductoProvider` | Soft delete (papelera) |
| POST | `/api/{id}/entrada` | `ProductoService.updateStock()` → `ProductoProvider` | Entrada de stock |
| POST | `/api/{id}/salida` | `ProductoService.updateStock()` → `ProductoProvider` | Salida de stock |
| GET | `/api/obtener/borrados` | `ProductoService.getProductosBorrados()` → `ProductoProvider` | Listar papelera |
| PUT | `/api/restaurar/producto/{id}` | `ProductoService.restaurarProducto()` → `ProductoProvider` | Restaurar de papelera |

### Historial (`/api`)
| Método | Ruta Backend | Frontend (Dart) | Descripción |
|---|---|---|---|
| GET | `/api/historial` | `HistorialService.getHistorial()` → `HistorialProvider` | Bitácora de auditoría |

### Facturación BFF (`/api`)
| Método | Ruta Backend (Gateway) | Ruta Microservicio | Frontend (Dart) | Descripción |
|---|---|---|---|---|
| GET | `/api/facturas` | `localhost:8081/facturas` | `FacturaProvider.loadFacturas()` | Facturas con Circuit Breaker |

---

## 🛡️ Seguridad y Resiliencia

### JWT (JSON Web Tokens)
- **Generación:** `JwtUtil.generateToken()` al hacer login
- **Validación:** `SecurityContextRepository` intercepta cada request
- **Expiración:** 24 horas (86400000ms)
- **Rutas públicas:** `/api/auth/login`, `/api/auth/registrar`
- **Todas las demás rutas:** Requieren `Authorization: Bearer <token>`

### Rate Limiter por IP (`IpRateLimiterFilter`)
- **Aplica a:** Peticiones SIN token Bearer (usuarios no autenticados)
- **Bypass:** Usuarios logueados con token válido pasan libremente
- **Bloqueo temporal:** > 10 peticiones en 60s → `429 Too Many Requests`
- **Bloqueo permanente:** ≥ 100 peticiones acumuladas → `403 Forbidden`
- **Almacenamiento:** `ConcurrentHashMap` en memoria

### Circuit Breaker (Resilience4j)
- **Servicio protegido:** Comunicación con `facturas_service` (puerto 8081)
- **Ventana deslizante:** 3 llamadas
- **Umbral de fallo:** 50%
- **Espera en estado OPEN:** 15 segundos
- **Fallback:** Retorna mensaje de mantenimiento (HTTP 503)

---

## 📁 Estructura del Proyecto

### Backend Principal (`backend_spring/`)
```
src/main/java/com/inventario/tws2/
├── InventarioApplication.java          # Punto de entrada Spring Boot
├── config/
│   ├── DataSeeder.java                 # Seed de datos iniciales (usuario admin)
│   └── IpRateLimiterFilter.java        # Firewall reactivo por IP
├── controller/
│   ├── AuthController.java             # Login y registro de usuarios
│   ├── ProductoController.java         # CRUD de productos e inventario
│   ├── HistorialController.java        # Bitácora de auditoría
│   ├── InventarioFacturasController.java # Gateway BFF de facturas
│   └── GlobalExceptionHandler.java     # Manejo global de excepciones
├── dto/
│   ├── AuthRequest.java                # DTO: login (nombre, password)
│   ├── AuthResponse.java              # DTO: respuesta con token + usuario
│   ├── RegistrarRequest.java          # DTO: registro con rol
│   └── StockMovimientoRequest.java    # DTO: entrada/salida de stock
├── model/
│   ├── Producto.java                   # Entidad JPA: productos
│   ├── Usuario.java                    # Entidad JPA: usuarios
│   ├── Historial.java                  # Entidad JPA: bitácora
│   └── MovimientoInventario.java       # Entidad JPA: movimientos
├── repository/
│   ├── ProductoRepository.java         # JPA Repository de productos
│   ├── UsuarioRepository.java          # JPA Repository de usuarios
│   ├── HistorialRepository.java        # JPA Repository de historial
│   └── MovimientoInventarioRepository.java # JPA Repository de movimientos
├── security/
│   ├── JwtUtil.java                    # Generación y validación de tokens
│   ├── JwtAuthenticationManager.java   # Manager de autenticación
│   ├── SecurityConfig.java            # Configuración de seguridad WebFlux
│   └── SecurityContextRepository.java  # Extrae token del header
└── service/
    ├── ProductoService.java            # Lógica de negocio de productos
    └── FacturaIntegrationService.java  # WebClient + Circuit Breaker
```

### Microservicio Satélite (`facturas_service/`)
```
src/main/java/com/facturas/tws2/
├── FacturasApplication.java            # Punto de entrada (puerto 8081)
└── FacturaController.java              # Endpoint reactivo con datos ficticios
```

### Frontend Flutter (`frontend_app/lib/`)
```
lib/
├── main.dart                           # Punto de entrada + ThemeProvider
├── core/
│   ├── api_config.dart                 # URL base del backend (Ngrok)
│   └── app_theme.dart                  # Paleta dual: claro/oscuro
├── models/
│   ├── producto.dart                   # Modelo Producto (fromJson/toJson)
│   ├── usuario.dart                    # Modelo Usuario
│   └── historial.dart                  # Modelo Historial
├── providers/
│   ├── auth_provider.dart              # Estado global de autenticación
│   ├── producto_provider.dart          # Estado global de productos
│   ├── historial_provider.dart         # Estado global de historial
│   ├── factura_provider.dart           # Estado global de facturas + polling
│   └── theme_provider.dart             # Toggle modo claro/oscuro
├── services/
│   ├── auth_service.dart               # HTTP: login/registro
│   ├── producto_service.dart           # HTTP: CRUD productos
│   └── historial_service.dart          # HTTP: obtener bitácora
└── ui/screens/
    ├── login_screen.dart               # Pantalla de login
    └── dashboard_screen.dart           # Dashboard principal (5 vistas)
```

---

## 🚀 Ejecución del Sistema

### 1. Backend Principal (Puerto 3000)
```bash
cd backend_spring
mvn spring-boot:run
```

### 2. Microservicio Facturas (Puerto 8081)
```bash
cd facturas_service
mvn spring-boot:run
```

### 3. Túnel Ngrok (para móvil)
```bash
ngrok http 3000
```
> Actualizar la URL en `frontend_app/lib/core/api_config.dart`

### 4. Frontend Flutter
```bash
cd frontend_app
flutter run
```

---

## 🔄 Flujo de Conexión: Frontend → Backend → Microservicio

### Flujo Normal de Productos
```
Flutter (ProductoProvider) 
  → HTTP GET /api/obtener/productos (con Bearer Token)
  → Ngrok Tunnel (HTTPS → localhost:3000)
  → IpRateLimiterFilter (bypass: tiene Bearer Token ✅)
  → SecurityContextRepository (valida JWT ✅)
  → ProductoController.obtenerProductos()
  → ProductoService.obtenerProductos()
  → ProductoRepository.findByDeletedAtIsNull() (JPA → MySQL)
  → Response: List<Producto> (JSON)
  → Flutter actualiza UI con notifyListeners()
```

### Flujo de Facturas con Circuit Breaker
```
Flutter (FacturaProvider — polling cada 3s)
  → HTTP GET /api/facturas (con Bearer Token)
  → Backend: InventarioFacturasController.obtenerFacturas()
  → FacturaIntegrationService.obtenerFacturas()
  → @CircuitBreaker(name="facturasService")
  │
  ├─ SI microservicio UP (puerto 8081):
  │   → WebClient.get().uri("/facturas").retrieve()
  │   → FacturaController.obtenerFacturasDummy() 
  │   → Response: 200 OK + List<Factura>
  │   → Flutter muestra tarjetas de facturas
  │
  └─ SI microservicio DOWN:
      → CircuitBreaker activa fallback
      → facturasFallback() → {"mensaje": "...mantenimiento..."}
      → Response: 503 Service Unavailable
      → Flutter: facturas.clear() + muestra pantalla mantenimiento
      → Auto-recuperación cuando servicio revive (polling detecta 200)
```

### Flujo de Rate Limiting (ataque sin token)
```
Atacante (navegador directo, sin login)
  → HTTP GET /api/crear/producto (SIN Bearer Token)
  → IpRateLimiterFilter:
  │   → authHeader == null → NO bypass
  │   → Incrementa contador IP
  │
  ├─ Peticiones 1-10: → 200/401 (depende de la ruta)
  ├─ Peticiones 11-99: → 429 Too Many Requests (bloqueo temporal 60s)
  └─ Petición 100+: → 403 Forbidden (bloqueo permanente)
```

---

## 🎨 Sistema de Temas

| Propiedad | Modo Oscuro | Modo Claro |
|---|---|---|
| Scaffold | `#0D1B22` | `#F0F5F2` |
| AppBar | `#0F2230 → #162E42` | `#4A8C6E → #3A7A5E` |
| Cards | Vidrio semitransparente | Blanco puro |
| Texto principal | `Colors.white` | `#1A2730` |
| Texto secundario | `Colors.white70` | `#5A7080` |
| Acento (sage) | `#8ECBA8` | `#4A8C6E` |
| Drawer | `#132030` | `Colors.white` |

---

## ⚙️ Configuraciones Clave

### `application.yml` (Backend Principal)
```yaml
server.port: 3000
spring.datasource.url: jdbc:mysql://localhost:3306/control_inventario
jwt.secret: [clave de 512 bits]
jwt.expiration: 86400000  # 24 horas

resilience4j.circuitbreaker.instances.facturasService:
  slidingWindowSize: 3
  failureRateThreshold: 50
  waitDurationInOpenState: 15s
  permittedNumberOfCallsInHalfOpenState: 2
```

### `application.yml` (Microservicio Facturas)
```yaml
server.port: 8081
```

### `api_config.dart` (Frontend)
```dart
class ApiConfig {
  static const String baseUrl = 'https://<ngrok-url>/api';
}
```
