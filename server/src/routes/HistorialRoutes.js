const express = require('express');
const historialController = require('../controllers/HistorialController');
const { verificarToken, verificarRol } = require('../middlewares/authMiddleware');

const router = express.Router();

router.get('/historial', verificarToken, historialController.obtenerHistorial);

module.exports = router;
