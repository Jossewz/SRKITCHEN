package com.example.rskitchen5.Model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
@Table(name = "items_pedido")
public class ItemPedido {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pedido_id")
    private Pedido pedido;

    private String productId;
    private String name;
    private Double price = 0.0;
    private String cant;
    private Integer unidades = 0;

    public ItemPedido() {
    }

    public ItemPedido(String name, String cant, Double price, Integer unidades, String productId) {
        this.name = name;
        this.cant = cant;
        this.price = price;
        this.unidades = unidades;
        this.productId = productId;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Pedido getPedido() {
        return pedido;
    }

    public void setPedido(Pedido pedido) {
        this.pedido = pedido;
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

    public Integer getUnidades() {
        return unidades != null ? unidades : 0;
    }

    public void setUnidades(Integer unidades) {
        this.unidades = unidades;
        if (unidades != null && (this.cant == null || this.cant.isEmpty())) {
            this.cant = String.valueOf(unidades);
        }
    }

    public String getProductId() {
        return productId;
    }

    public void setProductId(String productId) {
        this.productId = productId;
    }

    public Double getPrice() {
        return price != null ? price : 0.0;
    }

    public void setPrice(Double price) {
        this.price = price;
    }

    public void setNombre(String name) {
        this.name = name;
    }

    public void setPrecio(Double price) {
        this.price = price;
    }

    public void setCantidad(Integer i) {
        this.unidades = i;
        this.cant = i != null ? String.valueOf(i) : "0";
    }
}
