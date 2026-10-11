package com.example.rskitchen5.Model;

import com.example.rskitchen5.DTO.EstadoFacturaDTO;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "facturas")
public class Factura {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String pedidoId;
    private String mesaNum;
    private String meseroName;
    private LocalDateTime fecha;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "factura_items",
        joinColumns = @JoinColumn(name = "factura_id"),
        inverseJoinColumns = @JoinColumn(name = "item_id")
    )
    private List<ItemPedido> items = new ArrayList<>();

    private double total;
    private boolean pagada;

    @Enumerated(EnumType.STRING)
    private EstadoFacturaDTO estado;

    public Factura() {
        this.estado = EstadoFacturaDTO.PENDIENTE;
        this.fecha = LocalDateTime.now();
    }

    public Factura(EstadoFacturaDTO estado, LocalDateTime fecha, Long id, List<ItemPedido> items, String mesaNum, String meseroName, boolean pagada, String pedidoId, double total) {
        this.estado = estado != null ? estado : EstadoFacturaDTO.PENDIENTE;
        this.fecha = fecha != null ? fecha : LocalDateTime.now();
        this.id = id;
        this.items = items != null ? items : new ArrayList<>();
        this.mesaNum = mesaNum;
        this.meseroName = meseroName;
        this.pagada = pagada;
        this.pedidoId = pedidoId;
        this.total = total;
    }

    public EstadoFacturaDTO getEstado() {
        return estado;
    }

    public void setEstado(EstadoFacturaDTO estado) {
        this.estado = estado;
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

    public LocalDateTime getFecha() {
        return fecha;
    }

    public void setFecha(LocalDateTime fecha) {
        this.fecha = fecha;
    }

    public List<ItemPedido> getItems() {
        return items != null ? items : new ArrayList<>();
    }

    public void setItems(List<ItemPedido> items) {
        this.items = items != null ? items : new ArrayList<>();
    }

    public String getMesaNum() {
        return mesaNum;
    }

    public void setMesaNum(String mesaNum) {
        this.mesaNum = mesaNum;
    }

    public String getMeseroName() {
        return meseroName;
    }

    public void setMeseroName(String meseroName) {
        this.meseroName = meseroName;
    }

    public boolean isPagada() {
        return pagada;
    }

    public void setPagada(boolean pagada) {
        this.pagada = pagada;
    }

    public String getPedidoId() {
        return pedidoId;
    }

    public void setPedidoId(String pedidoId) {
        this.pedidoId = pedidoId;
    }

    public double getTotal() {
        return total;
    }

    public void setTotal(double total) {
        this.total = total;
    }
}
