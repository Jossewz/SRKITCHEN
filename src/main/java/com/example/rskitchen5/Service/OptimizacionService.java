package com.example.rskitchen5.Service;

import com.example.rskitchen5.Model.ItemPedido;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Repository.PedidoRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class OptimizacionService {

    @Autowired
    private PedidoRep pedidoRep;


    public static class DatosReales {
        public final long   totalPedidos;
        public final double x1VendidosReal;   
        public final double x2VendidosReal;   
        public final double ingresoReal;
        public final List<Map<String, Object>> platillosMasVendidos;

        public DatosReales(long totalPedidos, double x1, double x2,
                           double ingreso, List<Map<String, Object>> top) {
            this.totalPedidos         = totalPedidos;
            this.x1VendidosReal       = x1;
            this.x2VendidosReal       = x2;
            this.ingresoReal          = ingreso;
            this.platillosMasVendidos = top;
        }
    }

    public static class ResultadoOptimizacion {
        public final double x1PlatosFuertes;
        public final double x2PlatosSencillos;
        public final double utilidadMaxima;
        public final double costoTotal;
        public final double totalPlatillos;
        public final Map<String, Boolean> restricciones;
        public final String interpretacion;
        public final double x1Real;
        public final double x2Real;
        public final double diferenciaPotencial;

        public ResultadoOptimizacion(double x1, double x2,
                                     Map<String, Boolean> restricciones,
                                     String interpretacion,
                                     double x1Real, double x2Real,
                                     double ingresoReal) {
            this.x1PlatosFuertes     = x1;
            this.x2PlatosSencillos   = x2;
            this.utilidadMaxima      = 12 * x1 + 10 * x2;
            this.costoTotal          = 0.4 * x1 + 0.2 * x2;
            this.totalPlatillos      = x1 + x2;
            this.restricciones       = restricciones;
            this.interpretacion      = interpretacion;
            this.x1Real              = x1Real;
            this.x2Real              = x2Real;
            this.diferenciaPotencial = this.utilidadMaxima - ingresoReal;
        }
    }

    public static class ResultadoEvaluacion {
        public final double x1;
        public final double x2;
        public final double utilidad;
        public final boolean factible;
        public final Map<String, String> detalleRestricciones;

        public ResultadoEvaluacion(double x1, double x2,
                                   boolean factible,
                                   Map<String, String> detalle) {
            this.x1 = x1;
            this.x2 = x2;
            this.utilidad = 12 * x1 + 10 * x2;
            this.factible = factible;
            this.detalleRestricciones = detalle;
        }
    }

    public DatosReales obtenerDatosReales() {
        Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
        List<Pedido> pedidos = (restaurantId != null) 
                ? pedidoRep.findByRestaurantId(restaurantId) 
                : java.util.Collections.emptyList();
        long totalPedidos = pedidos.size();

        double x1 = 0, x2 = 0, ingreso = 0;
        Map<String, int[]> conteo = new LinkedHashMap<>(); // name -> [unidades]

        for (Pedido p : pedidos) {
            if (p.getItems() == null) continue;
            for (ItemPedido item : p.getItems()) {
                String cat = item.getCant() == null ? "" : item.getCant().toLowerCase();
                int uni = item.getUnidades() != null ? item.getUnidades() : 0;
                double precio = item.getPrice() != null ? item.getPrice() : 0.0;

                if (cat.contains("fuerte")) {
                    x1 += uni;
                    ingreso += uni * precio;
                } else if (cat.contains("sencillo")) {
                    x2 += uni;
                    ingreso += uni * precio;
                }

                // conteo por platillo
                String nombre = item.getName() == null ? "Desconocido" : item.getName();
                conteo.computeIfAbsent(nombre, k -> new int[]{0})[0] += uni;
            }
        }

        // Top 5 platillos más vendidos
        List<Map<String, Object>> top = conteo.entrySet().stream()
            .sorted((a, b) -> b.getValue()[0] - a.getValue()[0])
            .limit(5)
            .map(e -> {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("nombre",   e.getKey());
                m.put("unidades", e.getValue()[0]);
                return m;
            })
            .collect(Collectors.toList());

        return new DatosReales(totalPedidos, x1, x2, ingreso, top);
    }

    public ResultadoOptimizacion resolver() {
        DatosReales datos = obtenerDatosReales();

        double bestX1 = 10, bestX2 = 10;
        double bestZ  = objetivo(10, 10);

        for (double x1 = 10; x1 <= 80; x1++) {
            for (double x2 = 10; x2 <= 60; x2++) {
                if (esFeasible(x1, x2)) {
                    double z = objetivo(x1, x2);
                    if (z > bestZ) { bestZ = z; bestX1 = x1; bestX2 = x2; }
                }
            }
        }

        Map<String, Boolean> rest = buildRestricciones(bestX1, bestX2);

        String interp;
        if (datos.totalPedidos == 0) {
            interp = String.format(
                "No hay pedidos registrados aún. El modelo recomienda vender %.0f platos " +
                "fuertes y %.0f sencillos para alcanzar una utilidad de $%.2f.",
                bestX1, bestX2, bestZ
            );
        } else {
            double gap = bestZ - datos.ingresoReal;
            interp = String.format(
                "Con %d pedidos registrados, el restaurante ha vendido %.0f platos fuertes " +
                "y %.0f platos sencillos. El modelo óptimo recomienda %.0f y %.0f " +
                "respectivamente, generando $%.2f. %s",
                datos.totalPedidos,
                datos.x1VendidosReal, datos.x2VendidosReal,
                bestX1, bestX2, bestZ,
                gap > 0
                    ? String.format("Hay un potencial de mejora de $%.2f.", gap)
                    : "¡El restaurante ya opera cerca del óptimo!"
            );
        }

        return new ResultadoOptimizacion(bestX1, bestX2, rest, interp,
            datos.x1VendidosReal, datos.x2VendidosReal, datos.ingresoReal);
    }

    public ResultadoEvaluacion evaluar(double x1, double x2) {
        boolean[] flags = {
            x1 <= 80, x2 <= 60,
            (x1 + x2) <= 120,
            (0.4 * x1 + 0.2 * x2) <= 36,
            x1 >= 10, x2 >= 10
        };
        String[] nombres = {
            "X1 ≤ 80 (máx. platos fuertes)",
            "X2 ≤ 60 (máx. platos sencillos)",
            "X1+X2 ≤ 120 (capacidad total)",
            "0.4·X1+0.2·X2 ≤ 36 (costo insumos)",
            "X1 ≥ 10 (mín. platos fuertes)",
            "X2 ≥ 10 (mín. platos sencillos)"
        };

        Map<String, String> detalle = new LinkedHashMap<>();
        boolean factible = true;
        for (int i = 0; i < flags.length; i++) {
            detalle.put(nombres[i], flags[i] ? "✓ Cumple" : "✗ Viola");
            if (!flags[i]) factible = false;
        }
        return new ResultadoEvaluacion(x1, x2, factible, detalle);
    }

    public List<double[]> topCombinaciones(int top) {
        List<double[]> lista = new ArrayList<>();
        for (double x1 = 10; x1 <= 80; x1++) {
            for (double x2 = 10; x2 <= 60; x2++) {
                if (esFeasible(x1, x2))
                    lista.add(new double[]{x1, x2, objetivo(x1, x2)});
            }
        }
        lista.sort((a, b) -> Double.compare(b[2], a[2]));
        return lista.subList(0, Math.min(top, lista.size()));
    }

    private boolean esFeasible(double x1, double x2) {
        return x1 <= 80 && x2 <= 60
            && (x1 + x2) <= 120
            && (0.4 * x1 + 0.2 * x2) <= 36
            && x1 >= 10 && x2 >= 10;
    }

    private double objetivo(double x1, double x2) { return 12 * x1 + 10 * x2; }

    private Map<String, Boolean> buildRestricciones(double x1, double x2) {
        Map<String, Boolean> r = new LinkedHashMap<>();
        r.put("X1 ≤ 80",            x1 <= 80);
        r.put("X2 ≤ 60",            x2 <= 60);
        r.put("X1+X2 ≤ 120",        (x1 + x2) <= 120);
        r.put("0.4X1+0.2X2 ≤ 36",  (0.4*x1 + 0.2*x2) <= 36);
        r.put("X1 ≥ 10",            x1 >= 10);
        r.put("X2 ≥ 10",            x2 >= 10);
        return r;
    }
}