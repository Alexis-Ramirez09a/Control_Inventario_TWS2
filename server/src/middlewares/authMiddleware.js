const jwt = require('jsonwebtoken');

const verificarToken = (req, res, next) => {
    // Obtener token del header
    const token = req.header('Authorization');

    // Revisar si no hay token
    if (!token) {
        return res.status(401).json({ mensaje: 'No hay token, autorización denegada' });
    }

    try {
        // En POSTMAN o frontend, el token usualmente se envía como "Bearer <token>"
        const tokenLimpio = token.startsWith('Bearer ') ? token.slice(7, token.length) : token;
        
        // Verificar token
        const decodificado = jwt.verify(tokenLimpio, process.env.JWT_SECRET || 'secreto_super_seguro');
        
        // Guardar la información del usuario en el request
        req.usuario = decodificado;
        next();
    } catch (error) {
        res.status(401).json({ mensaje: 'Token no es válido o expiró' });
    }
};

// Función para verificar si el usuario tiene el rol permitido
const verificarRol = (rolesPermitidos) => {
    return (req, res, next) => {
        if (!req.usuario) {
            return res.status(401).json({ mensaje: 'Usuario no autenticado' });
        }

        if (!rolesPermitidos.includes(req.usuario.rol)) {
            return res.status(403).json({ mensaje: `Acceso denegado. Requiere permisos superiores.` });
        }

        next(); // Tiene el rol correcto, continúa...
    };
};

module.exports = { verificarToken, verificarRol };
