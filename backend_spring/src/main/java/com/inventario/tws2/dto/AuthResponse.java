package com.inventario.tws2.dto;

import com.inventario.tws2.model.Usuario;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class AuthResponse {
    private Usuario usuario;
    private String token;
}
