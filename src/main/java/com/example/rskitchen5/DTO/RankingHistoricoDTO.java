package com.example.rskitchen5.DTO;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class RankingHistoricoDTO {

    @JsonProperty("porPlatillo")
    @JsonAlias({"por_platillo", "porPlatillo"})
    private List<Map<String, Object>> porPlatillo = new ArrayList<>();

    @JsonProperty("porDiaSemana")
    @JsonAlias({"por_dia_semana", "porDiaSemana"})
    private Map<String, Object> porDiaSemana = new HashMap<>();

    @JsonProperty("totalPedidosHistoricos")
    @JsonAlias({"total_pedidos", "totalPedidosHistoricos"})
    private int totalPedidosHistoricos;

    @JsonProperty("totalIngresosHistoricos")
    @JsonAlias({"total_ingresos", "totalIngresosHistoricos"})
    private double totalIngresosHistoricos;

    public RankingHistoricoDTO() {
    }

    public List<Map<String, Object>> getPorPlatillo() {
        return porPlatillo;
    }

    public void setPorPlatillo(List<Map<String, Object>> porPlatillo) {
        this.porPlatillo = porPlatillo;
    }

    public Map<String, Object> getPorDiaSemana() {
        return porDiaSemana;
    }

    public void setPorDiaSemana(Map<String, Object> porDiaSemana) {
        this.porDiaSemana = porDiaSemana;
    }

    public int getTotalPedidosHistoricos() {
        return totalPedidosHistoricos;
    }

    public void setTotalPedidosHistoricos(int totalPedidosHistoricos) {
        this.totalPedidosHistoricos = totalPedidosHistoricos;
    }

    public double getTotalIngresosHistoricos() {
        return totalIngresosHistoricos;
    }

    public void setTotalIngresosHistoricos(double totalIngresosHistoricos) {
        this.totalIngresosHistoricos = totalIngresosHistoricos;
    }
}
