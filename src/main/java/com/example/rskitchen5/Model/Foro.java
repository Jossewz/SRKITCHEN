package com.example.rskitchen5.Model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "foros")
public class Foro {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String fnombre;

    @Column(length = 2000)
    private String fcomentario;

    private LocalDateTime fecha;

    public Foro() {
        this.fecha = LocalDateTime.now();
    }

    public Foro(String fnombre, String fcomentario, LocalDateTime fecha) {
        this.fnombre = fnombre;
        this.fcomentario = fcomentario;
        this.fecha = fecha != null ? fecha : LocalDateTime.now();
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

    public String getFnombre() {
        return fnombre;
    }

    public void setFnombre(String fnombre) {
        this.fnombre = fnombre;
    }

    public String getFcomentario() {
        return fcomentario;
    }

    public void setFcomentario(String fcomentario) {
        this.fcomentario = fcomentario;
    }

    public LocalDateTime getFecha() {
        return fecha;
    }

    public void setFecha(LocalDateTime fecha) {
        this.fecha = fecha;
    }
}
