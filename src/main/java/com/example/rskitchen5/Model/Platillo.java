package com.example.rskitchen5.Model;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "platillos")
public class Platillo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private double price;

    private String cant;
    private Long restaurantId;

    @OneToMany(mappedBy = "platillo", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<PlatilloIngrediente> ingredientes = new ArrayList<>();

    public Platillo() {
    }

    public Platillo(String cant, String description, Long id, String name, double price) {
        this.cant = cant;
        this.id = id;
        this.name = name;
        this.price = price;
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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Long getRestaurantId() {
        return restaurantId;
    }

    public void setRestaurantId(Long restaurantId) {
        this.restaurantId = restaurantId;
    }

    public List<PlatilloIngrediente> getIngredientes() {
        return ingredientes != null ? ingredientes : new ArrayList<>();
    }

    public void setIngredientes(List<PlatilloIngrediente> ingredientes) {
        this.ingredientes.clear();
        if (ingredientes != null) {
            for (PlatilloIngrediente ing : ingredientes) {
                ing.setPlatillo(this);
                this.ingredientes.add(ing);
            }
        }
    }

    public void addIngrediente(PlatilloIngrediente ing) {
        if (ing != null) {
            ing.setPlatillo(this);
            this.ingredientes.add(ing);
        }
    }

    public void removeIngrediente(PlatilloIngrediente ing) {
        if (ing != null) {
            this.ingredientes.remove(ing);
            ing.setPlatillo(null);
        }
    }

    /**
     * Determina si el platillo está disponible para la venta.
     * Si no tiene receta registrada, está disponible por defecto.
     * Si tiene receta, verifica que cada ingrediente tenga stock suficiente.
     */
    public boolean isDisponible() {
        if (ingredientes == null || ingredientes.isEmpty()) {
            return true;
        }
        for (PlatilloIngrediente ing : ingredientes) {
            if (ing.getProducto() != null) {
                if (ing.getProducto().getStock() < ing.getCantidad()) {
                    return false;
                }
            }
        }
        return true;
    }
}
