package com.inventario.tws2.controller;

import com.inventario.tws2.repository.HistorialRepository;
import com.inventario.tws2.repository.UsuarioRepository;
import com.inventario.tws2.model.Historial;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.util.stream.Collectors;

/**
 * Controlador de Historial (Bitácora de Auditoría)
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description Expone el endpoint GET /api/historial para consultar el registro de auditoría.
 *              Cada entrada incluye la acción (CREACION, EDICION, ELIMINACION, ENTRADA, SALIDA, RESTAURACION),
 *              los detalles del evento y el nombre del usuario que la ejecutó. Ordenado por fecha descendente.
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class HistorialController {

    private final HistorialRepository historialRepository;
    private final UsuarioRepository usuarioRepository;

    @GetMapping("/historial")
    public Flux<Historial> obtenerHistorial() {
        return Mono.fromCallable(() -> {
            var historiales = historialRepository.findAllByOrderByCreatedAtDesc();
            var usuarios = usuarioRepository.findAll();
            var userMap = usuarios.stream().collect(Collectors.toMap(u -> u.getId(), u -> u.getNombre()));
            historiales.forEach(h -> h.setUsuarioNombre(userMap.getOrDefault(h.getUsuarioId(), "Desconocido")));
            return historiales;
        }).subscribeOn(Schedulers.boundedElastic())
        .flatMapMany(Flux::fromIterable);
    }
}
