package com.inventario.tws2.service;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import java.util.Map;

/**
 * Servicio de Integración de Facturas (Circuit Breaker)
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description Servicio reactivo que se comunica con el microservicio satélite de facturas (localhost:8081)
 *              mediante WebClient. Implementa el patrón Circuit Breaker con Resilience4j para tolerancia a fallos.
 *              Configuración del CB: ventana de 3 llamadas, umbral 50%, espera 15s en estado OPEN.
 *              Fallback: retorna mensaje de mantenimiento cuando el microservicio no está disponible.
 */
@Service
public class FacturaIntegrationService {

    private final WebClient webClient;

    public FacturaIntegrationService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("http://localhost:8081").build();
    }

    @CircuitBreaker(name = "facturasService", fallbackMethod = "facturasFallback")
    public Flux<Map> obtenerFacturas() {
        return webClient.get()
                .uri("/facturas")
                .retrieve()
                .bodyToFlux(Map.class);
    }

    public Flux<Map> facturasFallback(Exception e) {
        return Flux.just(Map.of("mensaje", "El servicio se encuentra en mantenimiento temporalmente"));
    }
}
