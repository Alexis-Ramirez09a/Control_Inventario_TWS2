package com.inventario.tws2.dto;

import lombok.Data;

@Data
public class StockMovimientoRequest {
    private Integer cantidad;
    private String motivo;
}
