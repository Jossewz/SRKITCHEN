package com.example.rskitchen5.DTO;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDate;
import java.util.*;

@JsonIgnoreProperties(ignoreUnknown = true)
public class DemandaDiariaDTO {

    @JsonProperty("fechas")
    private List<String> fechas = new ArrayList<>();

    @JsonProperty("series")
    private Map<String, List<Double>> series = new HashMap<>();

    @JsonProperty("totalDiario")
    @JsonAlias({"total_diario", "totalDiario"})
    private List<Double> totalDiario = new ArrayList<>();

    public DemandaDiariaDTO() {
    }

    public static DemandaDiariaDTO crearFallback(int dias) {
        DemandaDiariaDTO dto = new DemandaDiariaDTO();
        int n = dias > 0 ? dias : 7;
        LocalDate hoy = LocalDate.now();
        List<String> fechas = new ArrayList<>();
        for (int i = 1; i <= n; i++) {
            fechas.add(hoy.plusDays(i).toString());
        }
        dto.setFechas(fechas);

        Map<String, List<Double>> s = new LinkedHashMap<>();
        // Patrones sintéticos calibrados según el día
        s.put("Cerveza Artesanal", generarValores(n, 2.7, 0.6));
        s.put("Hamburguesa rsKitchen", generarValores(n, 2.5, 0.7));
        s.put("Pizza Margarita", generarValores(n, 2.5, 0.6));
        s.put("Pasta Carbonara", generarValores(n, 2.1, 0.5));
        s.put("Corte de Carne", generarValores(n, 2.0, 0.4));
        s.put("Limonada Natural", generarValores(n, 1.8, 0.3));
        s.put("Ensalada Cesar", generarValores(n, 1.7, 0.3));
        s.put("Sopa del Dia", generarValores(n, 1.7, 0.3));
        dto.setSeries(s);

        List<Double> tot = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            double sum = 0;
            for (List<Double> v : s.values()) {
                sum += v.get(i);
            }
            tot.add(Math.round(sum * 10.0) / 10.0);
        }
        dto.setTotalDiario(tot);

        return dto;
    }

    private static List<Double> generarValores(int n, double base, double variacion) {
        List<Double> list = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            // simular picos de fin de semana
            double factor = (i % 7 >= 4) ? 1.35 : 0.85;
            double val = Math.round((base * factor) * 10.0) / 10.0;
            list.add(Math.max(1.0, val));
        }
        return list;
    }

    public List<String> getFechas() {
        return fechas;
    }

    public void setFechas(List<String> fechas) {
        this.fechas = fechas;
    }

    public Map<String, List<Double>> getSeries() {
        return series;
    }

    public void setSeries(Map<String, List<Double>> series) {
        this.series = series;
    }

    public List<Double> getTotalDiario() {
        return totalDiario;
    }

    public void setTotalDiario(List<Double> totalDiario) {
        this.totalDiario = totalDiario;
    }
}
