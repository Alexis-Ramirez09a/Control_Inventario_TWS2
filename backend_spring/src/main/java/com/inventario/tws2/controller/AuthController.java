package com.inventario.tws2.controller;

import com.inventario.tws2.dto.AuthRequest;
import com.inventario.tws2.dto.AuthResponse;
import com.inventario.tws2.dto.RegistrarRequest;
import com.inventario.tws2.model.Usuario;
import com.inventario.tws2.repository.UsuarioRepository;
import com.inventario.tws2.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.util.Map;

/**
 * Controlador de Autenticación
 *
 * @author Alexis Ramírez
 * @date 2026-03-25
 * @description Gestiona el login y registro de usuarios mediante JWT.
 *              Rutas públicas: POST /api/auth/login, POST /api/auth/registrar.
 *              Utiliza BCrypt para el hash de contraseñas y genera tokens JWT con rol y ID del usuario.
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    /**
     * Autentica un usuario y retorna un token JWT.
     * @param request DTO con nombre y password del usuario.
     * @return 200 OK con AuthResponse (usuario + token) o 401 UNAUTHORIZED si las credenciales son inválidas.
     */
    @PostMapping("/login")
    public Mono<ResponseEntity<?>> login(@RequestBody AuthRequest request) {
        return Mono.fromCallable(() -> usuarioRepository.findByNombre(request.getNombre()))
                .subscribeOn(Schedulers.boundedElastic())
                .map(optUsuario -> {
                    if (optUsuario.isPresent() && passwordEncoder.matches(request.getPassword(), optUsuario.get().getPassword())) {
                        Usuario u = optUsuario.get();
                        String token = jwtUtil.generateToken(u.getNombre(), u.getRol(), u.getId());
                        u.setPassword(null); 
                        return ResponseEntity.ok(new AuthResponse(u, token));
                    }
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("mensaje", "Credenciales inválidas"));
                });
    }

    @PostMapping("/registrar")
    public Mono<ResponseEntity<?>> registrar(@RequestBody RegistrarRequest request) {
        return Mono.fromCallable(() -> {
            if (usuarioRepository.findByNombre(request.getNombre()).isPresent()) {
                return false;
            }
            Usuario u = new Usuario();
            u.setNombre(request.getNombre());
            u.setPassword(passwordEncoder.encode(request.getPassword()));
            u.setRol(request.getRol() == null ? "VISTA" : request.getRol());
            usuarioRepository.save(u);
            return true;
        }).subscribeOn(Schedulers.boundedElastic())
        .map(success -> {
            if (success) {
                return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("mensaje", "Usuario registrado exitosamente"));
            }
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("mensaje", "El usuario ya existe"));
        });
    }
}
