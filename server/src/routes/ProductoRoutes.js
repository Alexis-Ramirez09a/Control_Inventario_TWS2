const express = require('express');
const router = express.Router();
const productoController = require('../controllers/ProductoController');
const { verificarToken, verificarRol } = require('../middlewares/authMiddleware');

// Control y Admin pueden crear, ver y actualizar
router.post('/', verificarToken, verificarRol(['ADMIN', 'CONTROL']), productoController.crearProducto);
router.get('/', verificarToken, verificarRol(['ADMIN', 'CONTROL']), productoController.obtenerProductos);
router.put('/:id', verificarToken, verificarRol(['ADMIN', 'CONTROL']), productoController.actualizarProducto);

// Solo Admin puede eliminar (borrado lógico)
router.delete('/:id', verificarToken, verificarRol(['ADMIN']), productoController.eliminarProducto);

module.exports = router;