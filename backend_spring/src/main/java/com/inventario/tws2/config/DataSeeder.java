package com.inventario.tws2.config;

import com.inventario.tws2.model.Usuario;
import com.inventario.tws2.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        if (usuarioRepository.count() == 0) {
            Usuario admin = new Usuario();
            admin.setNombre("admin");
            admin.setPassword(passwordEncoder.encode("123"));
            admin.setRol("ADMIN");
            usuarioRepository.save(admin);
            
            Usuario almacen = new Usuario();
            almacen.setNombre("almacen");
            almacen.setPassword(passwordEncoder.encode("123"));
            almacen.setRol("CONTROL");
            usuarioRepository.save(almacen);
            
            System.out.println("✅ Usuarios semilla creados en la nueva base JPA: admin/123 y almacen/123");
        }
    }
}
