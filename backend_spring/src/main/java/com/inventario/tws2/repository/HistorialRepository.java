package com.inventario.tws2.repository;

import com.inventario.tws2.model.Historial;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface HistorialRepository extends JpaRepository<Historial, Long> {
    List<Historial> findAllByOrderByCreatedAtDesc();
}
