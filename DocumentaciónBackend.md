# ⚙️ Guía Técnica: Backend Spring Boot (WebFlux)

Este es el núcleo lógico del sistema **Control de Inventario TWS2**. Está diseñado bajo una arquitectura reactiva no bloqueante para maximizar el rendimiento y la escalabilidad.

---

## 🏗️ Stack Tecnológico
- **Framework:** Spring Boot 3.2.4 (Spring WebFlux)
- **Base de Datos:** MySQL 8.0
- **Seguridad:** Spring Security (JWT Stateless)
- **Documentación:** OpenAPI / Swagger (Opcional)
- **Resiliencia:** Resilience4j (Circuit Breaker)

---

## 🔒 Arquitectura de Seguridad (Firewall Niveles)

### Nivel 1: IP Rate Limiter (`IpRateLimiterFilter`)
Ubicado en `@Order(-101)`, se ejecuta antes de cualquier lógica. Protege al servidor de ataques de denegación de servicio (DoS) y fuerza bruta.
- **Lógicas:**
    - Detecta IP real vía `X-Forwarded-For`.
    - Permite hasta **10 peticiones/min** sin token.
    - Bloqueo permanente tras **100 peticiones** sospechosas.
- **Excepción:** Si la petición trae un Bearer Token válido, el filtro se salta automáticamente para no afectar al usuario legítimo.

### Nivel 2: JWT (JSON Web Tokens)
Implementado de forma reactiva.
- **Autenticación:** El `JwtAuthenticationManager` valida la firma del token enviado en el header `Authorization`.
- **Autorización:** Define rutas públicas (`/api/auth/**`) y rutas protegidas que requieren un token firmado con una clave secreta de 512 bits.

---

## 📦 Capa de Modelo y Negocio

### Entidad: `Producto`
Campos clave:
- `inventariado (boolean)`: Define si el producto sigue reglas estrictas de stock.
- `cantidadEnStock (int)`: Balance actual.
- `deletedAt (datetime)`: Soporte para **Soft Delete**.

### Servicio: `ProductoService`
Contiene la lógica pesada:
- **Validación de Eliminación:** Lanza una excepción si se intenta borrar un producto inventariado con stock > 0.
- **Gestión de Stock:** Asegura que no se retire más stock del existente (en operaciones de salida).
- **Audit Logging:** Cada acción llama al repositorio de historial para persistir la bitácora.

---

## 📡 Integración BFF (Facturas Gateway)
El backend actúa como un **BFF (Backend For Frontend)** para el microservicio de facturas.
- **WebClient:** Utiliza un cliente reactivo para consumir `facturas_service` (puerto 8081).
- **Circuit Breaker:** Protege la comunicación. Si el servicio de facturas falla, el backend responde un mensaje de mantenimiento (Fallback) para que el frontend no se quede "colgado".

---

## 📁 Endpoints Principales

| Categoría | Ruta | Descripción |
|---|---|---|
| **Auth** | `/api/auth/login` | Recibe nombre/password, devuelve Token + Usuario. |
| **Auth** | `/api/auth/registrar` | Registra nuevos usuarios (Admin/Vista). |
| **CRUD** | `/api/obtener/productos` | Filtra solo los productos cuya columna `deletedAt` es NULL. |
| **Stock** | `/api/{id}/entrada` | Incrementa stock y registra movimiento. |
| **Stock** | `/api/{id}/salida` | Decrementa stock y valida disponibilidad. |
| **Papelera** | `/api/obtener/borrados` | Recupera productos con `deletedAt` NOT NULL. |
| **Facturas** | `/api/facturas` | Proxy reactivo hacia el microservicio satélite. |

---
> **Nota:** La base de datos se genera automáticamente (`ddl-auto: update`) al arrancar la aplicación si se tiene configurado el acceso en `application.yml`.
