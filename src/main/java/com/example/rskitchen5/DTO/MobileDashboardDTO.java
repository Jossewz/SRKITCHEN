package com.example.rskitchen5.DTO;

import java.util.List;
import java.util.Map;

public class MobileDashboardDTO {

    private Map<String, Object> restaurante;
    private VentasTotalesDTO ventasTotales;
    private PromedioVentasDTO promedioVentas;
    private MejorVentaDTO mejorVenta;
    private PlatilloRankingDTO platilloMasVendido;
    private List<PlatilloRankingDTO> topPlatillos;
    private InventarioNivelesDTO resumenInventario;

    public MobileDashboardDTO() {
    }

    public MobileDashboardDTO(Map<String, Object> restaurante, VentasTotalesDTO ventasTotales,
                              PromedioVentasDTO promedioVentas, MejorVentaDTO mejorVenta,
                              PlatilloRankingDTO platilloMasVendido, List<PlatilloRankingDTO> topPlatillos,
                              InventarioNivelesDTO resumenInventario) {
        this.restaurante = restaurante;
        this.ventasTotales = ventasTotales;
        this.promedioVentas = promedioVentas;
        this.mejorVenta = mejorVenta;
        this.platilloMasVendido = platilloMasVendido;
        this.topPlatillos = topPlatillos;
        this.resumenInventario = resumenInventario;
    }

    public Map<String, Object> getRestaurante() {
        return restaurante;
    }

    public void setRestaurante(Map<String, Object> restaurante) {
        this.restaurante = restaurante;
    }

    public VentasTotalesDTO getVentasTotales() {
        return ventasTotales;
    }

    public void setVentasTotales(VentasTotalesDTO ventasTotales) {
        this.ventasTotales = ventasTotales;
    }

    public PromedioVentasDTO getPromedioVentas() {
        return promedioVentas;
    }

    public void setPromedioVentas(PromedioVentasDTO promedioVentas) {
        this.promedioVentas = promedioVentas;
    }

    public MejorVentaDTO getMejorVenta() {
        return mejorVenta;
    }

    public void setMejorVenta(MejorVentaDTO mejorVenta) {
        this.mejorVenta = mejorVenta;
    }

    public PlatilloRankingDTO getPlatilloMasVendido() {
        return platilloMasVendido;
    }

    public void setPlatilloMasVendido(PlatilloRankingDTO platilloMasVendido) {
        this.platilloMasVendido = platilloMasVendido;
    }

    public List<PlatilloRankingDTO> getTopPlatillos() {
        return topPlatillos;
    }

    public void setTopPlatillos(List<PlatilloRankingDTO> topPlatillos) {
        this.topPlatillos = topPlatillos;
    }

    public InventarioNivelesDTO getResumenInventario() {
        return resumenInventario;
    }

    public void setResumenInventario(InventarioNivelesDTO resumenInventario) {
        this.resumenInventario = resumenInventario;
    }
}

