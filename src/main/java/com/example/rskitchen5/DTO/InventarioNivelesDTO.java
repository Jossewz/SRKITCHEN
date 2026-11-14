package com.example.rskitchen5.DTO;

import java.util.ArrayList;
import java.util.List;

public class InventarioNivelesDTO {

    private int totalProductos;
    private int conteoCriticos;
    private int conteoBajos;
    private int conteoNormales;
    private boolean requiereAtencion;

    private List<ProductoInventarioDTO> criticos = new ArrayList<>();
    private List<ProductoInventarioDTO> bajos = new ArrayList<>();
    private List<ProductoInventarioDTO> normales = new ArrayList<>();

    public InventarioNivelesDTO() {
    }

    public InventarioNivelesDTO(int totalProductos, int conteoCriticos, int conteoBajos, int conteoNormales,
                                boolean requiereAtencion, List<ProductoInventarioDTO> criticos,
                                List<ProductoInventarioDTO> bajos, List<ProductoInventarioDTO> normales) {
        this.totalProductos = totalProductos;
        this.conteoCriticos = conteoCriticos;
        this.conteoBajos = conteoBajos;
        this.conteoNormales = conteoNormales;
        this.requiereAtencion = requiereAtencion;
        this.criticos = criticos != null ? criticos : new ArrayList<>();
        this.bajos = bajos != null ? bajos : new ArrayList<>();
        this.normales = normales != null ? normales : new ArrayList<>();
    }

    public int getTotalProductos() {
        return totalProductos;
    }

    public void setTotalProductos(int totalProductos) {
        this.totalProductos = totalProductos;
    }

    public int getConteoCriticos() {
        return conteoCriticos;
    }

    public void setConteoCriticos(int conteoCriticos) {
        this.conteoCriticos = conteoCriticos;
    }

    public int getConteoBajos() {
        return conteoBajos;
    }

    public void setConteoBajos(int conteoBajos) {
        this.conteoBajos = conteoBajos;
    }

    public int getConteoNormales() {
        return conteoNormales;
    }

    public void setConteoNormales(int conteoNormales) {
        this.conteoNormales = conteoNormales;
    }

    public boolean isRequiereAtencion() {
        return requiereAtencion;
    }

    public void setRequiereAtencion(boolean requiereAtencion) {
        this.requiereAtencion = requiereAtencion;
    }

    public List<ProductoInventarioDTO> getCriticos() {
        return criticos;
    }

    public void setCriticos(List<ProductoInventarioDTO> criticos) {
        this.criticos = criticos;
    }

    public List<ProductoInventarioDTO> getBajos() {
        return bajos;
    }

    public void setBajos(List<ProductoInventarioDTO> bajos) {
        this.bajos = bajos;
    }

    public List<ProductoInventarioDTO> getNormales() {
        return normales;
    }

    public void setNormales(List<ProductoInventarioDTO> normales) {
        this.normales = normales;
    }
}

