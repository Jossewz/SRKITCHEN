package com.example.rskitchen5.DTO;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class PrediccionItemDTO {

    @JsonProperty("ranking")
    @JsonAlias({"posicion", "ranking"})
    private int ranking;

    @JsonProperty("platillo")
    private String platillo;

    @JsonProperty("unidadesProyectadas")
    @JsonAlias({"unidades_proyectadas", "unidadesProyectadas"})
    private int unidadesProyectadas;

    @JsonProperty("precioUnitarioCOP")
    @JsonAlias({"precio_unitario_COP", "precioUnitarioCOP"})
    private double precioUnitarioCOP;

    @JsonProperty("ingresosEstimadosCOP")
    @JsonAlias({"ingresos_estimados_COP", "ingresosEstimadosCOP"})
    private double ingresosEstimadosCOP;

    @JsonProperty("insumosCriticos")
    @JsonAlias({"insumos_criticos", "insumosCriticos"})
    private List<String> insumosCriticos = new ArrayList<>();

    @JsonProperty("serieDiaria")
    @JsonAlias({"serie_diaria", "serieDiaria"})
    private List<Map<String, Object>> serieDiaria = new ArrayList<>();

    public PrediccionItemDTO() {
    }

    public PrediccionItemDTO(int ranking, String platillo, int unidadesProyectadas, double precioUnitarioCOP,
            double ingresosEstimadosCOP, List<String> insumosCriticos) {
        this.ranking = ranking;
        this.platillo = platillo;
        this.unidadesProyectadas = unidadesProyectadas;
        this.precioUnitarioCOP = precioUnitarioCOP;
        this.ingresosEstimadosCOP = ingresosEstimadosCOP;
        this.insumosCriticos = insumosCriticos != null ? insumosCriticos : new ArrayList<>();
    }

    public int getRanking() {
        return ranking;
    }

    public void setRanking(int ranking) {
        this.ranking = ranking;
    }

    public String getPlatillo() {
        return platillo;
    }

    public void setPlatillo(String platillo) {
        this.platillo = platillo;
    }

    public int getUnidadesProyectadas() {
        return unidadesProyectadas;
    }

    public void setUnidadesProyectadas(int unidadesProyectadas) {
        this.unidadesProyectadas = unidadesProyectadas;
    }

    public double getPrecioUnitarioCOP() {
        return precioUnitarioCOP;
    }

    public void setPrecioUnitarioCOP(double precioUnitarioCOP) {
        this.precioUnitarioCOP = precioUnitarioCOP;
    }

    public double getIngresosEstimadosCOP() {
        return ingresosEstimadosCOP;
    }

    public void setIngresosEstimadosCOP(double ingresosEstimadosCOP) {
        this.ingresosEstimadosCOP = ingresosEstimadosCOP;
    }

    public List<String> getInsumosCriticos() {
        return insumosCriticos;
    }

    public void setInsumosCriticos(List<String> insumosCriticos) {
        this.insumosCriticos = insumosCriticos != null ? insumosCriticos : new ArrayList<>();
    }

    public List<Map<String, Object>> getSerieDiaria() {
        return serieDiaria;
    }

    public void setSerieDiaria(List<Map<String, Object>> serieDiaria) {
        this.serieDiaria = serieDiaria != null ? serieDiaria : new ArrayList<>();
    }

    public String getPrecioFormateado() {
        return String.format("%,.0f COP", precioUnitarioCOP);
    }

    public String getIngresosFormateado() {
        return String.format("%,.0f COP", ingresosEstimadosCOP);
    }
}
