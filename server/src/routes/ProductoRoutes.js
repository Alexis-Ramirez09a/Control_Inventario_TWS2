const express = require('express');
const router = express.Router();
const productoController = require('../controllers/ProductoController');
const { verificarToken, verificarRol } = require('../middlewares/authMiddleware');

// Control y Admin pueden crear, ver y actualizar
router.post('/crear/producto', verificarToken, verificarRol(['ADMIN', 'CONTROL']), productoController.crearProducto);
router.get('/obtener/productos', verificarToken, verificarRol(['ADMIN', 'CONTROL']), productoController.obtenerProductos);
router.put('/actualizar/producto/:id', verificarToken, verificarRol(['ADMIN', 'CONTROL']), productoController.actualizarProducto);

// Solo Admin puede eliminar (borrado lógico)
router.delete('/eliminar/producto/:id', verificarToken, verificarRol(['ADMIN']), productoController.eliminarProducto);

// Entradas y salidas de inventario
router.post('/:id/entrada', verificarToken, verificarRol(['ADMIN', 'CONTROL']), productoController.agregarStock);
router.post('/:id/salida', verificarToken, verificarRol(['ADMIN', 'CONTROL']), productoController.despacharStock);

// Papelera de Reciclaje Lógica
router.get('/obtener/borrados', verificarToken, verificarRol(['ADMIN']), productoController.obtenerProductosBorrados);
router.put('/restaurar/producto/:id', verificarToken, verificarRol(['ADMIN']), productoController.restaurarProducto);

module.exports = router;