package com.inventario.tws2.config;

import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Firewall Reactivo de Rate Limiting por IP
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description WebFilter reactivo que controla el tráfico entrante por dirección IP.
 *              Se ejecuta ANTES que Spring Security (@Order(-1)) para interceptar tráfico malicioso
 *              antes de cualquier validación de JWT.
 *              - Bypass automático: peticiones con header 'Authorization: Bearer ...' pasan sin restricción.
 *              - Bloqueo temporal: +10 peticiones sin token en 60s → HTTP 429 (Too Many Requests).
 *              - Bloqueo permanente: +100 peticiones acumuladas → HTTP 403 (Forbidden).
 *              Almacena contadores en ConcurrentHashMap en memoria (no persiste tras reinicios).
 */
@Component
@Order(-101) // Spring Security WebFlux está en @Order(-100), necesitamos ser más negativos para correr ANTES
public class IpRateLimiterFilter implements WebFilter {

    private final Map<String, IpRecord> cache = new ConcurrentHashMap<>();

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        // Bypass del Rate Limiter Firewall si la petición proviene de un usuario logueado en la App
        String authHeader = exchange.getRequest().getHeaders().getFirst("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return chain.filter(exchange); // Usuario Legítimo: Dejar pasar libremente
        }

        // 1. Detectar IP Real (Soporte para Ngrok/Proxies)
        String forwardedFor = exchange.getRequest().getHeaders().getFirst("X-Forwarded-For");
        String ip;
        if (forwardedFor != null && !forwardedFor.isEmpty()) {
            // El primer elemento de la lista es la IP real del cliente
            ip = forwardedFor.split(",")[0].trim();
        } else {
            ip = exchange.getRequest().getRemoteAddress() != null 
                    ? exchange.getRequest().getRemoteAddress().getAddress().getHostAddress() 
                    : "UNKNOWN";
        }
        
        IpRecord record = cache.compute(ip, (k, v) -> {
            if (v == null || v.isExpired()) {
                return new IpRecord(1, Instant.now().plusSeconds(60));
            }
            if (!v.isPermanentBlock()) {
                v.count++;
                if (v.count >= 100) { // Umbral de bloqueo permanente relajado
                    v.permanentBlock = true;
                }
            }
            return v;
        });

        if (record.isPermanentBlock()) {
            exchange.getResponse().setStatusCode(HttpStatus.FORBIDDEN);
            return exchange.getResponse().setComplete();
        }

        if (record.count > 10) { // Límite aumentado de 10 a 30 para desarrollo
            exchange.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
            return exchange.getResponse().setComplete();
        }

        return chain.filter(exchange);
    }

    private static class IpRecord {
        int count;
        Instant expiry;
        boolean permanentBlock;

        IpRecord(int count, Instant expiry) {
            this.count = count;
            this.expiry = expiry;
            this.permanentBlock = false;
        }

        boolean isExpired() {
            return Instant.now().isAfter(expiry);
        }
        
        boolean isPermanentBlock() {
            return permanentBlock;
        }
    }
}
