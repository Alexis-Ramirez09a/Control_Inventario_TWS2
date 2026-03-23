const Usuario = require('../models/Usuario');
const jwt = require('jsonwebtoken');

const registrar = async (req, res) => {
    try {
        const { nombre, password, rol } = req.body;
        
        // Verificar si el usuario ya existe
        const usuarioExistente = await Usuario.findOne({ where: { nombre } });
        if (usuarioExistente) {
            return res.status(400).json({ mensaje: 'El nombre de usuario ya está registrado' });
        }

        const nuevoUsuario = await Usuario.create({ nombre, password, rol });
        
        res.status(201).json({
            mensaje: 'Usuario registrado exitosamente',
            usuario: { 
                id: nuevoUsuario.id, 
                nombre: nuevoUsuario.nombre, 
                rol: nuevoUsuario.rol 
            }
        });
    } catch (error) {
        res.status(500).json({ mensaje: 'Error al registrar usuario', error: error.message });
    }
};

const login = async (req, res) => {
    try {
        const { nombre, password } = req.body;

        // Buscar usuario por nombre
        const usuario = await Usuario.findOne({ where: { nombre } });
        if (!usuario) {
            return res.status(404).json({ mensaje: 'Usuario no encontrado' });
        }

        // Verificar contraseña
        const passwordValido = await usuario.verificarPassword(password);
        if (!passwordValido) {
            return res.status(401).json({ mensaje: 'Contraseña incorrecta' });
        }

        // Generar Token JWT
        const token = jwt.sign(
            { id: usuario.id, rol: usuario.rol },
            process.env.JWT_SECRET || 'secreto_super_seguro',
            { expiresIn: '8h' }
        );

        res.status(200).json({
            mensaje: 'Login exitoso',
            token,
            usuario: { 
                id: usuario.id, 
                nombre: usuario.nombre, 
                rol: usuario.rol 
            }
        });
    } catch (error) {
        res.status(500).json({ mensaje: 'Error en el login', error: error.message });
    }
};

module.exports = { registrar, login };
