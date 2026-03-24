const Producto = require('../models/Producto');
const MovimientoInventario = require('../models/MovimientoInventario');
const Historial = require('../models/Historial');
const sequelize = require('../config/database');
const { Op } = require('sequelize');

const crearProducto = async (req, res) => {
    try {
        const nuevoProducto = await Producto.create(req.body);
        await Historial.create({ accion: 'CREACION', detalles: `Producto registrado: ${nuevoProducto.nombre}`, usuarioId: req.usuario.id });
        res.status(201).json(nuevoProducto);
    } catch (error) {
        res.status(500).json({ mensaje: 'Error al crear producto', error: error.message });
    }
};

const obtenerProductos = async (req, res) => {
    try {
        const productos = await Producto.findAll();
        res.status(200).json(productos);
    } catch (error) {
        res.status(500).json({ mensaje: 'Error al obtener productos', error: error.message });
    }
};

const actualizarProducto = async (req, res) => {
    try {
        const { id } = req.params;
        const producto = await Producto.findByPk(id);
        
        if (!producto) {
            return res.status(404).json({ mensaje: 'Producto no encontrado' });
        }

        await producto.update(req.body);
        await Historial.create({ accion: 'EDICION', detalles: `Producto modificado: ${producto.nombre}`, usuarioId: req.usuario.id });
        res.status(200).json(producto);
    } catch (error) {
        res.status(500).json({ mensaje: 'Error al actualizar producto', error: error.message });
    }
};

const eliminarProducto = async (req, res) => {
    try {
        const { id } = req.params;
        const producto = await Producto.findByPk(id);
        
        if (!producto) {
            return res.status(404).json({ mensaje: 'Producto no encontrado' });
        }
        if (producto.cantidadEnStock > 0) {
            return res.status(400).json({ mensaje: 'No se puede eliminar. El stock físico debe ser vacío primero (Despachar todo).' });
        }

        await producto.destroy();
        await Historial.create({ accion: 'ELIMINACION', detalles: `Producto eliminado: ${producto.nombre}`, usuarioId: req.usuario.id });
        res.status(200).json({ mensaje: 'Producto eliminado correctamente' });
    } catch (error) {
        res.status(500).json({ mensaje: 'Error al eliminar producto', error: error.message });
    }
};

module.exports = {
    crearProducto,
    obtenerProductos,
    actualizarProducto,
    eliminarProducto
};

const agregarStock = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { id } = req.params;
        const { cantidad, motivo } = req.body;
        const usuarioId = req.usuario.id;

        if (!cantidad || cantidad <= 0) {
            return res.status(400).json({ mensaje: 'La cantidad debe ser mayor a 0' });
        }

        const producto = await Producto.findByPk(id, { transaction: t });
        if (!producto) {
            await t.rollback();
            return res.status(404).json({ mensaje: 'Producto no encontrado' });
        }

        producto.cantidadEnStock += cantidad;
        await producto.save({ transaction: t });

        await MovimientoInventario.create({
            tipoMovimiento: 'ENTRADA',
            cantidad,
            motivo: motivo || 'Entrada manual de stock',
            productoId: producto.id,
            usuarioId
        }, { transaction: t });

        await Historial.create({ accion: 'ENTRADA', detalles: `Entrada de ${cantidad} unids. de ${producto.nombre}`, usuarioId }, { transaction: t });

        await t.commit();
        res.status(200).json({ mensaje: 'Stock agregado correctamente', producto });
    } catch (error) {
        await t.rollback();
        res.status(500).json({ mensaje: 'Error al agregar stock', error: error.message });
    }
};

const despacharStock = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { id } = req.params;
        const { cantidad, motivo } = req.body;
        const usuarioId = req.usuario.id;

        if (!cantidad || cantidad <= 0) {
            return res.status(400).json({ mensaje: 'La cantidad debe ser mayor a 0' });
        }

        const producto = await Producto.findByPk(id, { transaction: t });
        if (!producto) {
             await t.rollback();
             return res.status(404).json({ mensaje: 'Producto no encontrado' });
        }

        if (producto.cantidadEnStock < cantidad) {
             await t.rollback();
             return res.status(400).json({ mensaje: 'Stock insuficiente para despachar' });
        }

        producto.cantidadEnStock -= cantidad;
        await producto.save({ transaction: t });

        await MovimientoInventario.create({
            tipoMovimiento: 'SALIDA',
            cantidad,
            motivo: motivo || 'Despacho de inventario',
            productoId: producto.id,
            usuarioId
        }, { transaction: t });

        await Historial.create({ accion: 'SALIDA', detalles: `Salida de ${cantidad} unids. de ${producto.nombre}`, usuarioId }, { transaction: t });

        await t.commit();
        res.status(200).json({ mensaje: 'Stock despachado correctamente', producto });
    } catch (error) {
        await t.rollback();
        res.status(500).json({ mensaje: 'Error al despachar stock', error: error.message });
    }
};

const obtenerProductosBorrados = async (req, res) => {
    try {
        const productos = await Producto.findAll({
            where: { deletedAt: { [Op.ne]: null } },
            paranoid: false
        });
        res.status(200).json(productos);
    } catch (error) {
        res.status(500).json({ mensaje: 'Error al obtener productos borrados', error: error.message });
    }
};

const restaurarProducto = async (req, res) => {
    try {
        const producto = await Producto.findOne({
            where: { id: req.params.id },
            paranoid: false
        });
        if (!producto) return res.status(404).json({ mensaje: 'Producto no encontrado' });
        
        await producto.restore();
        await Historial.create({ accion: 'RESTAURACION', detalles: `Producto Restaurado de Papelera: ${producto.nombre}`, usuarioId: req.usuario.id });
        
        res.status(200).json({ mensaje: 'Producto restaurado exitosamente', producto });
    } catch (error) {
        res.status(500).json({ mensaje: 'Error al restaurar producto', error: error.message });
    }
};

module.exports = {
    crearProducto,
    obtenerProductos,
    actualizarProducto,
    eliminarProducto,
    agregarStock,
    despacharStock,
    obtenerProductosBorrados,
    restaurarProducto
};