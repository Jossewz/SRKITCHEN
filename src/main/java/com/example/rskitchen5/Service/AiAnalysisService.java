package com.example.rskitchen5.Service;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Model.ItemPedido;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Repository.PedidoRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class AiAnalysisService {

    @Autowired
    private GroqApiClient groqApiClient;

    @Autowired
    private FacturaRep facturaRep;

    @Autowired
    private PedidoRep pedidoRep;

    public String analyzeTopDishes() {
        List<Pedido> pedidos = pedidoRep.findAll();
        
        // Summarize data to avoid exceeding context window
        Map<String, Integer> ventasPorPlatillo = new HashMap<>();
        int totalPedidos = pedidos.size();
        
        for (Pedido p : pedidos) {
            if (p.getItems() != null) {
                for (ItemPedido item : p.getItems()) {
                    String nombre = item.getName();
                    int cantidad = item.getUnidades();
                    ventasPorPlatillo.put(nombre, ventasPorPlatillo.getOrDefault(nombre, 0) + cantidad);
                }
            }
        }
        
        // Convert to a simple string
        String dataSummary = ventasPorPlatillo.entrySet().stream()
                .map(e -> e.getKey() + ": " + e.getValue() + " vendidos")
                .collect(Collectors.joining(", "));

        String prompt = "Eres un asistente experto en restaurantes. Actúa de manera profesional y amable. "
                + "Aquí tienes un resumen de los platillos más vendidos de nuestro restaurante basado en " + totalPedidos + " pedidos totales:\n\n"
                + dataSummary + "\n\n"
                + "Por favor, analiza estos datos brevemente, dime cuáles son los platillos que más se están vendiendo, "
                + "por qué crees que son populares y qué estrategias de marketing me recomiendas para los menos vendidos.";

        return groqApiClient.askGroq(prompt);
    }

    public String analyzeInvoicesReport() {
        List<Factura> facturas = facturaRep.findAll();
        
        double totalIngresos = 0.0;
        int facturasPendientes = 0;
        int facturasPagadas = 0;
        
        for (Factura f : facturas) {
            totalIngresos += f.getTotal();
            if (f.isPagada()) facturasPagadas++;
            else facturasPendientes++;
        }

        String prompt = "Eres un analista financiero de un restaurante. Sé profesional pero conciso. "
                + "Aquí tienes un resumen de la facturación actual:\n"
                + "- Total de facturas registradas: " + facturas.size() + "\n"
                + "- Ingresos totales generados (sumando todas): $" + totalIngresos + "\n"
                + "- Facturas Pagadas: " + facturasPagadas + "\n"
                + "- Facturas Pendientes: " + facturasPendientes + "\n\n"
                + "Basado en estos datos, dame un pequeño reporte sobre la situación actual de los cobros y alguna recomendación si hay muchas pendientes.";
                
        return groqApiClient.askGroq(prompt);
    }
}
