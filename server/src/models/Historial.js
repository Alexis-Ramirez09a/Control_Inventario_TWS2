const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Usuario = require('./Usuario');

const Historial = sequelize.define('Historial', {
    accion: {
        type: DataTypes.ENUM('CREACION', 'EDICION', 'ELIMINACION', 'ENTRADA', 'SALIDA'),
        allowNull: false
    },
    detalles: {
        type: DataTypes.STRING,
        allowNull: false
    }
}, {
    tableName: 'historial',
    timestamps: true
});

Usuario.hasMany(Historial, { foreignKey: 'usuarioId' });
Historial.belongsTo(Usuario, { foreignKey: 'usuarioId' });

module.exports = Historial;
