package com.example.rskitchen5.Service;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Model.ItemPedido;
import com.example.rskitchen5.Model.Mesa;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Model.Platillo;
import com.example.rskitchen5.Model.Producto;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Repository.MesaRep;
import com.example.rskitchen5.Repository.PedidoRep;
import com.example.rskitchen5.Repository.PlatilloRep;
import com.example.rskitchen5.Repository.ProductoRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Comparator;
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

        // RAG DINÁMICO
        String context = generateSmartContext(userQuestion);

        String prompt = """
                Eres un asistente inteligente y amigable de un restaurante.

                Debes responder SOLO usando la información del contexto.

                Si la información no existe en el contexto,
                responde amablemente que no tienes datos suficientes.

                CONTEXTO:
                %s

                PREGUNTA DEL USUARIO:
                %s
                """.formatted(context, userQuestion);

        return groqApiClient.askGroq(prompt);
    }

    // ======================================================
    // RAG INTELIGENTE
    // ======================================================
    private String generateSmartContext(String question) {

        question = question.toLowerCase();

        // ======================================================
        // PLATILLOS MÁS / MENOS VENDIDOS
        // IMPORTANTE:
        // ESTE BLOQUE VA PRIMERO
        // ======================================================
        if (question.contains("mas vendido")
                || question.contains("más vendido")
                || question.contains("menos vendido")
                || question.contains("popular")
                || question.contains("vende mas")
                || question.contains("vende más")) {

            List<Pedido> pedidos = pedidoRep.findAll();

            Map<String, Integer> ventasPorPlatillo = new HashMap<>();

            for (Pedido p : pedidos) {

                if (p.getItems() != null) {

                    for (ItemPedido item : p.getItems()) {

                        String nombre = item.getName();
                        int cantidad = item.getUnidades();

                        ventasPorPlatillo.put(
                                nombre,
                                ventasPorPlatillo.getOrDefault(nombre, 0)
                                        + cantidad
                        );
                    }
                }
            }

            if (ventasPorPlatillo.isEmpty()) {
                return "No hay ventas registradas.";
            }

            String masVendido = ventasPorPlatillo.entrySet()
                    .stream()
                    .max(Map.Entry.comparingByValue())
                    .map(e -> e.getKey() + " con "
                            + e.getValue() + " ventas")
                    .orElse("No disponible");

            String menosVendido = ventasPorPlatillo.entrySet()
                    .stream()
                    .min(Map.Entry.comparingByValue())
                    .map(e -> e.getKey() + " con "
                            + e.getValue() + " ventas")
                    .orElse("No disponible");

            return """
                    ESTADÍSTICAS DE VENTAS

                    Platillo más vendido:
                    %s

                    Platillo menos vendido:
                    %s

                    Ventas completas:

                    %s
                    """.formatted(
                    masVendido,
                    menosVendido,
                    ventasPorPlatillo.entrySet()
                            .stream()
                            .sorted(Map.Entry.comparingByValue(
                                    Comparator.reverseOrder()))
                            .map(e -> "- "
                                    + e.getKey()
                                    + ": "
                                    + e.getValue()
                                    + " vendidos")
                            .collect(Collectors.joining("\n"))
            );
        }

        if (question.contains("mesa")
                || question.contains("libre")
                || question.contains("ocupada")) {

            List<Mesa> mesas = mesaRep.findAll();

            long ocupadas = mesas.stream()
                    .filter(Mesa::isOcupado)
                    .count();

            long libres = mesas.size() - ocupadas;

            return """
                    ESTADO DE MESAS

                    Total de mesas: %d
                    Mesas ocupadas: %d
                    Mesas libres: %d
                    """.formatted(mesas.size(), ocupadas, libres);
        }

        if (question.contains("menu")
                || question.contains("menú")
                || question.contains("platillo")
                || question.contains("comida")
                || question.contains("pizza")
                || question.contains("hamburguesa")) {

            List<Platillo> platillos = platilloRep.findAll();

            if (platillos.isEmpty()) {
                return "No hay platillos registrados.";
            }

            return """
                    MENÚ DEL RESTAURANTE

                    %s
                    """.formatted(
                    platillos.stream()
                            .map(p -> "- "
                                    + p.getName()
                                    + " ($"
                                    + p.getPrice()
                                    + ")")
                            .collect(Collectors.joining("\n"))
            );
        }

        if (question.contains("inventario")
                || question.contains("stock")
                || question.contains("producto")) {

            List<Producto> productos = productoRep.findAll();

            if (productos.isEmpty()) {
                return "No hay productos registrados.";
            }

            return """
                    INVENTARIO

                    %s
                    """.formatted(
                    productos.stream()
                            .map(p -> "- "
                                    + p.getName()
                                    + " | Stock: "
                                    + p.getStock()
                                    + " | Precio: $"
                                    + p.getPrice())
                            .collect(Collectors.joining("\n"))
            );
        }

        if (question.contains("venta")
                || question.contains("ingreso")
                || question.contains("factura")
                || question.contains("ganancia")
                || question.contains("dinero")) {

            List<Factura> facturas = facturaRep.findAll();

            double ingresos = 0;
            int pagadas = 0;
            int pendientes = 0;

            for (Factura f : facturas) {

                if (f.isPagada()) {
                    ingresos += f.getTotal();
                    pagadas++;
                } else {
                    pendientes++;
                }
            }

            return """
                    FINANZAS

                    Facturas pagadas: %d
                    Facturas pendientes: %d
                    Ingresos totales: $%.2f
                    """.formatted(pagadas, pendientes, ingresos);
        }

        return generateGeneralContext();
    }

    private String generateGeneralContext() {

        List<Mesa> mesas = mesaRep.findAll();
        List<Platillo> platillos = platilloRep.findAll();
        List<Producto> productos = productoRep.findAll();

        long ocupadas = mesas.stream()
                .filter(Mesa::isOcupado)
                .count();

        long libres = mesas.size() - ocupadas;

        return """
                INFORMACIÓN GENERAL DEL RESTAURANTE

                Mesas totales: %d
                Mesas ocupadas: %d
                Mesas libres: %d

                Total platillos: %d
                Total productos inventario: %d
                """.formatted(
                mesas.size(),
                ocupadas,
                libres,
                platillos.size(),
                productos.size()
        );
    }
}