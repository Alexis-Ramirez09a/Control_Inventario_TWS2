package com.inventario.tws2.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * Entidad MovimientoInventario
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description Registra cada movimiento físico de inventario (ENTRADA o SALIDA).
 *              Vinculado al producto afectado (productoId) y al usuario que ejecutó la operación (usuarioId).
 *              Incluye la cantidad movida y un motivo opcional.
 */
@Data
@Entity
@Table(name = "movimientos_inventario")
public class MovimientoInventario {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tipoMovimiento", nullable = false)
    private String tipoMovimiento;

    @Column(nullable = false)
    private Integer cantidad;

    private String motivo;

    @Column(name = "productoId", nullable = false)
    private Long productoId;

    @Column(name = "usuarioId", nullable = false)
    private Long usuarioId;

    @Column(name = "createdAt", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updatedAt")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
