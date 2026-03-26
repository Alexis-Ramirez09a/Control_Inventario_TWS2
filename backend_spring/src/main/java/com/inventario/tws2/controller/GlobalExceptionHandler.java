package com.inventario.tws2.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<?> handleRuntimeException(RuntimeException e) {
        if(e.getMessage().contains("no encontrado")) {
            return ResponseEntity.status(404).body(Map.of("mensaje", e.getMessage()));
        }
        if(e.getMessage().contains("insuficiente") || e.getMessage().contains("mayor a 0") || e.getMessage().contains("inventariado con stock activo")) {
            return ResponseEntity.status(400).body(Map.of("mensaje", e.getMessage()));
        }
        return ResponseEntity.status(400).body(Map.of("mensaje", e.getMessage()));
    }
}
