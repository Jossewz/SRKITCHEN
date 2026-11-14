package com.example.rskitchen5.DTO;

import java.time.LocalDateTime;
import java.util.List;

public class PedidoDetalleDTO {

    private String id;
    private LocalDateTime fecha;
    private Double total;
    private Boolean pagado;
    private String nombreMesero;
    private List<ItemPedidoDetalleDTO> items;

    public LocalDateTime getFecha() {
        return fecha;
    }

    public void setFecha(LocalDateTime fecha) {
        this.fecha = fecha;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public List<ItemPedidoDetalleDTO> getItems() {
        return items;
    }

    public void setItems(List<ItemPedidoDetalleDTO> items) {
        this.items = items;
    }

    public Double getTotal() {
        return total;
    }

    public void setTotal(Double total) {
        this.total = total;
    }

    public Boolean isPagado() {
        return pagado;
    }

    public void setPagado(Boolean pagado) {
        this.pagado = pagado;
    }

    public String getNombreMesero() {
        return nombreMesero;
    }

    public void setNombreMesero(String nombreMesero) {
        this.nombreMesero = nombreMesero;
    }
}
