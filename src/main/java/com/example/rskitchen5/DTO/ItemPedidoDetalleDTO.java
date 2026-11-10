package com.example.rskitchen5.DTO;

public class ItemPedidoDetalleDTO {

    private String nombrePlatillo;
    private String descripcionPlatillo;
    private String cantidad;
    private double precio;

    public String getCantidad() {
        return cantidad;
    }

    public void setCantidad(String cantidad) {
        this.cantidad = cantidad;
    }

    public double getPrecio() {
        return precio;
    }

    public void setPrecio(double precio) {
        this.precio = precio;
    }

    public String getNombrePlatillo() {
        return nombrePlatillo;
    }

    public void setNombrePlatillo(String nombrePlatillo) {
        this.nombrePlatillo = nombrePlatillo;
    }

    public String getDescripcionPlatillo() {
        return descripcionPlatillo;
    }

    public void setDescripcionPlatillo(String descripcionPlatillo) {
        this.descripcionPlatillo = descripcionPlatillo;
    }
}