package com.example.rskitchen5.Model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "pagos")
public class Pago {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String facturaId;
    private String metodo;
    private double monto;
    private LocalDateTime fecha;
    private boolean imprimirCopia;

    public Pago() {
        this.fecha = LocalDateTime.now();
    }

    public Pago(String facturaId, LocalDateTime fecha, Long id, boolean imprimirCopia, String metodo, double monto) {
        this.facturaId = facturaId;
        this.fecha = fecha != null ? fecha : LocalDateTime.now();
        this.id = id;
        this.imprimirCopia = imprimirCopia;
        this.metodo = metodo;
        this.monto = monto;
    }

    public String getId() {
        return id != null ? String.valueOf(id) : null;
    }

    public void setId(String id) {
        if (id != null && !id.trim().isEmpty()) {
            try {
                this.id = Long.parseLong(id);
            } catch (NumberFormatException ignored) {}
        }
    }

    public Long getIdLong() {
        return id;
    }

    public void setIdLong(Long id) {
        this.id = id;
    }

    public String getFacturaId() {
        return facturaId;
    }

    public void setFacturaId(String facturaId) {
        this.facturaId = facturaId;
    }

    public LocalDateTime getFecha() {
        return fecha;
    }

    public void setFecha(LocalDateTime fecha) {
        this.fecha = fecha;
    }

    public boolean isImprimirCopia() {
        return imprimirCopia;
    }

    public void setImprimirCopia(boolean imprimirCopia) {
        this.imprimirCopia = imprimirCopia;
    }

    public String getMetodo() {
        return metodo;
    }

    public void setMetodo(String metodo) {
        this.metodo = metodo;
    }

    public double getMonto() {
        return monto;
    }

    public void setMonto(double monto) {
        this.monto = monto;
    }
}
