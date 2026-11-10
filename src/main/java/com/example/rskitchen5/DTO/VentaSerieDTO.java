package com.example.rskitchen5.DTO;

import java.time.LocalDateTime;

public class VentaSerieDTO {

    private LocalDateTime timestamp;
    private double monto;

    public VentaSerieDTO() {
    }

    public VentaSerieDTO(LocalDateTime timestamp, double monto) {
        this.timestamp = timestamp;
        this.monto = monto;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    public double getMonto() {
        return monto;
    }

    public void setMonto(double monto) {
        this.monto = monto;
    }
}
