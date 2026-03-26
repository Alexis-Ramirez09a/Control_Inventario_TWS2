package com.inventario.tws2.dto;

import lombok.Data;

@Data
public class RegistrarRequest {
    private String nombre;
    private String password;
    private String rol;
}
