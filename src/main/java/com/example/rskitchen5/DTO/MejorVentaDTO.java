package com.example.rskitchen5.DTO;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class MejorVentaDTO {

    private String facturaId;
    private String pedidoId;
    private double monto;
    private String montoFormateado;
    private LocalDateTime fecha;
    private String fechaFormateada;
    private String mesa;
    private String mesero;
    private int totalItems;
    private List<ItemVentaDTO> items = new ArrayList<>();

    public static class ItemVentaDTO {
        private String nombre;
        private int cantidad;
        private double precio;
        private double subtotal;

        public ItemVentaDTO() {
        }

        public ItemVentaDTO(String nombre, int cantidad, double precio, double subtotal) {
            this.nombre = nombre;
            this.cantidad = cantidad;
            this.precio = precio;
            this.subtotal = subtotal;
        }

        public String getNombre() {
            return nombre;
        }

        public void setNombre(String nombre) {
            this.nombre = nombre;
        }

        public int getCantidad() {
            return cantidad;
        }

        public void setCantidad(int cantidad) {
            this.cantidad = cantidad;
        }

        public double getPrecio() {
            return precio;
        }

        public void setPrecio(double precio) {
            this.precio = precio;
        }

        public double getSubtotal() {
            return subtotal;
        }

        public void setSubtotal(double subtotal) {
            this.subtotal = subtotal;
        }
    }

    public MejorVentaDTO() {
    }

    public MejorVentaDTO(String facturaId, String pedidoId, double monto, String montoFormateado,
                         LocalDateTime fecha, String fechaFormateada, String mesa, String mesero,
                         int totalItems, List<ItemVentaDTO> items) {
        this.facturaId = facturaId;
        this.pedidoId = pedidoId;
        this.monto = monto;
        this.montoFormateado = montoFormateado;
        this.fecha = fecha;
        this.fechaFormateada = fechaFormateada;
        this.mesa = mesa;
        this.mesero = mesero;
        this.totalItems = totalItems;
        this.items = items != null ? items : new ArrayList<>();
    }

    public String getFacturaId() {
        return facturaId;
    }

    public void setFacturaId(String facturaId) {
        this.facturaId = facturaId;
    }

    public String getPedidoId() {
        return pedidoId;
    }

    public void setPedidoId(String pedidoId) {
        this.pedidoId = pedidoId;
    }

    public double getMonto() {
        return monto;
    }

    public void setMonto(double monto) {
        this.monto = monto;
    }

    public String getMontoFormateado() {
        return montoFormateado;
    }

    public void setMontoFormateado(String montoFormateado) {
        this.montoFormateado = montoFormateado;
    }

    public LocalDateTime getFecha() {
        return fecha;
    }

    public void setFecha(LocalDateTime fecha) {
        this.fecha = fecha;
    }

    public String getFechaFormateada() {
        return fechaFormateada;
    }

    public void setFechaFormateada(String fechaFormateada) {
        this.fechaFormateada = fechaFormateada;
    }

    public String getMesa() {
        return mesa;
    }

    public void setMesa(String mesa) {
        this.mesa = mesa;
    }

    public String getMesero() {
        return mesero;
    }

    public void setMesero(String mesero) {
        this.mesero = mesero;
    }

    public int getTotalItems() {
        return totalItems;
    }

    public void setTotalItems(int totalItems) {
        this.totalItems = totalItems;
    }

    public List<ItemVentaDTO> getItems() {
        return items;
    }

    public void setItems(List<ItemVentaDTO> items) {
        this.items = items;
    }
}

