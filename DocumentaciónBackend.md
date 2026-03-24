# Documentación del Backend: Control de Inventario

Esta documentación describe la arquitectura, componentes y flujo de datos del servidor backend, desarrollado con **Node.js, Express.js y Sequelize (ORM)** conectándose a una base de datos MySQL.

## 1. Arquitectura del Proyecto (`/server`)
El servidor sigue de manera estricta el patrón **MVC** (Modelos, Vistas, Controladores), omitiendo las vistas clásicas ya que expone interactuando directamente como una **API REST**.

```text
/server
├── src/
│   ├── app.js               # Punto de entrada principal (Entry point)
│   ├── config/              # Configuraciones globales (Conexión a BD)
│   ├── controllers/         # Lógica de negocio (Cerebro de la API)
│   ├── middlewares/         # Filtros de seguridad e interceptores
│   ├── models/              # Esquemas de Base de Datos (Sequelize)
│   └── routes/              # Endpoints (URLs expuestas a internet)
└── package.json             # Dependencias (Express, jsonwebtoken, etc.)
```

---

## 2. Modelos (`/models`)
Los modelos representan la estructura matemática de nuestras tablas en MySQL.
- **`Usuario.js`**: Define a los administradores y operadores. Encripta las contraseñas y define el campo `rol` (ENUM: `ADMIN`, `CONTROL`).
- **`Producto.js`**: El núcleo del sistema. Guarda `nombre`, `descripcion`, `precioUnitarioCompra`, `precioUnitarioVenta` y la `cantidadEnStock`.
- **`Historial.js`**: Modelo de Auditoría. Guarda cada acción (`CREACION`, `ENTRADA`, `ELIMINACION`, etc.), quién la hizo (`usuarioId`) y los detalles exactos en texto.
- **`MovimientoInventario.js`**: (Complementario) Lleva un registro más duro sobre los flujos numéricos exactos de existencias para reportes contables.

*(Sequelize se encarga de crear y vincular estas tablas automáticamente gracias al comando `sync({ alter: true })` en el `app.js`).*

---

## 3. Controladores (`/controllers`)
El cerebro de la aplicación. Aquí se procesa todo antes de mandarlo a la base de datos.
- **`AuthController.js`**: 
  - `login`: Busca al usuario, verifica la contraseña (Bcrypt) y, si es correcta, firma y devuelve un **Token JWT** para sesiones seguras.
- **`ProductoController.js`**:
  - `crearProducto` / `obtenerProductos`: Métodos clásicos de CRUD.
  - `agregarStock` / `despacharStock`: Métodos críticos usando **Transacciones de SQL**. Garantizan que si ocurre un error de red al sumar el stock, la base de datos revierte todo (_rollback_) para que no haya inventarios fantasma. Además, inyectan silenciosamente un log en el *Historial*.
  - `actualizarProducto` / `eliminarProducto`: Acciones protegidas y auditadas.
- **`HistorialController.js`**:
  - `obtenerHistorial`: Extrae la bitácora uniendo la tabla de `Historial` con la tabla de `Usuario` (para saber el nombre) y los ordena de más reciente a más antiguo (`DESC`).

---

## 4. Middleware de Seguridad (`/middlewares`)
- **`authMiddleware.js`**: 
  - `verificarToken`: Intercepta cualquier petición web. Revisa los `Headers` buscando el token JWT. Si es falso o expiró, rechaza la conexión con `Error 401`.
  - `verificarRol`: Intercepta la petición y revisa si el token pertenece a un `ADMIN`. Si es un simple `USER`, devuelve un `Error 403 (No Autorizado)` impidiendo borrar o crear productos irreales.

---

## 5. Rutas y Endpoints (`/routes`)
Las puertas de enlace que el Frontend llama a través de llamadas HTTP (`GET`, `POST`, `PUT`, `DELETE`).

### Rutas Claves (Expuestas de forma privada):
* `POST /api/auth/login` -> Para autenticación.
* `GET /api/obtener/productos` -> Lista el catálogo abierto.
* `POST /api/crear/producto` -> [Solo ADMIN] Ingresa nuevo ítem.
* `PUT /api/editar/producto/:id` -> [Solo ADMIN] Refactoriza precios/descripción.
* `DELETE /api/eliminar/producto/:id` -> [Solo ADMIN] Da de baja definitiva.
* `POST /api/:id/entrada` -> Agrega stock físico (Ej: Compra de mercadería).
* `POST /api/:id/salida` -> Resta stock físico (Ej: Ventas al cliente).
* `GET /api/historial` -> Muestra toda la data de la bitácora.
