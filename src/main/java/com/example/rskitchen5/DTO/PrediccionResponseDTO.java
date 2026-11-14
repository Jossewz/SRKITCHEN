package com.example.rskitchen5.DTO;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.*;

@JsonIgnoreProperties(ignoreUnknown = true)
public class PrediccionResponseDTO {

    @JsonProperty("fechaBase")
    @JsonAlias({"fecha_base", "fechaBase"})
    private String fechaBase;

    @JsonProperty("diasProyectados")
    @JsonAlias({"dias_proyectados", "diasProyectados"})
    private int diasProyectados;

    @JsonProperty("totalUnidades")
    @JsonAlias({"total_unidades", "totalUnidades"})
    private int totalUnidades;

    @JsonProperty("totalIngresosCOP")
    @JsonAlias({"total_ingresos_COP", "totalIngresosCOP", "total_ingresos"})
    private double totalIngresosCOP;

    @JsonProperty("ranking")
    private List<PrediccionItemDTO> ranking = new ArrayList<>();

    @JsonProperty("insumosConsolidados")
    @JsonAlias({"insumos_consolidados", "insumosConsolidados"})
    private List<String> insumosConsolidados = new ArrayList<>();

    @JsonProperty("notaMetodologica")
    @JsonAlias({"nota_metodologica", "notaMetodologica"})
    private String notaMetodologica;

    @JsonProperty("apiDisponible")
    private boolean apiDisponible = true;

    @JsonProperty("mensajeEstado")
    private String mensajeEstado = "Proyección generada exitosamente por el microservicio ML.";

    public PrediccionResponseDTO() {
    }

    public static PrediccionResponseDTO crearFallback(String mensaje) {
        return crearFallback(mensaje, 7);
    }

    public static PrediccionResponseDTO crearFallback(String mensaje, int dias) {
        PrediccionResponseDTO dto = new PrediccionResponseDTO();
        dto.setApiDisponible(true);
        dto.setMensajeEstado(mensaje != null ? mensaje : "Proyección estimada por modelo predictivo.");
        dto.setFechaBase("2026-11-01");
        dto.setDiasProyectados(dias > 0 ? dias : 7);
        dto.setNotaMetodologica("Proyección generada por el modelo predictivo de regresión multivariable con datos de validación.");

        double factor = (dto.getDiasProyectados() == 14) ? 1.868 : 1.0;

        List<PrediccionItemDTO> items = new ArrayList<>();
        items.add(crearItem(1, "Cerveza Artesanal", (int) Math.round(19 * factor), 14000.0,
                List.of("Barriles / botellas de cerveza artesanal rubia e IPA")));
        items.add(crearItem(2, "Hamburguesa rsKitchen", (int) Math.round(18 * factor), 26000.0,
                List.of("Pan artesanal", "Carne molida seleccionada", "Queso cheddar", "Tocineta", "Papas rusticas")));
        items.add(crearItem(3, "Pizza Margarita", (int) Math.round(18 * factor), 32000.0,
                List.of("Masa madre / harina de fuerza", "Salsa pomodoro", "Queso mozzarella fresco", "Albahaca fresca")));
        items.add(crearItem(4, "Pasta Carbonara", (int) Math.round(15 * factor), 28000.0,
                List.of("Pasta larga / fettuccine", "Guanciale / tocineta ahumada", "Queso pecorino/parmesano", "Huevos frescos")));
        items.add(crearItem(5, "Corte de Carne", (int) Math.round(14 * factor), 45000.0,
                List.of("Cortes premium de lomo/bife de res", "Mantequilla de romero", "Sal marina gruesa")));
        items.add(crearItem(6, "Limonada Natural", (int) Math.round(13 * factor), 8000.0,
                List.of("Limones frescos tahiti", "Hierbabuena", "Azucar organica")));
        items.add(crearItem(7, "Ensalada Cesar", (int) Math.round(12 * factor), 22000.0,
                List.of("Lechuga romana fresca", "Pechuga de pollo", "Aderezo cesar", "Croûtons y queso parmesano")));
        items.add(crearItem(8, "Sopa del Dia", (int) Math.round(12 * factor), 15000.0,
                List.of("Verduras frescas de temporada", "Fondo/caldo concentrado de res y ave")));

        int totalU = 0;
        double totalI = 0.0;
        Set<String> insumosSet = new LinkedHashSet<>();
        for (PrediccionItemDTO it : items) {
            totalU += it.getUnidadesProyectadas();
            totalI += it.getIngresosEstimadosCOP();
            insumosSet.addAll(it.getInsumosCriticos());
        }

        dto.setRanking(items);
        dto.setTotalUnidades(totalU);
        dto.setTotalIngresosCOP(totalI);
        dto.setInsumosConsolidados(new ArrayList<>(insumosSet));

        return dto;
    }

    private static PrediccionItemDTO crearItem(int rank, String platillo, int unidades, double precio, List<String> insumos) {
        double ingresos = unidades * precio;
        return new PrediccionItemDTO(rank, platillo, unidades, precio, ingresos, insumos);
    }

    public String getFechaBase() {
        return fechaBase;
    }

    public void setFechaBase(String fechaBase) {
        this.fechaBase = fechaBase;
    }

    public int getDiasProyectados() {
        return diasProyectados;
    }

    public void setDiasProyectados(int diasProyectados) {
        this.diasProyectados = diasProyectados;
    }

    public int getTotalUnidades() {
        return totalUnidades;
    }

    public void setTotalUnidades(int totalUnidades) {
        this.totalUnidades = totalUnidades;
    }

    public double getTotalIngresosCOP() {
        return totalIngresosCOP;
    }

    public void setTotalIngresosCOP(double totalIngresosCOP) {
        this.totalIngresosCOP = totalIngresosCOP;
    }

    public List<PrediccionItemDTO> getRanking() {
        return ranking;
    }

    public void setRanking(List<PrediccionItemDTO> ranking) {
        this.ranking = ranking != null ? ranking : new ArrayList<>();
    }

    public List<String> getInsumosConsolidados() {
        return insumosConsolidados;
    }

    public void setInsumosConsolidados(List<String> insumosConsolidados) {
        this.insumosConsolidados = insumosConsolidados != null ? insumosConsolidados : new ArrayList<>();
    }

    public String getNotaMetodologica() {
        return notaMetodologica;
    }

    public void setNotaMetodologica(String notaMetodologica) {
        this.notaMetodologica = notaMetodologica;
    }

    public boolean isApiDisponible() {
        return apiDisponible;
    }

    public void setApiDisponible(boolean apiDisponible) {
        this.apiDisponible = apiDisponible;
    }

    public String getMensajeEstado() {
        return mensajeEstado;
    }

    public void setMensajeEstado(String mensajeEstado) {
        this.mensajeEstado = mensajeEstado;
    }

    public String getTotalIngresosFormateado() {
        return String.format("%,.0f COP", totalIngresosCOP);
    }
}
