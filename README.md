# 📦 Control de Inventario TWS2 — Premium Edition

¡Bienvenido al sistema de **Control de Inventario TWS2**! Esta es una solución integral diseñada para gestionar existencias, movimientos de mercancía y auditoría de forma segura, elegante y eficiente.

El programa está dividido en tres grandes partes que trabajan en equipo:
1.  **Backend (El Cerebro):** Construido con Spring Boot, gestiona la base de datos y la seguridad.
2.  **Microservicio de Facturas (El Satélite):** Un servicio independiente que simula la conexión con sistemas externos de facturación.
3.  **Frontend (La Cara):** Una aplicación moderna hecha en Flutter que funciona en celulares y computadoras.

---

## 🚀 ¿Qué hace este programa? (Funcionalidades Clave)

### 1. Gestión Inteligente de Productos
- **Inventariado vs. No Inventariado:** El sistema permite marcar qué productos deben tener un control estricto de stock y cuáles son servicios (que no necesitan stock).
- **Protección de Datos:** No puedes borrar un producto "Inventariado" si todavía tiene stock físico, evitando errores contables.

### 2. Control de Stock y Movimientos
- **Entradas y Salidas:** Puedes añadir o retirar unidades fácilmente, especificando siempre el **motivo** (ej. "Compra a proveedor", "Venta directa").
- **Alertas de Stock Crítico:** El sistema te avisa visualmente cuando un producto tiene 3 unidades o menos, permitiéndote reabastecer con un solo clic.

### 3. Auditoría y Transparencia (Bitácora)
- **Historial Completo:** Cada vez que alguien crea, edita, mueve stock o borra algo, se guarda un registro con: qué se hizo, quién lo hizo y a qué hora. ¡Nada se pierde!

### 4. Papelera de Reciclaje (Soft Delete)
- Al "eliminar" un producto, este no desaparece de la base de datos. Se va a una papelera de reciclaje desde donde puedes consultarlo o **restaurarlo** si te equivocaste.

### 5. Facturación y Resiliencia
- El sistema se conecta a un microservicio de facturas. Si ese servicio falla, el backend activa un **"Circuit Breaker"** (Corta-fuegos) que protege la app y muestra un mensaje amable de mantenimiento en lugar de colapsar.

### 6. Seguridad de Grado Industrial
- **JWT (Tokens):** Solo usuarios registrados y autenticados pueden ver o modificar datos.
- **Firewall IP (Rate Limiter):** El servidor detecta y bloquea automáticamente intentos de ataque o uso excesivo desde una misma dirección IP.

---

## 🎨 Interfaz de Usuario (Experiencia Premium)

- **Modo Dual:** Soporte completo para **Modo Oscuro** (Night mode) y **Modo Claro**.
- **Diseño Responsivo:** Se adapta perfectamente si lo abres en un navegador de PC (Grilla de 4 columnas) o en un celular (Vista de lista).
- **Efectos Visuales:** Las tarjetas de productos tienen efectos de "brillo" y elevación al pasar el mouse, facilitando la navegación visual.
- **Alertas Animadas:** Los mensajes de error y confirmación son modernos, con animaciones suaves y estilo contemporáneo.

---

## 🛠️ Estructura Técnica (Para Desarrolladores)

Si deseas ver los detalles técnicos de cada componente, consulta los manuales específicos:

- [Manual Backend (Spring Boot)](file:///c:/Users/ASUS/Desktop/Control_Inventario/DocumentaciónBackend.md)
- [Manual Frontend (Flutter)](file:///c:/Users/ASUS/Desktop/Control_Inventario/DocumentaciónFrontend.md)
- [Guía de Integración Completa](file:///c:/Users/ASUS/Desktop/Control_Inventario/DocumentaciónBackendFrontend.md)

---

## 🛠️ Requisitos Rápidos para ejecución
1. **Base de Datos:** MySQL corriendo en el puerto 3306 (Base: `control_inventario`).
2. **Backend:** Java 17+ y Maven. Ejecutar en puerto 3000.
3. **Frontend:** Flutter SDK. Configurar IP en `api_config.dart`.
4. **Túnel (Opcional):** Ngrok para acceso desde el celular.

---
> **Desarrollado con ❤️ para el control total de tus activos.**
