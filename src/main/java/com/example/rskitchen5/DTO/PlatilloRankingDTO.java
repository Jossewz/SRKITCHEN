package com.example.rskitchen5.DTO;

public class PlatilloRankingDTO {

    private int posicion;
    private String nombre;
    private int unidadesVendidas;
    private double precioUnitario;
    private double ingresosTotales;
    private String ingresosTotalesFormateado;
    private double porcentajeTotal;

    public PlatilloRankingDTO() {
    }

    public PlatilloRankingDTO(int posicion, String nombre, int unidadesVendidas, double precioUnitario,
                              double ingresosTotales, String ingresosTotalesFormateado, double porcentajeTotal) {
        this.posicion = posicion;
        this.nombre = nombre;
        this.unidadesVendidas = unidadesVendidas;
        this.precioUnitario = precioUnitario;
        this.ingresosTotales = ingresosTotales;
        this.ingresosTotalesFormateado = ingresosTotalesFormateado;
        this.porcentajeTotal = porcentajeTotal;
    }

    public int getPosicion() {
        return posicion;
    }

    public void setPosicion(int posicion) {
        this.posicion = posicion;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public int getUnidadesVendidas() {
        return unidadesVendidas;
    }

    public void setUnidadesVendidas(int unidadesVendidas) {
        this.unidadesVendidas = unidadesVendidas;
    }

    public double getPrecioUnitario() {
        return precioUnitario;
    }

    public void setPrecioUnitario(double precioUnitario) {
        this.precioUnitario = precioUnitario;
    }

    public double getIngresosTotales() {
        return ingresosTotales;
    }

    public void setIngresosTotales(double ingresosTotales) {
        this.ingresosTotales = ingresosTotales;
    }

    public String getIngresosTotalesFormateado() {
        return ingresosTotalesFormateado;
    }

    public void setIngresosTotalesFormateado(String ingresosTotalesFormateado) {
        this.ingresosTotalesFormateado = ingresosTotalesFormateado;
    }

    public double getPorcentajeTotal() {
        return porcentajeTotal;
    }

    public void setPorcentajeTotal(double porcentajeTotal) {
        this.porcentajeTotal = porcentajeTotal;
    }
}

