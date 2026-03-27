package com.inventario.tws2.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * Entidad Producto
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description Modelo JPA que representa un producto del inventario.
 *              Soporta soft delete mediante el campo deletedAt (null = activo, fecha = en papelera).
 *              Campos auditables: createdAt (auto), updatedAt (auto).
 */
@Data
@Entity
@Table(name = "productos")
public class Producto {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre del producto es obligatorio")
    @Size(min = 3, max = 150, message = "El nombre debe tener entre 3 y 150 caracteres")
    @Column(nullable = false)
    private String nombre;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    @NotNull(message = "El precio de venta es obligatorio")
    @Positive(message = "El precio de venta debe ser mayor a 0")
    @Column(name = "precioUnitarioVenta", nullable = false)
    private Double precioUnitarioVenta;

    @NotNull(message = "El precio de compra es obligatorio")
    @Positive(message = "El precio de compra debe ser mayor a 0")
    @Column(name = "precioUnitarioCompra", nullable = false)
    private Double precioUnitarioCompra;

    @Min(value = 0, message = "El stock no puede ser negativo")
    @Column(name = "cantidadEnStock", nullable = false)
    private Integer cantidadEnStock = 0;

    @Column(name = "createdAt", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updatedAt")
    private LocalDateTime updatedAt;

    @Column(name = "deletedAt")
    private LocalDateTime deletedAt;

    @Column(nullable = false)
    private boolean inventariado = true;

    @ManyToOne
    @JoinColumn(name = "categoria_id")
    private Categoria categoria;

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
