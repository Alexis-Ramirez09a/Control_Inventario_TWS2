const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Producto = sequelize.define('Producto', {
    nombre: {
        type: DataTypes.STRING,
        allowNull: false
    },
    descripcion: {
        type: DataTypes.STRING,
        allowNull: false
    },
    cantidadEnStock: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 0
    },
    precioUnitarioCompra: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false
    },
    precioUnitarioVenta: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false
    }
}, {
    tableName: 'productos',
    timestamps: true,
    paranoid: true // Habilita el borrado lógico (crea columna deletedAt)
});

module.exports = Producto;