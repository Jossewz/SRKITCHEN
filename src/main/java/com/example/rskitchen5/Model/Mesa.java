package com.example.rskitchen5.Model;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "mesas")
public class Mesa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private int num;

    private boolean ocupado;

    private String meseroId;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "mesa_pedidos", joinColumns = @JoinColumn(name = "mesa_id"))
    @Column(name = "pedido_id")
    private List<String> pedidosId = new ArrayList<>();

    public Mesa() {
    }

    public Mesa(Long id, String meseroId, List<String> pedidosId, boolean ocupado, int num) {
        this.id = id;
        this.meseroId = meseroId;
        this.pedidosId = pedidosId != null ? pedidosId : new ArrayList<>();
        this.ocupado = ocupado;
        this.num = num;
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

    public String getMeseroId() {
        return meseroId;
    }

    public void setMeseroId(String meseroId) {
        this.meseroId = meseroId;
    }

    public int getNum() {
        return num;
    }

    public void setNum(int num) {
        this.num = num;
    }

    public boolean isOcupado() {
        return ocupado;
    }

    public void setOcupado(boolean ocupado) {
        this.ocupado = ocupado;
    }

    public List<String> getPedidosId() {
        return pedidosId != null ? pedidosId : new ArrayList<>();
    }

    public void setPedidosId(List<String> pedidosId) {
        this.pedidosId = pedidosId != null ? pedidosId : new ArrayList<>();
    }
}
