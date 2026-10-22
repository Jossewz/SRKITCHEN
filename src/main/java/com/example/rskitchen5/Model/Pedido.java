package com.example.rskitchen5.Model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "pedidos")
public class Pedido {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private int mesaNum;
    private String meseroName;
    private String mesaId;
    private String meseroId;

    private LocalDateTime fecha;

    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<ItemPedido> items = new ArrayList<>();

    private double total;
    private boolean pagado;
    private Long restaurantId;

    public Pedido() {
        this.fecha = LocalDateTime.now();
    }

    public Pedido(LocalDateTime fecha, Long id, List<ItemPedido> items, int mesaNum, String mesaId, String meseroId, boolean pagado, double total, String meseroName) {
        this.fecha = fecha != null ? fecha : LocalDateTime.now();
        this.id = id;
        this.setItems(items);
        this.mesaNum = mesaNum;
        this.mesaId = mesaId;
        this.meseroId = meseroId;
        this.pagado = pagado;
        this.total = total;
        this.meseroName = meseroName;
    }

    public LocalDateTime getFecha() {
        return fecha;
    }

    public void setFecha(LocalDateTime fecha) {
        this.fecha = fecha;
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

    public List<ItemPedido> getItems() {
        return items != null ? items : new ArrayList<>();
    }

    public void setItems(List<ItemPedido> items) {
        this.items.clear();
        if (items != null) {
            for (ItemPedido item : items) {
                item.setPedido(this);
                this.items.add(item);
            }
        }
    }

    public String getMesaId() {
        return mesaId;
    }

    public void setMesaId(String mesaId) {
        this.mesaId = mesaId;
    }

    public int getMesaNum() {
        return mesaNum;
    }

    public void setMesaNum(int mesaNum) {
        this.mesaNum = mesaNum;
    }

    public String getMeseroId() {
        return meseroId;
    }

    public void setMeseroId(String meseroId) {
        this.meseroId = meseroId;
    }

    public String getMeseroName() {
        return meseroName;
    }

    public void setMeseroName(String meseroName) {
        this.meseroName = meseroName;
    }

    public boolean isPagado() {
        return pagado;
    }

    public void setPagado(boolean pagado) {
        this.pagado = pagado;
    }

    public double getTotal() {
        return total;
    }

    public void setTotal(double total) {
        this.total = total;
    }

    public Long getRestaurantId() {
        return restaurantId;
    }

    public void setRestaurantId(Long restaurantId) {
        this.restaurantId = restaurantId;
    }
}