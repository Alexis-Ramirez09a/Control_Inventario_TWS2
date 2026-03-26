package com.inventario.tws2.controller;

import com.inventario.tws2.dto.StockMovimientoRequest;
import com.inventario.tws2.model.Producto;
import com.inventario.tws2.model.Usuario;
import com.inventario.tws2.service.ProductoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.util.Map;

/**
 * Controlador de Productos
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description CRUD completo de productos con gestión de inventario (entradas y salidas de stock),
 *              soft delete (papelera de reciclaje) y restauración. Todas las rutas requieren autenticación JWT.
 *              Cada operación registra automáticamente un historial de auditoría.
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService productoService;

    private Long getAuthId(Authentication auth) {
        return ((Usuario) auth.getPrincipal()).getId();
    }

    @PostMapping("/crear/producto")
    public Mono<ResponseEntity<?>> crearProducto(@Valid @RequestBody Producto producto, Authentication authentication) {
        return Mono.fromCallable(() -> productoService.crearProducto(producto, getAuthId(authentication)))
                .subscribeOn(Schedulers.boundedElastic())
                .map(p -> ResponseEntity.status(HttpStatus.CREATED).body(p));
    }

    @GetMapping("/obtener/productos")
    public Flux<Producto> obtenerProductos() {
        return Mono.fromCallable(() -> productoService.obtenerProductos())
                .subscribeOn(Schedulers.boundedElastic())
                .flatMapMany(Flux::fromIterable);
    }

    @PutMapping("/actualizar/producto/{id}")
    public Mono<ResponseEntity<?>> actualizarProducto(@PathVariable Long id, @Valid @RequestBody Producto producto, Authentication authentication) {
        return Mono.fromCallable(() -> productoService.actualizarProducto(id, producto, getAuthId(authentication)))
                .subscribeOn(Schedulers.boundedElastic())
                .map(p -> ResponseEntity.ok().body((Object) p));
    }

    @DeleteMapping("/eliminar/producto/{id}")
    public Mono<ResponseEntity<?>> eliminarProducto(@PathVariable Long id, Authentication authentication) {
        return Mono.fromRunnable(() -> productoService.eliminarProducto(id, getAuthId(authentication)))
                .subscribeOn(Schedulers.boundedElastic())
                .then(Mono.just(ResponseEntity.ok().body((Object) Map.of("mensaje", "Producto eliminado correctamente"))));
    }

    @PostMapping("/{id}/entrada")
    public Mono<ResponseEntity<?>> agregarStock(@PathVariable Long id, @Valid @RequestBody StockMovimientoRequest req, Authentication authentication) {
        return Mono.fromCallable(() -> productoService.agregarStock(id, req, getAuthId(authentication)))
                .subscribeOn(Schedulers.boundedElastic())
                .map(p -> ResponseEntity.ok().body((Object) Map.of("mensaje", "Stock agregado correctamente", "producto", p)));
    }

    @PostMapping("/{id}/salida")
    public Mono<ResponseEntity<?>> despacharStock(@PathVariable Long id, @Valid @RequestBody StockMovimientoRequest req, Authentication authentication) {
        return Mono.fromCallable(() -> productoService.despacharStock(id, req, getAuthId(authentication)))
                .subscribeOn(Schedulers.boundedElastic())
                .map(p -> ResponseEntity.ok().body((Object) Map.of("mensaje", "Stock despachado correctamente", "producto", p)));
    }

    @GetMapping("/obtener/borrados")
    public Flux<Producto> obtenerProductosBorrados() {
        return Mono.fromCallable(() -> productoService.obtenerProductosBorrados())
                .subscribeOn(Schedulers.boundedElastic())
                .flatMapMany(Flux::fromIterable);
    }

    @PutMapping("/restaurar/producto/{id}")
    public Mono<ResponseEntity<?>> restaurarProducto(@PathVariable Long id, Authentication authentication) {
        return Mono.fromCallable(() -> productoService.restaurarProducto(id, getAuthId(authentication)))
                .subscribeOn(Schedulers.boundedElastic())
                .map(p -> ResponseEntity.ok().body((Object) Map.of("mensaje", "Producto restaurado exitosamente", "producto", p)));
    }
}
