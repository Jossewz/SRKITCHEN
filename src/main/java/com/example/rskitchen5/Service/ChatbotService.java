package com.example.rskitchen5.Service;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Model.ItemPedido;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Model.Mesa;
import com.example.rskitchen5.Model.Platillo;
import com.example.rskitchen5.Model.Producto;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Repository.PedidoRep;
import com.example.rskitchen5.Repository.MesaRep;
import com.example.rskitchen5.Repository.PlatilloRep;
import com.example.rskitchen5.Repository.ProductoRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ChatbotService {

    @Autowired
    private GroqApiClient groqApiClient;

    @Autowired
    private FacturaRep facturaRep;

    @Autowired
    private PedidoRep pedidoRep;

    @Autowired
    private MesaRep mesaRep;

    @Autowired
    private PlatilloRep platilloRep;

    @Autowired
    private ProductoRep productoRep;

    public String askQuestion(String userQuestion) {
        String context = generateRestaurantContext();

        String prompt = "Eres un asistente de inteligencia artificial experto y amigable para un restaurante. "
                + "Tu objetivo es responder de manera clara, profesional y concisa a la pregunta del usuario basándote en los "
                + "siguientes datos reales de nuestro sistema en este momento:\n\n"
                + context + "\n\n"
                + "Si el usuario pregunta algo que no está en los datos provistos, indícale amablemente que careces de esa información en tus datos actuales.\n"
                + "Pregunta del usuario: " + userQuestion;

        return groqApiClient.askGroq(prompt);
    }

    private String generateRestaurantContext() {
        List<Pedido> pedidos = pedidoRep.findAll();
        List<Factura> facturas = facturaRep.findAll();
        List<Mesa> mesas = mesaRep.findAll();
        List<Platillo> platillos = platilloRep.findAll();
        List<Producto> productos = productoRep.findAll();

        // 1. Resumen de Platillos (Todos, para responder qué se vende menos y qué se vende más)
        Map<String, Integer> ventasPorPlatillo = new HashMap<>();
        // 2. Resumen de Pedidos por Mesero
        Map<String, Integer> pedidosPorMesero = new HashMap<>();

        for (Pedido p : pedidos) {
            String mesero = p.getMeseroName() != null && !p.getMeseroName().isEmpty() ? p.getMeseroName() : "Mesero Desconocido";
            pedidosPorMesero.put(mesero, pedidosPorMesero.getOrDefault(mesero, 0) + 1);

            if (p.getItems() != null) {
                for (ItemPedido item : p.getItems()) {
                    String nombre = item.getName() != null ? item.getName() : "Desconocido";
                    int cantidad = item.getUnidades();
                    ventasPorPlatillo.put(nombre, ventasPorPlatillo.getOrDefault(nombre, 0) + cantidad);
                }
            }
        }

        String dataPlatillos = ventasPorPlatillo.isEmpty() ? "No hay ventas registradas" :
            ventasPorPlatillo.entrySet().stream()
                .map(e -> "- " + e.getKey() + ": " + e.getValue() + " und(s)")
                .collect(Collectors.joining("\n"));

        String dataMeseros = pedidosPorMesero.isEmpty() ? "No hay pedidos registrados por meseros" :
            pedidosPorMesero.entrySet().stream()
                .map(e -> "- " + e.getKey() + ": " + e.getValue() + " pedido(s)")
                .collect(Collectors.joining("\n"));

        double totalIngresos = 0.0;
        double ingresosPorCobrar = 0.0;
        int facturasPagadas = 0;
        int facturasPendientes = 0;

        for (Factura f : facturas) {
            if (f.isPagada()) {
                totalIngresos += f.getTotal();
                facturasPagadas++;
            } else {
                ingresosPorCobrar += f.getTotal();
                facturasPendientes++;
            }
        }
        
        long mesasOcupadas = mesas.stream().filter(Mesa::isOcupado).count();
        long mesasLibres = mesas.size() - mesasOcupadas;
        
        String dataMenu = platillos.isEmpty() ? "No hay platillos en el menú registrados." :
            platillos.stream().map(p -> "- " + p.getName() + " (Precio: $" + p.getPrice() + ")")
                .collect(Collectors.joining("\n"));
                
        String dataInventario = productos.isEmpty() ? "No hay inventario registrado." :
            productos.stream().map(p -> "- " + p.getName() + " (Stock: " + p.getStock() + " unids, Costo: $" + p.getPrice() + ")")
                .collect(Collectors.joining("\n"));

        return "---- CONTEXTO ACTUAL DEL RESTAURANTE ----\n"
                + "Total de Pedidos Realizados (Histórico y actuales): " + pedidos.size() + "\n\n"
                + "[Estado de Mesas]\n"
                + "Total de Mesas: " + mesas.size() + "\n"
                + "- Ocupadas: " + mesasOcupadas + "\n"
                + "- Disponibles (Libres): " + mesasLibres + "\n\n"
                + "[Ventas por Platillo (Datos de todos los platillos)]\n" + dataPlatillos + "\n\n"
                + "[Rendimiento de Meseros (Pedidos Atendidos)]\n" + dataMeseros + "\n\n"
                + "[Finanzas y Facturación]\n"
                + "- Ingresos Totales (Facturas Pagadas): $" + totalIngresos + " (" + facturasPagadas + " facturas)\n"
                + "- Ingresos Pendientes por Cobrar: $" + ingresosPorCobrar + " (" + facturasPendientes + " facturas pendientes)\n\n"
                + "[Menú del Restaurante (Platillos y Precios)]\n" + dataMenu + "\n\n"
                + "[Inventario de Productos y Stock]\n" + dataInventario + "\n"
                + "-----------------------------------------";
    }
}
