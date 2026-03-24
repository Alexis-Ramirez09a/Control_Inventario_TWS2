# Documentación del Frontend: Flutter Inventario (TWS2)

Esta documentación enmarca la aplicación lado cliente (Frontend), construida con **Flutter** utilizando los principios de **Arquitectura Limpia (Clean Architecture)** y **Gestión de Estado (Provider)** para aplicaciones móviles y web de alto rendimiento.

## 1. Arquitectura del Proyecto (`/frontend_app/lib`)
El proyecto está estratificado por componentes específicos de responsabilidad única:

```text
/lib
├── core/                # Variables y Constantes universales (api_config)
├── models/              # Moldes de Clases (Traducción JSON a Dart)
├── providers/           # Gestores de Estado Global interconectados al UI
├── services/            # Clientes HTTP (Conectividad directa con Node.js)
├── ui/screens/          # Planos Visuales interactivos (Componentes UI)
└── main.dart            # Inyector de dependencias multihilo y tema raíz.
```

---

## 2. Modelos (`/models`)
Son traductores rápidos (`factory fromJson`) que convierten el texto recibido desde la Base de Datos a objetos tipados en Dart para evitar errores tontos de nulos (`NullSafety`).
- **`usuario.dart`**: Modela a la entidad que inicia sesión (almacena nombre, ID, rol).
- **`producto.dart`**: Representa un ítem gráfico del inventario (nombre, stock matemático, precios).
- **`historial.dart`**: Traduce la fecha de MySQL a formato "DateTime" local de tu país, además de manejar colores dinámicos.

---

## 3. Servicios (`/services`)
Actúan como "cables" invisibles que viajan a internet. Cada servicio representa un contexto de tu negocio.
- **`auth_service.dart`**: Envía credenciales al backend y, si es correcto, devuelve el ansiado Token JWT de sesión.
- **`producto_service.dart`**: Contiene métodos complejos como `addStock` o `deleteProduct`. Encripta el Token de seguridad en el `Headers { Authorization: Bearer ... }` antes de golpear al servidor de Ngrok.
- **`historial_service.dart`**: Recupera el volcado completo de la bitácora de auditoría. *(Incluye headers `ngrok-skip-browser-warning` para evadir bloqueos de CORS).*

---

## 4. Gestores de Estado (`/providers`)
Aquí es donde reside la "Inteligencia Artificial" reactiva de tu programa (Uso de la librería `ChangeNotifier`).
- **`auth_provider.dart`**: Mantiene en memoria (`RAM`) si estás logueado o no. Si oprimes "Cerrar Sesión", borra el token y despacha un aviso general para echarte al menú principal.
- **`producto_provider.dart` y `historial_provider.dart`**: Cuando la Base de Datos cambia en el backend, estos proveedores recogen las respuestas asincrónicas HTTP, actualizan Arrays internos (Listas) y llaman al método secreto `notifyListeners()`. Esto hace que las pantallas de tu celular cambien mágicamente sin tener que refrescar la App manualmente.

---

## 5. Diseño e Interfaces Visuales (`/ui/screens`)

### A. `login_screen.dart`
- **Técnica UX:** Diseño `Glassmorphism` inmersivo.
- Realiza validaciones en el formulario en vivo sin dejarte introducir contraseñas vacías, conectándose en paralelo a `AuthProvider` para intentar arrancar tu sesión.

### B. `dashboard_screen.dart`
El componente más inmersivo de la aplicación. Integra tecnología **Mobile-First** con Responsive Flex (vía `LayoutBuilder`).
Tiene una estructura de "Cajón Oculto" (`Drawer`) que aloja un menú lateral. Se particiona matemáticamente en 3 vistas controladas por una variable de estado local (`_indiceActual`):

#### Vista 0: "Resumen General"
- Itera asíncronamente sobre todas las listas de MongoDB para calcular y sumar instantáneamente valores económicos como si fuera un modelo en Excel ($12,800.00 dólares en activo material).
- Se contrae verticalmente en el smartphone, pero horizontalmente como "Dash" en Web/Edge.

#### Vista 1: "Inventario Detallado" (El CRUD)
- Una pasarela de listas optimizada consumiendo `ListView.builder` para no saturar memoria RAM si tienes 5,000 productos.
- Lógica de Roles oculta: Solo renderiza los botones de "Edición" y "Eliminación absoluta" verificando que `usuario?.rol == 'ADMIN'`.

#### Vista 2: "Historial y Auditoría"
- La terminal de logs gráfica. Utiliza una banda de elementos de estado visual `FilterChip` que interceptan el listado bruto y purgan visualmente acciones que no empaten (Ej: Ocultar los de 'CREACION' y mostrar solo 'ELIMINACION').
- Recurre al paquete `lucide_icons` asignando constantes numéricas Hexadecimales (Colors) basado en condicionales `switch (acción)`.
