package com.example.rskitchen5.service;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Repository.PedidoRep;
import com.example.rskitchen5.Service.VentasSerieService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class VentasSerieServiceTest {

    private static final long RESTAURANT_ID = 17L;
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 11, 10, 10, 30);

    private FacturaRep facturaRep;
    private PedidoRep pedidoRep;
    private VentasSerieService service;

    @BeforeEach
    void setUp() {
        facturaRep = mock(FacturaRep.class);
        pedidoRep = mock(PedidoRep.class);
        Clock clock = Clock.fixed(
                Instant.parse("2026-11-10T10:30:00Z"),
                ZoneId.of("UTC"));
        service = new VentasSerieService(facturaRep, pedidoRep, clock);
        when(facturaRep.findByRestaurantId(RESTAURANT_ID)).thenReturn(List.of());
        when(pedidoRep.findByRestaurantId(RESTAURANT_ID)).thenReturn(List.of());
    }

    @Test
    void agrupaVentasPorHoraEnOrdenYRedondeaElMonto() {
        when(facturaRep.findByRestaurantId(RESTAURANT_ID)).thenReturn(List.of(
                factura(LocalDateTime.of(2026, 11, 10, 10, 12), 0.2),
                factura(LocalDateTime.of(2026, 11, 10, 9, 59), 0.1),
                factura(LocalDateTime.of(2026, 11, 10, 10, 0), 0.1)));

        var serie = service.obtenerSerie(RESTAURANT_ID, "hoy", false);

        assertEquals(11, serie.size());
        assertEquals(LocalDateTime.of(2026, 11, 10, 0, 0), serie.get(0).getTimestamp());
        assertEquals(0.1, serie.get(9).getMonto(), 0.001);
        assertEquals(0.3, serie.get(10).getMonto(), 0.001);
    }

    @Test
    void respetaLimitesDeDiaSemanaYMesYCalculaIntervaloAnterior() {
        when(facturaRep.findByRestaurantId(RESTAURANT_ID)).thenReturn(List.of(
                factura(LocalDateTime.of(2026, 11, 9, 23, 59), 50),
                factura(LocalDateTime.of(2026, 11, 10, 10, 30), 70),
                factura(LocalDateTime.of(2026, 11, 10, 10, 31), 100),
                factura(LocalDateTime.of(2026, 11, 11, 0, 0), 200),
                factura(LocalDateTime.of(2026, 10, 10, 10, 30), 30),
                factura(LocalDateTime.of(2026, 10, 10, 10, 31), 40)));

        var semana = service.obtenerSerie(RESTAURANT_ID, "semana", false);
        var mesAnterior = service.obtenerSerie(RESTAURANT_ID, "mes", true);

        assertEquals(2, semana.size());
        assertEquals(50, semana.get(0).getMonto());
        assertEquals(70, semana.get(1).getMonto());
        assertEquals(10, mesAnterior.size());
        assertEquals(30, mesAnterior.get(9).getMonto());
    }

    @Test
    void usaPedidosSoloCuandoNoHayFacturasYDevuelveVacioSinVentas() {
        Pedido pedido = new Pedido();
        pedido.setFecha(NOW);
        pedido.setTotal(125.5);
        when(pedidoRep.findByRestaurantId(RESTAURANT_ID)).thenReturn(List.of(pedido));

        var seriePedidos = service.obtenerSerie(RESTAURANT_ID, "hoy", false);
        when(facturaRep.findByRestaurantId(RESTAURANT_ID)).thenReturn(List.of(
                factura(NOW, 20)));
        var serieFacturas = service.obtenerSerie(RESTAURANT_ID, "hoy", false);

        assertEquals(125.5, seriePedidos.get(10).getMonto());
        assertEquals(20, serieFacturas.get(10).getMonto());
        when(facturaRep.findByRestaurantId(RESTAURANT_ID)).thenReturn(List.of());
        when(pedidoRep.findByRestaurantId(RESTAURANT_ID)).thenReturn(List.of());
        assertTrue(service.obtenerSerie(RESTAURANT_ID, "hoy", false).isEmpty());
    }

    private Factura factura(LocalDateTime fecha, double total) {
        Factura factura = new Factura();
        factura.setFecha(fecha);
        factura.setTotal(total);
        return factura;
    }
}
