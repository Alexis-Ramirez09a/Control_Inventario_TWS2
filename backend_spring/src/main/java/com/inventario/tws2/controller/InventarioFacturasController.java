package com.inventario.tws2.controller;

import com.inventario.tws2.service.FacturaIntegrationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

/**
 * Controlador Gateway de Facturación (BFF)
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description Actúa como gateway BFF (Backend For Frontend) para el microservicio satélite de facturas (puerto 8081).
 *              Endpoint GET /api/facturas delega al FacturaIntegrationService que implementa Circuit Breaker con Resilience4j.
 *              Si el microservicio está caído, retorna HTTP 503 con mensaje de mantenimiento (fallback automático).
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class InventarioFacturasController {

    private final FacturaIntegrationService facturaIntegrationService;

    @GetMapping("/facturas")
    public Mono<ResponseEntity<?>> obtenerFacturas() {
        return facturaIntegrationService.obtenerFacturas()
                .collectList()
                .map(lista -> {
                    if (!lista.isEmpty() && lista.get(0).containsKey("mensaje")) {
                        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(lista.get(0));
                    }
                    return ResponseEntity.ok(lista);
                });
    }
}
