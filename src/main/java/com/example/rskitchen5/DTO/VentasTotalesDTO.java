package com.example.rskitchen5.DTO;

public class VentasTotalesDTO {

    private double totalVentas;
    private String totalVentasFormateado;
    private long cantidadVentas;
    private long totalItemsVendidos;
    private double ventasHoy;
    private String ventasHoyFormateado;
    private long cantidadVentasHoy;

    public VentasTotalesDTO() {
    }

    public VentasTotalesDTO(double totalVentas, String totalVentasFormateado, long cantidadVentas,
                            long totalItemsVendidos, double ventasHoy, String ventasHoyFormateado,
                            long cantidadVentasHoy) {
        this.totalVentas = totalVentas;
        this.totalVentasFormateado = totalVentasFormateado;
        this.cantidadVentas = cantidadVentas;
        this.totalItemsVendidos = totalItemsVendidos;
        this.ventasHoy = ventasHoy;
        this.ventasHoyFormateado = ventasHoyFormateado;
        this.cantidadVentasHoy = cantidadVentasHoy;
    }

    public double getTotalVentas() {
        return totalVentas;
    }

    public void setTotalVentas(double totalVentas) {
        this.totalVentas = totalVentas;
    }

    public String getTotalVentasFormateado() {
        return totalVentasFormateado;
    }

    public void setTotalVentasFormateado(String totalVentasFormateado) {
        this.totalVentasFormateado = totalVentasFormateado;
    }

    public long getCantidadVentas() {
        return cantidadVentas;
    }

    public void setCantidadVentas(long cantidadVentas) {
        this.cantidadVentas = cantidadVentas;
    }

    public long getTotalItemsVendidos() {
        return totalItemsVendidos;
    }

    public void setTotalItemsVendidos(long totalItemsVendidos) {
        this.totalItemsVendidos = totalItemsVendidos;
    }

    public double getVentasHoy() {
        return ventasHoy;
    }

    public void setVentasHoy(double ventasHoy) {
        this.ventasHoy = ventasHoy;
    }

    public String getVentasHoyFormateado() {
        return ventasHoyFormateado;
    }

    public void setVentasHoyFormateado(String ventasHoyFormateado) {
        this.ventasHoyFormateado = ventasHoyFormateado;
    }

    public long getCantidadVentasHoy() {
        return cantidadVentasHoy;
    }

    public void setCantidadVentasHoy(long cantidadVentasHoy) {
        this.cantidadVentasHoy = cantidadVentasHoy;
    }
}

