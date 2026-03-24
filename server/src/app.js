const express = require('express');
const cors = require('cors');
const sequelize = require('./config/database');
const productoRoutes = require('./routes/ProductoRoutes');
const authRoutes = require('./routes/AuthRoutes');
const historialRoutes = require('./routes/HistorialRoutes');
require('dotenv').config();

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api', productoRoutes);
app.use('/api/auth', authRoutes);
app.use('/api', historialRoutes);

const PORT = process.env.PORT || 3000;

const iniciarServidor = async () => {
    try {
        await sequelize.authenticate();
        console.log('✅ Conexión a MySQL establecida correctamente.');
        
        await sequelize.sync({ alter: true });
        console.log('✅ Modelos sincronizados con la base de datos.');

        app.listen(PORT, () => {
            console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
        });
    } catch (error) {
        console.error('❌ No se pudo conectar a la base de datos:', error.message);
    }
};

iniciarServidor();