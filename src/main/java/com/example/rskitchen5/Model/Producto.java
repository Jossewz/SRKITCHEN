package com.example.rskitchen5.Model;

import jakarta.persistence.*;

@Entity
@Table(name = "productos")
public class Producto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String cant;
    private double price;
    private int stock;

    public Producto() {
    }

    public Producto(String cant, Long id, String name, double price, int stock) {
        this.cant = cant;
        this.id = id;
        this.name = name;
        this.price = price;
        this.stock = stock;
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

    public String getCant() {
        return cant;
    }

    public void setCant(String cant) {
        this.cant = cant;
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
}