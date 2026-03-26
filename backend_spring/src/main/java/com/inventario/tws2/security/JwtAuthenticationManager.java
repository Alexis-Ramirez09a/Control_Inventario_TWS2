package com.inventario.tws2.security;

import com.inventario.tws2.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.ReactiveAuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.util.Collections;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationManager implements ReactiveAuthenticationManager {

    private final JwtUtil jwtUtil;
    private final UsuarioRepository usuarioRepository;

    @Override
    public Mono<Authentication> authenticate(Authentication authentication) {
        String authToken = authentication.getCredentials().toString();
        
        return Mono.fromCallable(() -> {
            if (jwtUtil.validateToken(authToken)) {
                Long userId = jwtUtil.getUserIdFromToken(authToken);
                return usuarioRepository.findById(userId).orElse(null);
            }
            return null;
        }).subscribeOn(Schedulers.boundedElastic())
        .map(usuario -> {
            if (usuario != null) {
                return new UsernamePasswordAuthenticationToken(
                        usuario, 
                        authToken, 
                        Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + usuario.getRol()))
                );
            }
            return null;
        }).cast(Authentication.class)
        .onErrorResume(e -> Mono.empty());
    }
}
