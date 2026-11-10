package com.example.rskitchen5.DTO;

public class ProductoInventarioDTO {

    private Long id;
    private String name;
    private String descripcion;
    private String uMedida;
    private double price;
    private int stock;
    private boolean activo;
    private String nivelStock; // "CRITICO", "BAJO", "NORMAL"
    private String colorNivel; // "danger", "warning", "success"

    public ProductoInventarioDTO() {
    }

    public ProductoInventarioDTO(Long id, String name, String descripcion, String uMedida,
                                 double price, int stock, boolean activo, String nivelStock, String colorNivel) {
        this.id = id;
        this.name = name;
        this.descripcion = descripcion;
        this.uMedida = uMedida;
        this.price = price;
        this.stock = stock;
        this.activo = activo;
        this.nivelStock = nivelStock;
        this.colorNivel = colorNivel;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public String getUMedida() {
        return uMedida;
    }

    public void setUMedida(String uMedida) {
        this.uMedida = uMedida;
    }

    public double getPrice() {
        return price;
    }

    public void setPrice(double price) {
        this.price = price;
    }

    public int getStock() {
        return stock;
    }

    public void setStock(int stock) {
        this.stock = stock;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }

    public String getNivelStock() {
        return nivelStock;
    }

    public void setNivelStock(String nivelStock) {
        this.nivelStock = nivelStock;
    }

    public String getColorNivel() {
        return colorNivel;
    }

    public void setColorNivel(String colorNivel) {
        this.colorNivel = colorNivel;
    }
}

