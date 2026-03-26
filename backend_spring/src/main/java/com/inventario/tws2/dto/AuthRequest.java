package com.inventario.tws2.dto;

import lombok.Data;

@Data
public class AuthRequest {
    private String nombre;
    private String password;
}
