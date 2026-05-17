package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Service.OptimizacionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Controller
@RequestMapping("/datos")
public class DatosController {

    @Autowired
    private OptimizacionService optimizacionService;

    @GetMapping
    public String mostrarDatos() {
        return "datos";
    }

    @GetMapping("/api/realtime")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getRealtime() {
        try {
            OptimizacionService.DatosReales datos =
                optimizacionService.obtenerDatosReales();

            Map<String, Object> r = new LinkedHashMap<>();
            r.put("totalPedidos",         datos.totalPedidos);
            r.put("x1VendidosReal",       datos.x1VendidosReal);
            r.put("x2VendidosReal",       datos.x2VendidosReal);
            r.put("ingresoReal",          datos.ingresoReal);
            r.put("platillosMasVendidos", datos.platillosMasVendidos);
            return ResponseEntity.ok(r);
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/api/optimo")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getOptimo() {
        try {
            OptimizacionService.ResultadoOptimizacion res =
                optimizacionService.resolver();

            Map<String, Object> r = new LinkedHashMap<>();
            r.put("estado",              "optimo");
            r.put("x1PlatosFuertes",     res.x1PlatosFuertes);
            r.put("x2PlatosSencillos",   res.x2PlatosSencillos);
            r.put("utilidadMaxima",      res.utilidadMaxima);
            r.put("costoTotal",          res.costoTotal);
            r.put("totalPlatillos",      res.totalPlatillos);
            r.put("restricciones",       res.restricciones);
            r.put("interpretacion",      res.interpretacion);
            r.put("x1Real",              res.x1Real);
            r.put("x2Real",              res.x2Real);
            r.put("diferenciaPotencial", res.diferenciaPotencial);
            r.put("modelo",              buildModeloInfo());
            return ResponseEntity.ok(r);
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(Map.of("estado", "error", "mensaje", e.getMessage()));
        }
    }

    @GetMapping("/api/evaluar")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> evaluar(
            @RequestParam(defaultValue = "60") double x1,
            @RequestParam(defaultValue = "60") double x2) {
        try {
            OptimizacionService.ResultadoEvaluacion res =
                optimizacionService.evaluar(x1, x2);

            Map<String, Object> r = new LinkedHashMap<>();
            r.put("x1",       res.x1);
            r.put("x2",       res.x2);
            r.put("utilidad", res.utilidad);
            r.put("factible", res.factible);
            r.put("detalle",  res.detalleRestricciones);
            return ResponseEntity.ok(r);
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/api/ranking")
    @ResponseBody
    public ResponseEntity<List<Map<String, Object>>> getRanking(
            @RequestParam(defaultValue = "5") int top) {
        try {
            List<double[]> topList = optimizacionService.topCombinaciones(top);
            List<Map<String, Object>> r = new ArrayList<>();
            int rank = 1;
            for (double[] combo : topList) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("posicion",          rank++);
                item.put("x1PlatosFuertes",   (int) combo[0]);
                item.put("x2PlatosSencillos", (int) combo[1]);
                item.put("utilidad",          combo[2]);
                r.add(item);
            }
            return ResponseEntity.ok(r);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(List.of());
        }
    }

    private Map<String, Object> buildModeloInfo() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("objetivo",      "Max Z = 12·X1 + 10·X2");
        m.put("variables",     List.of(
            "X1 = platos fuertes vendidos/día  ($12 c/u)",
            "X2 = platos sencillos vendidos/día ($10 c/u)"
        ));
        m.put("restricciones", List.of(
            "X1 ≤ 80", "X2 ≤ 60", "X1+X2 ≤ 120",
            "0.4·X1+0.2·X2 ≤ 36", "X1 ≥ 10", "X2 ≥ 10"
        ));
        return m;
    }
}
