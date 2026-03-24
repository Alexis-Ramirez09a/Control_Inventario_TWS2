const Historial = require('../models/Historial');
const Usuario = require('../models/Usuario');

const obtenerHistorial = async (req, res) => {
    try {
        const registros = await Historial.findAll({
            include: [{ model: Usuario, attributes: ['nombre', 'rol'] }],
            order: [['createdAt', 'DESC']]
        });
        res.status(200).json(registros);
    } catch (error) {
        res.status(500).json({ mensaje: 'Error al obtener historial', error: error.message });
    }
};

module.exports = { obtenerHistorial };
