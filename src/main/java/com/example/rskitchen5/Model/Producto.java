package com.example.rskitchen5.Model;

import jakarta.persistence.*;

@Entity
@Table(name = "productos")
public class Producto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @Column(length = 1000)
    private String descripcion;

    @Column(name = "u_medida")
    private String uMedida;

    private String cant;
    private double price;
    private int stock;
    private Long restaurantId;

    @Column(nullable = false)
    private boolean activo = true;

    public Producto() {
        this.activo = true;
    }

    public Producto(String cant, Long id, String name, double price, int stock) {
        this.cant = cant;
        this.id = id;
        this.name = name;
        this.price = price;
        this.stock = stock;
        this.uMedida = cant;
        this.activo = true;
    }

    public Producto(String cant, Long id, String name, String descripcion, double price, int stock) {
        this.cant = cant;
        this.id = id;
        this.name = name;
        this.descripcion = descripcion;
        this.price = price;
        this.stock = stock;
        this.uMedida = cant;
        this.activo = true;
    }

    public Producto(Long id, String name, String descripcion, String cant, String uMedida, double price, int stock, boolean activo) {
        this.id = id;
        this.name = name;
        this.descripcion = descripcion;
        this.cant = cant;
        this.uMedida = uMedida;
        this.price = price;
        this.stock = stock;
        this.activo = activo;
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

    public String getDescription() {
        return descripcion;
    }

    public void setDescription(String description) {
        this.descripcion = description;
    }

    public String getuMedida() {
        return uMedida;
    }

    public void setuMedida(String uMedida) {
        this.uMedida = uMedida;
    }

    public String getUMedida() {
        return uMedida;
    }

    public void setUMedida(String uMedida) {
        this.uMedida = uMedida;
    }

    public String getUnidadMedida() {
        return uMedida;
    }

    public void setUnidadMedida(String unidadMedida) {
        this.uMedida = unidadMedida;
    }

    public String getCant() {
        return cant != null ? cant : uMedida;
    }

    public void setCant(String cant) {
        this.cant = cant;
        if (this.uMedida == null || this.uMedida.isEmpty()) {
            this.uMedida = cant;
        }
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

    public void setStock(String stockStr) {
        if (stockStr != null && !stockStr.trim().isEmpty()) {
            try {
                this.stock = Integer.parseInt(stockStr.trim());
            } catch (NumberFormatException ignored) {}
        }
    }

    public Long getRestaurantId() {
        return restaurantId;
    }

    public void setRestaurantId(Long restaurantId) {
        this.restaurantId = restaurantId;
    }

    public boolean isActivo() {
        return activo;
    }

    public boolean getActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }

    public void desactivar() {
        this.activo = false;
    }

    public void activar() {
        this.activo = true;
    }
}
