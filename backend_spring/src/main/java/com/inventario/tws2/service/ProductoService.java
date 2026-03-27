package com.inventario.tws2.service;

import com.inventario.tws2.dto.StockMovimientoRequest;
import com.inventario.tws2.model.Historial;
import com.inventario.tws2.model.MovimientoInventario;
import com.inventario.tws2.model.Producto;
import com.inventario.tws2.repository.CategoriaRepository;
import com.inventario.tws2.repository.HistorialRepository;
import com.inventario.tws2.repository.MovimientoInventarioRepository;
import com.inventario.tws2.repository.ProductoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Servicio de Lógica de Negocio de Productos
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description Contiene toda la lógica de negocio para la gestión de productos:
 *              - CRUD con soft delete (deletedAt != null → papelera).
 *              - Entradas y salidas de stock con validaciones de cantidad.
 *              - Registro automático en la bitácora de auditoría (Historial) para cada operación.
 *              - Registro de movimientos de inventario (MovimientoInventario) para trazabilidad.
 *              Todas las operaciones de escritura son transaccionales (@Transactional).
 */
@Service
@RequiredArgsConstructor
public class ProductoService {
    private final ProductoRepository productoRepository;
    private final HistorialRepository historialRepository;
    private final MovimientoInventarioRepository movimientoInventarioRepository;
    private final CategoriaRepository categoriaRepository;

    @Transactional
    public Producto crearProducto(Producto producto, Long usuarioId) {
        if (producto.getCategoria() != null && producto.getCategoria().getId() != null) {
            categoriaRepository.findById(producto.getCategoria().getId())
                    .ifPresent(producto::setCategoria);
        }
        Producto nuevo = productoRepository.save(producto);
        
        Historial h = new Historial();
        h.setAccion("CREACION");
        h.setDetalles("Producto registrado (" + nuevo.getNombre() + ") con stock inicial de " + nuevo.getCantidadEnStock() + " unidades [" + (nuevo.isInventariado() ? "Inventariable" : "Servicio") + "]");
        h.setUsuarioId(usuarioId);
        historialRepository.save(h);
        return nuevo;
    }

    public List<Producto> obtenerProductos() {
        return productoRepository.findByDeletedAtIsNull();
    }

    @Transactional
    public Producto actualizarProducto(Long id, Producto data, Long usuarioId) {
        Producto p = productoRepository.findById(id).orElseThrow(() -> new RuntimeException("Producto no encontrado"));
        p.setNombre(data.getNombre());
        p.setDescripcion(data.getDescripcion());
        p.setPrecioUnitarioVenta(data.getPrecioUnitarioVenta());
        p.setPrecioUnitarioCompra(data.getPrecioUnitarioCompra());
        p.setInventariado(data.isInventariado());
        
        // Buscar y asignar la categoría desde el repositorio para asegurar persistencia correcta
        if (data.getCategoria() != null && data.getCategoria().getId() != null) {
            categoriaRepository.findById(data.getCategoria().getId())
                    .ifPresent(p::setCategoria);
        } else {
            p.setCategoria(null);
        }
        if(data.getCantidadEnStock() != null) p.setCantidadEnStock(data.getCantidadEnStock());
        
        Producto actualizado = productoRepository.save(p);
        
        Historial h = new Historial();
        h.setAccion("EDICION");
        h.setDetalles("Producto modificado: " + p.getNombre());
        h.setUsuarioId(usuarioId);
        historialRepository.save(h);
        
        return actualizado;
    }

    @Transactional
    public void eliminarProducto(Long id, Long usuarioId) {
        Producto p = productoRepository.findById(id).orElseThrow(() -> new RuntimeException("Producto no encontrado"));
        
        // REGLA DE NEGOCIO: No eliminar si es inventariado y tiene stock > 0
        if (p.isInventariado() && p.getCantidadEnStock() > 0) {
            throw new RuntimeException("No se puede eliminar: el producto tiene stock activo.");
        }

        p.setDeletedAt(LocalDateTime.now());
        productoRepository.save(p);
        
        Historial h = new Historial();
        h.setAccion("ELIMINACION");
        h.setDetalles("Producto enviado a papelera: " + p.getNombre());
        h.setUsuarioId(usuarioId);
        historialRepository.save(h);
    }

    @Transactional
    public Producto agregarStock(Long id, StockMovimientoRequest req, Long usuarioId) {
        if(req.getCantidad() == null || req.getCantidad() <= 0) throw new RuntimeException("La cantidad debe ser mayor a 0");
        Producto p = productoRepository.findById(id).orElseThrow(() -> new RuntimeException("Producto no encontrado"));
        p.setCantidadEnStock(p.getCantidadEnStock() + req.getCantidad());
        productoRepository.save(p);

        MovimientoInventario m = new MovimientoInventario();
        m.setTipoMovimiento("ENTRADA");
        m.setCantidad(req.getCantidad());
        m.setMotivo(req.getMotivo() != null && !req.getMotivo().isEmpty() ? req.getMotivo() : "Entrada manual de stock");
        m.setProductoId(p.getId());
        m.setUsuarioId(usuarioId);
        movimientoInventarioRepository.save(m);

        Historial h = new Historial();
        h.setAccion("ENTRADA");
        h.setDetalles("Entrada de " + req.getCantidad() + " unids. de " + p.getNombre());
        h.setUsuarioId(usuarioId);
        historialRepository.save(h);

        return p;
    }

    @Transactional
    public Producto despacharStock(Long id, StockMovimientoRequest req, Long usuarioId) {
        if(req.getCantidad() == null || req.getCantidad() <= 0) throw new RuntimeException("La cantidad debe ser mayor a 0");
        Producto p = productoRepository.findById(id).orElseThrow(() -> new RuntimeException("Producto no encontrado"));
        if(p.getCantidadEnStock() < req.getCantidad()) throw new RuntimeException("Stock insuficiente para despachar");
        
        p.setCantidadEnStock(p.getCantidadEnStock() - req.getCantidad());
        productoRepository.save(p);

        MovimientoInventario m = new MovimientoInventario();
        m.setTipoMovimiento("SALIDA");
        m.setCantidad(req.getCantidad());
        m.setMotivo(req.getMotivo() != null && !req.getMotivo().isEmpty() ? req.getMotivo() : "Despacho de inventario");
        m.setProductoId(p.getId());
        m.setUsuarioId(usuarioId);
        movimientoInventarioRepository.save(m);

        Historial h = new Historial();
        h.setAccion("SALIDA");
        h.setDetalles("Salida de " + req.getCantidad() + " unids. de " + p.getNombre());
        h.setUsuarioId(usuarioId);
        historialRepository.save(h);

        return p;
    }

    public List<Producto> obtenerProductosBorrados() {
        return productoRepository.findByDeletedAtIsNotNull();
    }

    @Transactional
    public Producto restaurarProducto(Long id, Long usuarioId) {
        Producto p = productoRepository.findById(id).orElseThrow(() -> new RuntimeException("Producto no encontrado"));
        p.setDeletedAt(null);
        productoRepository.save(p);

        Historial h = new Historial();
        h.setAccion("RESTAURACION");
        h.setDetalles("Producto Restaurado de Papelera: " + p.getNombre());
        h.setUsuarioId(usuarioId);
        historialRepository.save(h);

        return p;
    }
}
