package com.example.rskitchen5.Service;

import com.example.rskitchen5.DTO.VentaSerieDTO;
import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Repository.PedidoRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

@Service
public class VentasSerieService {

    private final FacturaRep facturaRep;
    private final PedidoRep pedidoRep;
    private final Clock clock;

    @Autowired
    public VentasSerieService(FacturaRep facturaRep, PedidoRep pedidoRep) {
        this(facturaRep, pedidoRep, Clock.systemDefaultZone());
    }

    public VentasSerieService(FacturaRep facturaRep, PedidoRep pedidoRep, Clock clock) {
        this.facturaRep = facturaRep;
        this.pedidoRep = pedidoRep;
        this.clock = clock;
    }

    public FuenteVentas cargarFuente(Long restaurantId) {
        List<Factura> facturas = facturaRep.findByRestaurantId(restaurantId);
        if (!facturas.isEmpty()) {
            return new FuenteVentas(facturas, List.of(), true);
        }
        return new FuenteVentas(List.of(), pedidoRep.findByRestaurantId(restaurantId), false);
    }

    public List<VentaSerieDTO> obtenerSerie(Long restaurantId, String periodo, boolean anterior) {
        PeriodoVentas parsed = PeriodoVentas.from(periodo);
        Intervalo intervalo = crearIntervalo(parsed, anterior, LocalDateTime.now(clock));
        FuenteVentas fuente = cargarFuente(restaurantId);
        List<LocalDateTime> fechas = new ArrayList<>();
        List<Double> montos = new ArrayList<>();

        if (fuente.usaFacturas()) {
            for (Factura factura : fuente.facturas()) {
                agregarVenta(factura.getFecha(), factura.getTotal(), intervalo, fechas, montos);
            }
        } else {
            for (Pedido pedido : fuente.pedidos()) {
                agregarVenta(pedido.getFecha(), pedido.getTotal(), intervalo, fechas, montos);
            }
        }

        if (fechas.isEmpty()) {
            return List.of();
        }

        int cantidadBuckets = intervalo.bucketCount();
        double[] totales = new double[cantidadBuckets];
        LocalDateTime inicioBucket = inicioBucket(intervalo.start(), parsed);
        for (int i = 0; i < fechas.size(); i++) {
            int indice = (int) ChronoUnit.SECONDS.between(
                    inicioBucket, inicioBucket(fechas.get(i), parsed)) / (parsed.isHourly() ? 3600 : 86400);
            if (indice >= 0 && indice < totales.length) {
                totales[indice] += montos.get(i);
            }
        }

        List<VentaSerieDTO> serie = new ArrayList<>(cantidadBuckets);
        for (int i = 0; i < cantidadBuckets; i++) {
            LocalDateTime timestamp = parsed.isHourly()
                    ? inicioBucket.plusHours(i)
                    : inicioBucket.plusDays(i);
            serie.add(new VentaSerieDTO(timestamp, Math.round(totales[i] * 100.0) / 100.0));
        }
        return serie;
    }

    private void agregarVenta(
            LocalDateTime fecha,
            double monto,
            Intervalo intervalo,
            List<LocalDateTime> fechas,
            List<Double> montos) {
        if (fecha != null && !fecha.isBefore(intervalo.start()) && fecha.isBefore(intervalo.endExclusive())) {
            fechas.add(fecha);
            montos.add(monto);
        }
    }

    private Intervalo crearIntervalo(PeriodoVentas periodo, boolean anterior, LocalDateTime now) {
        LocalDate today = now.toLocalDate();
        LocalDateTime start;
        LocalDateTime end;
        int bucketCount;

        switch (periodo) {
            case HOY -> {
                start = today.atStartOfDay();
                bucketCount = now.getHour() + 1;
                end = now.plusNanos(1);
                if (anterior) {
                    start = start.minusDays(1);
                    end = end.minusDays(1);
                }
            }
            case SEMANA -> {
                LocalDate monday = today.with(DayOfWeek.MONDAY);
                start = monday.atStartOfDay();
                bucketCount = (int) ChronoUnit.DAYS.between(monday, today) + 1;
                end = now.plusNanos(1);
                if (anterior) {
                    start = start.minusWeeks(1);
                    end = end.minusWeeks(1);
                }
            }
            case MES -> {
                LocalDate firstDay = today.withDayOfMonth(1);
                start = firstDay.atStartOfDay();
                bucketCount = today.getDayOfMonth();
                end = now.plusNanos(1);
                if (anterior) {
                    LocalDate previousMonth = firstDay.minusMonths(1);
                    start = previousMonth.atStartOfDay();
                    int previousMonthDay = Math.min(today.getDayOfMonth(), previousMonth.lengthOfMonth());
                    end = previousMonth.plusDays(previousMonthDay - 1L)
                            .atTime(now.toLocalTime())
                            .plusNanos(1);
                    bucketCount = previousMonthDay;
                }
            }
            default -> throw new IllegalStateException("Período no soportado: " + periodo);
        }
        return new Intervalo(start, end, bucketCount);
    }

    private LocalDateTime inicioBucket(LocalDateTime fecha, PeriodoVentas periodo) {
        return periodo.isHourly()
                ? fecha.truncatedTo(ChronoUnit.HOURS)
                : fecha.toLocalDate().atStartOfDay();
    }

    public record FuenteVentas(List<Factura> facturas, List<Pedido> pedidos, boolean usaFacturas) {
    }

    private record Intervalo(LocalDateTime start, LocalDateTime endExclusive, int bucketCount) {
    }

    public enum PeriodoVentas {
        HOY,
        SEMANA,
        MES;

        public static PeriodoVentas from(String periodo) {
            if (periodo == null) {
                throw new IllegalArgumentException("El período es requerido");
            }
            return switch (periodo.trim().toLowerCase()) {
                case "hoy" -> HOY;
                case "semana" -> SEMANA;
                case "mes" -> MES;
                default -> throw new IllegalArgumentException("Período inválido. Use hoy, semana o mes");
            };
        }

        private boolean isHourly() {
            return this == HOY;
        }
    }
}
