package com.example.rskitchen5.Model;

import com.example.rskitchen5.DTO.EstadoFacturaDTO;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;
import java.util.List;

@Document(collection = "facturas")
public class Factura {
    @Id
    private String id;
    private String pedidoId;
    private String mesaNum;
    private String meseroName;
    private LocalDateTime fecha;
    private List<ItemPedido> items;
    private Double total;
    private Boolean pagada;
    private EstadoFacturaDTO estado;

    public Factura() {
        this.estado = EstadoFacturaDTO.PENDIENTE;
    }

    public Factura(EstadoFacturaDTO estado, LocalDateTime fecha, String id, List<ItemPedido> items, String mesaNum,
            String meseroName, Boolean pagada, String pedidoId, Double total) {
        this.estado = estado;
        this.fecha = fecha;
        this.id = id;
        this.items = items;
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
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public LocalDateTime getFecha() {
        return fecha;
    }

    public void setFecha(LocalDateTime fecha) {
        this.fecha = fecha;
    }

    public List<ItemPedido> getItems() {
        return items;
    }

    public void setItems(List<ItemPedido> items) {
        this.items = items;
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

    public Boolean isPagada() {
        return pagada;
    }

    public void setPagada(Boolean pagada) {
        this.pagada = pagada;
    }

    public String getPedidoId() {
        return pedidoId;
    }

    public void setPedidoId(String pedidoId) {
        this.pedidoId = pedidoId;
    }

    public Double getTotal() {
        return total;
    }

    public void setTotal(Double total) {
        this.total = total;
    }
}
