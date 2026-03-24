const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Producto = require('./Producto');
const Usuario = require('./Usuario');

const MovimientoInventario = sequelize.define('MovimientoInventario', {
    tipoMovimiento: {
        type: DataTypes.ENUM('ENTRADA', 'SALIDA'),
        allowNull: false
    },
    cantidad: {
        type: DataTypes.INTEGER,
        allowNull: false,
        validate: {
            min: 1
        }
    },
    motivo: {
        type: DataTypes.STRING,
        allowNull: true
    },
    fecha: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW
    }
}, {
    tableName: 'movimientos_inventario',
    timestamps: true
});

// Definir relaciones
MovimientoInventario.belongsTo(Producto, { foreignKey: 'productoId' });
Producto.hasMany(MovimientoInventario, { foreignKey: 'productoId' });

MovimientoInventario.belongsTo(Usuario, { foreignKey: 'usuarioId' });
Usuario.hasMany(MovimientoInventario, { foreignKey: 'usuarioId' });

module.exports = MovimientoInventario;
