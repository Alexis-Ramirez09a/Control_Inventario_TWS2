package com.facturas.tws2;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * Controlador del Microservicio Satélite de Facturas
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description Servicio independiente (puerto 8081) que expone datos ficticios de facturación.
 *              Endpoint GET /facturas retorna 4 facturas dummy con latencia simulada de 300ms por registro
 *              para demostrar el comportamiento reactivo del backend principal con WebClient y Circuit Breaker.
 *              Este microservicio puede encenderse/apagarse para probar la resiliencia del gateway BFF.
 */
@RestController
@RequestMapping("/facturas")
public class FacturaController {

    @GetMapping
    public Flux<Factura> obtenerFacturasDummy() {
        return Flux.just(
                new Factura("FAC-001", "Compra Hardware", 1500.0, LocalDateTime.now().minusDays(1)),
                new Factura("FAC-002", "Licencias Software", 300.0, LocalDateTime.now().minusDays(3)),
                new Factura("FAC-003", "Soporte Técnico", 150.0, LocalDateTime.now().minusDays(5)),
                new Factura("FAC-004", "Silla Ergonómica", 250.0, LocalDateTime.now().minusDays(10))
        ).delayElements(Duration.ofMillis(300)); // Simulamos latencia asíncrona de 300ms por registro
    }

    record Factura(String codigo, String concepto, Double monto, LocalDateTime fecha) {}
}
