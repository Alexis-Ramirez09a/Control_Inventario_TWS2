package com.inventario.tws2.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * Entidad Historial (Bitácora de Auditoría)
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description Registro de auditoría que almacena cada acción ejecutada en el sistema.
 *              Acciones posibles: CREACION, EDICION, ELIMINACION, ENTRADA, SALIDA, RESTAURACION.
 *              El campo usuarioNombre es @Transient (se resuelve en runtime desde UsuarioRepository).
 */
@Data
@Entity
@Table(name = "historial")
public class Historial {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String accion;

    @Column(nullable = false)
    private String detalles;

    @Column(name = "usuarioId", nullable = false)
    private Long usuarioId;

    @Transient
    private String usuarioNombre;

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
