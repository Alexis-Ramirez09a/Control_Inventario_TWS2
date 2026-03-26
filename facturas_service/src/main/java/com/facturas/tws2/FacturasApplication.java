package com.facturas.tws2;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Punto de Entrada del Microservicio Satélite de Facturas
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description Microservicio independiente Spring Boot que corre en el puerto 8081.
 *              Su función es simular un sistema de facturación externo al cual el backend principal
 *              se conecta mediante WebClient + Resilience4j Circuit Breaker.
 */
@SpringBootApplication
public class FacturasApplication {
    public static void main(String[] args) {
        SpringApplication.run(FacturasApplication.class, args);
    }
}
