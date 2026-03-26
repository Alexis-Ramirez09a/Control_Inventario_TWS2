package com.inventario.tws2.repository;

import com.inventario.tws2.model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ProductoRepository extends JpaRepository<Producto, Long> {
    List<Producto> findByDeletedAtIsNull();
    List<Producto> findByDeletedAtIsNotNull();
}
