package com.example.rskitchen5.DTO;

public class PromedioVentasDTO {

    private double promedioVenta;
    private String promedioVentaFormateado;
    private double promedioVentasHoy;
    private String promedioVentasHoyFormateado;
    private double totalVentas;
    private long cantidadVentas;

    public PromedioVentasDTO() {
    }

    public PromedioVentasDTO(double promedioVenta, String promedioVentaFormateado,
                             double promedioVentasHoy, String promedioVentasHoyFormateado,
                             double totalVentas, long cantidadVentas) {
        this.promedioVenta = promedioVenta;
        this.promedioVentaFormateado = promedioVentaFormateado;
        this.promedioVentasHoy = promedioVentasHoy;
        this.promedioVentasHoyFormateado = promedioVentasHoyFormateado;
        this.totalVentas = totalVentas;
        this.cantidadVentas = cantidadVentas;
    }

    public double getPromedioVenta() {
        return promedioVenta;
    }

    public void setPromedioVenta(double promedioVenta) {
        this.promedioVenta = promedioVenta;
    }

    public String getPromedioVentaFormateado() {
        return promedioVentaFormateado;
    }

    public void setPromedioVentaFormateado(String promedioVentaFormateado) {
        this.promedioVentaFormateado = promedioVentaFormateado;
    }

    public double getPromedioVentasHoy() {
        return promedioVentasHoy;
    }

    public void setPromedioVentasHoy(double promedioVentasHoy) {
        this.promedioVentasHoy = promedioVentasHoy;
    }

    public String getPromedioVentasHoyFormateado() {
        return promedioVentasHoyFormateado;
    }

    public void setPromedioVentasHoyFormateado(String promedioVentasHoyFormateado) {
        this.promedioVentasHoyFormateado = promedioVentasHoyFormateado;
    }

    public double getTotalVentas() {
        return totalVentas;
    }

    public void setTotalVentas(double totalVentas) {
        this.totalVentas = totalVentas;
    }

    public long getCantidadVentas() {
        return cantidadVentas;
    }

    public void setCantidadVentas(long cantidadVentas) {
        this.cantidadVentas = cantidadVentas;
    }
}

