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

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
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

        // ─────────────────────────────────────────────
        // PUNTO DE ENTRADA PRINCIPAL
        // ─────────────────────────────────────────────

        public String askQuestion(String userQuestion) {

                String q = userQuestion.toLowerCase().trim();

                // ── MESAS ──────────────────────────────────
                if (esComandoEliminarMesa(q))
                        return eliminarMesaPorNumero(q);
                if (esComandoLiberarMesa(q))
                        return liberarMesa(q);
                if (esComandoOcuparMesa(q))
                        return ocuparMesa(q);
                if (esComandoAsignarMesero(q))
                        return asignarMesero(userQuestion);
                if (esComandoRemoverMesero(q))
                        return removerMesero(q);
                if (esComandoLimpiarPedidos(q))
                        return limpiarPedidos(q);

                // ── PLATILLOS ──────────────────────────────
                // IMPORTANTE: el orden importa — editar antes que agregar
                if (esComandoEliminarPlatillo(q))
                        return eliminarPlatillo(userQuestion);
                if (esComandoEditarPlatillo(q))
                        return editarPlatillo(userQuestion);
                if (esComandoAgregarPlatillo(q))
                        return agregarPlatillo(userQuestion);

                // ── CONSULTAS INFORMATIVAS (Groq + RAG) ────
                String context = generateSmartContext(q);

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

        // ═════════════════════════════════════════════
        // DETECCIÓN DE INTENCIONES — MESAS
        // ═════════════════════════════════════════════

        private boolean esComandoEliminarMesa(String q) {
                return (q.contains("elimina") || q.contains("eliminar")
                                || q.contains("borra") || q.contains("borrar"))
                                && q.contains("mesa")
                                && !q.contains("platillo")
                                && extraerNumeroMesa(q) != -1;
        }

        private boolean esComandoLiberarMesa(String q) {
                return q.contains("mesa")
                                && (q.contains("libera") || q.contains("liberar")
                                                || q.contains("libre") || q.contains("desocupa")
                                                || q.contains("desocupar"))
                                && extraerNumeroMesa(q) != -1;
        }

        private boolean esComandoOcuparMesa(String q) {
                return q.contains("mesa")
                                && (q.contains("ocupa") || q.contains("ocupar")
                                                || q.contains("marca como ocupada"))
                                && extraerNumeroMesa(q) != -1;
        }

        private boolean esComandoAsignarMesero(String q) {
                return q.contains("mesa")
                                && (q.contains("asigna") || q.contains("asignar")
                                                || q.contains("pon mesero") || q.contains("agrega mesero"))
                                && extraerNumeroMesa(q) != -1;
        }

        private boolean esComandoRemoverMesero(String q) {
                return q.contains("mesa")
                                && (q.contains("remueve mesero") || q.contains("remover mesero")
                                                || q.contains("quita mesero") || q.contains("quitar mesero"))
                                && extraerNumeroMesa(q) != -1;
        }

        private boolean esComandoLimpiarPedidos(String q) {
                return q.contains("mesa")
                                && (q.contains("limpia pedidos") || q.contains("limpiar pedidos")
                                                || q.contains("borra pedidos") || q.contains("vaciar pedidos"))
                                && extraerNumeroMesa(q) != -1;
        }

        // ═════════════════════════════════════════════
        // DETECCIÓN DE INTENCIONES — PLATILLOS
        // Detecta el VERBO + la palabra "platillo" en cualquier orden
        // ═════════════════════════════════════════════

        private boolean esComandoAgregarPlatillo(String q) {
                boolean tieneVerbo = q.contains("agrega") || q.contains("agregar")
                                || q.contains("nuevo") || q.contains("crea") || q.contains("crear")
                                || q.contains("añade") || q.contains("añadir")
                                || q.contains("registra") || q.contains("registrar");
                boolean tienePlatillo = q.contains("platillo");
                // Formato clave=valor clásico
                boolean tieneFormatoClasico = q.contains("nombre=") && q.contains("precio=");
                // Formato natural: "crea platillo jamon con queso, precio 1.000, cantidad 1"
                boolean tieneFormatoNatural = tienePlatillo && q.contains("precio");
                return (tieneVerbo && tienePlatillo)
                                || (tieneVerbo && tieneFormatoClasico)
                                || (tieneVerbo && tieneFormatoNatural);
        }

        private boolean esComandoEditarPlatillo(String q) {
                boolean tieneVerbo = q.contains("edita") || q.contains("editar")
                                || q.contains("modifica") || q.contains("modificar")
                                || q.contains("actualiza") || q.contains("actualizar")
                                || q.contains("cambia") || q.contains("cambiar");
                boolean tienePlatillo = q.contains("platillo") || q.contains("nombre=");
                return tieneVerbo && tienePlatillo;
        }

        private boolean esComandoEliminarPlatillo(String q) {
                boolean tieneVerbo = q.contains("elimina") || q.contains("eliminar")
                                || q.contains("borra") || q.contains("borrar")
                                || q.contains("quita") || q.contains("quitar")
                                || q.contains("borra") || q.contains("borrar");
                boolean tienePlatillo = q.contains("platillo");
                // Que NO sea una mesa para evitar conflictos
                boolean noEsMesa = !q.contains("mesa");
                return tieneVerbo && tienePlatillo && noEsMesa;
        }

        // ═════════════════════════════════════════════
        // ACCIONES — MESAS
        // ═════════════════════════════════════════════

        private String eliminarMesaPorNumero(String q) {
                int num = extraerNumeroMesa(q);
                if (num == -1)
                        return "No pude identificar el número de mesa. Ejemplo: 'elimina la mesa 3'.";
                Optional<Mesa> opt = buscarMesaPorNum(num);
                if (opt.isEmpty())
                        return "No encontré ninguna mesa con el número " + num + ".";
                mesaRep.deleteById(opt.get().getId());
                return "✅ Mesa número " + num + " eliminada correctamente.";
        }

        private String liberarMesa(String q) {
                int num = extraerNumeroMesa(q);
                Optional<Mesa> opt = buscarMesaPorNum(num);
                if (opt.isEmpty())
                        return "No encontré ninguna mesa con el número " + num + ".";
                Mesa m = opt.get();
                m.setOcupado(false);
                m.setMeseroId(null);
                m.setPedidosId(new ArrayList<>());
                mesaRep.save(m);
                return "✅ Mesa " + num + " liberada (libre, sin mesero, sin pedidos).";
        }

        private String ocuparMesa(String q) {
                int num = extraerNumeroMesa(q);
                Optional<Mesa> opt = buscarMesaPorNum(num);
                if (opt.isEmpty())
                        return "No encontré ninguna mesa con el número " + num + ".";
                Mesa m = opt.get();
                m.setOcupado(true);
                mesaRep.save(m);
                return "✅ Mesa " + num + " marcada como ocupada.";
        }

        private String asignarMesero(String original) {
                String q = original.toLowerCase();
                int num = extraerNumeroMesa(q);
                Optional<Mesa> opt = buscarMesaPorNum(num);
                if (opt.isEmpty())
                        return "No encontré ninguna mesa con el número " + num + ".";
                String meseroId = extraerMeseroId(original);
                if (meseroId == null || meseroId.isBlank())
                        return "No pude identificar el ID del mesero. Ejemplo: 'asigna mesero abc123 a la mesa 2'.";
                Mesa m = opt.get();
                m.setMeseroId(meseroId);
                m.setOcupado(true);
                mesaRep.save(m);
                return "✅ Mesero '" + meseroId + "' asignado a la mesa " + num + ".";
        }

        private String removerMesero(String q) {
                int num = extraerNumeroMesa(q);
                Optional<Mesa> opt = buscarMesaPorNum(num);
                if (opt.isEmpty())
                        return "No encontré ninguna mesa con el número " + num + ".";
                Mesa m = opt.get();
                m.setMeseroId(null);
                mesaRep.save(m);
                return "✅ Mesero removido de la mesa " + num + ".";
        }

        private String limpiarPedidos(String q) {
                int num = extraerNumeroMesa(q);
                Optional<Mesa> opt = buscarMesaPorNum(num);
                if (opt.isEmpty())
                        return "No encontré ninguna mesa con el número " + num + ".";
                Mesa m = opt.get();
                m.setPedidosId(new ArrayList<>());
                mesaRep.save(m);
                return "✅ Pedidos de la mesa " + num + " limpiados.";
        }

        // ═════════════════════════════════════════════
        // ACCIONES — PLATILLOS
        // Usa platilloRep.save() igual que PlatilloController
        // ═════════════════════════════════════════════

        /**
         * Agrega un nuevo platillo. Soporta DOS formatos:
         *
         * FORMATO NATURAL (nuevo):
         * "crea platillo jamon con queso, precio 1.000, cantidad 1"
         * "agrega platillo pizza margarita, precio 12.5, cantidad 8"
         *
         * FORMATO CLÁSICO (clave=valor):
         * "agrega platillo nombre=Pizza precio=12.5 cantidad=8"
         *
         * Intenta el formato natural primero; si falla, cae al clásico.
         */
        private String agregarPlatillo(String original) {

                String nombre;
                double precio;
                String cantidad;

                // ── Intentar formato natural primero ──────────────────────────────
                // Patrón: "platillo NOMBRE, precio PRECIO, cantidad CANTIDAD"
                // El nombre va desde después de "platillo" hasta la primera coma
                // El precio va después de "precio" hasta la siguiente coma o fin
                // La cantidad va después de "cantidad" hasta fin o coma
                nombre = extraerNombreNatural(original);
                precio = extraerPrecioNatural(original);
                cantidad = extraerCantidadNatural(original);

                // ── Si el formato natural no dio nombre, intentar formato clásico ──
                if (nombre == null || nombre.isBlank()) {
                        nombre = extraerCampoTexto(original, "nombre");
                        precio = extraerCampoDouble(original, "precio");
                        cantidad = extraerCampoTexto(original, "cantidad");
                }

                // ── Validaciones ──────────────────────────────────────────────────
                if (nombre == null || nombre.isBlank())
                        return "⚠️ No pude identificar el nombre.\n"
                                        + "Formato natural:  crea platillo jamon con queso, precio 1.000, cantidad 1\n"
                                        + "Formato clásico:  agrega platillo nombre=Pizza precio=12.5 cantidad=8";

                if (precio < 0)
                        return "⚠️ No pude identificar el precio del platillo '" + nombre + "'.\n"
                                        + "Ejemplo: crea platillo " + nombre + ", precio 5.000, cantidad 1";

                // ── Guardar igual que PlatilloController ──────────────────────────
                Platillo nuevo = new Platillo();
                nuevo.setName(nombre.trim());
                nuevo.setPrice(precio);
                nuevo.setCant(cantidad != null && !cantidad.isBlank() ? cantidad.trim() : "0");

                platilloRep.save(nuevo);

                return "✅ Platillo '" + nuevo.getName() + "' guardado en la BD\n"
                                + "   Precio: $" + nuevo.getPrice() + " | Cantidad: " + nuevo.getCant();
        }

        /**
         * Extrae el nombre en formato natural.
         * Ejemplo: "crea platillo jamon con queso, precio 1.000, cantidad 1"
         * → "jamon con queso"
         * Busca el texto entre la palabra "platillo" y la primera coma.
         */
        private String extraerNombreNatural(String original) {
                // Busca: (agrega|crea|...) platillo NOMBRE , ...
                Pattern p = Pattern.compile(
                                "(?:agrega|agregar|crea|crear|nuevo|añade|añadir|registra|registrar)"
                                                + "\\s+platillo\\s+([^,]+)",
                                Pattern.CASE_INSENSITIVE);
                Matcher m = p.matcher(original);
                if (m.find()) {
                        return m.group(1).trim();
                }
                return null;
        }

        /**
         * Extrae el precio en formato natural.
         * Soporta: "precio 1.000", "precio 12.5", "precio 1,000" (coma como separador
         * de miles)
         * Ejemplo: "precio 1.000" → 1000.0 | "precio 12.5" → 12.5
         */
        private double extraerPrecioNatural(String original) {
                Pattern p = Pattern.compile(
                                "precio\\s+([\\d.,]+)",
                                Pattern.CASE_INSENSITIVE);
                Matcher m = p.matcher(original);
                if (m.find()) {
                        String raw = m.group(1)
                                        .replace(",", "") // quitar comas de miles: 1,000 → 1000
                                        .replace(".", ""); // quitar puntos de miles: 1.000 → 1000

                        // Si el original tenía decimales reales (ej: 12.5), conservarlos
                        // Heurística: si el número original tiene punto Y más de 2 dígitos después →
                        // miles
                        // si tiene punto Y exactamente 1-2 dígitos después → decimal real
                        String rawOriginal = m.group(1).replace(",", "");
                        if (rawOriginal.contains(".")) {
                                String[] partes = rawOriginal.split("\\.");
                                String decimales = partes[partes.length - 1];
                                if (decimales.length() <= 2) {
                                        // Es decimal real: 12.5 o 12.50
                                        try {
                                                return Double.parseDouble(rawOriginal);
                                        } catch (NumberFormatException ignored) {
                                        }
                                }
                        }
                        // Es separador de miles: 1.000 → 1000
                        try {
                                return Double.parseDouble(raw);
                        } catch (NumberFormatException ignored) {
                        }
                }
                return -1;
        }

        /**
         * Extrae la cantidad en formato natural.
         * Ejemplo: "cantidad 1" → "1"
         */
        private String extraerCantidadNatural(String original) {
                Pattern p = Pattern.compile(
                                "cantidad\\s+([\\d]+)",
                                Pattern.CASE_INSENSITIVE);
                Matcher m = p.matcher(original);
                return m.find() ? m.group(1).trim() : null;
        }

        /**
         * Edita un platillo existente replicando PlatilloController.updatePlatillo().
         * Busca por nombre (más natural para el chatbot) en vez de por ID.
         *
         * Formatos:
         * "edita platillo nombre=Pizza precio=15.0"
         * "cambia cantidad del platillo nombre=Sisa cantidad=5"
         * "modifica platillo nombre=Sisa nuevonombre=Sisa Especial"
         */
        private String editarPlatillo(String original) {
                String nombre = extraerCampoTexto(original, "nombre");

                if (nombre == null || nombre.isBlank())
                        return "⚠️ Necesito el nombre del platillo. Ejemplo: editar platillo nombre=Pizza precio=15.0";

                // Buscar en BD igual que findById en el controlador
                Optional<Platillo> opt = platilloRep.findAll().stream()
                                .filter(p -> p.getName().equalsIgnoreCase(nombre.trim()))
                                .findFirst();

                if (opt.isEmpty())
                        return "No encontré ningún platillo llamado '" + nombre + "'.";

                // Replicar lógica de updatePlatillo() del controlador
                Platillo platillo = opt.get();
                StringBuilder cambios = new StringBuilder();

                double nuevoPrecio = extraerCampoDouble(original, "precio");
                if (nuevoPrecio >= 0) {
                        platillo.setPrice(nuevoPrecio);
                        cambios.append(" precio=$").append(nuevoPrecio).append(";");
                }

                String nuevaCant = extraerCampoTexto(original, "cantidad");
                if (nuevaCant != null && !nuevaCant.isBlank()) {
                        platillo.setCant(nuevaCant.trim());
                        cambios.append(" cantidad=").append(nuevaCant.trim()).append(";");
                }

                String nuevoNombre = extraerCampoTexto(original, "nuevonombre");
                if (nuevoNombre != null && !nuevoNombre.isBlank()) {
                        platillo.setName(nuevoNombre.trim());
                        cambios.append(" nombre='").append(nuevoNombre.trim()).append("';");
                }

                if (cambios.isEmpty())
                        return "No detecté qué editar. Campos disponibles: precio, cantidad, nuevonombre.\n"
                                        + "Ejemplo: edita platillo nombre=Pizza precio=15.0";

                platilloRep.save(platillo); // ← mismo método que usa PlatilloController

                return "✅ Platillo '" + nombre + "' actualizado en la BD →" + cambios;
        }

        /**
         * Elimina un platillo replicando PlatilloController.deletePlatillo().
         * Busca por nombre en vez de por ID.
         *
         * Formato: "elimina platillo nombre=Sisa"
         */
        private String eliminarPlatillo(String original) {
                String nombre = extraerCampoTexto(original, "nombre");

                if (nombre == null || nombre.isBlank())
                        return "⚠️ Necesito el nombre. Ejemplo: elimina platillo nombre=Sisa";

                Optional<Platillo> opt = platilloRep.findAll().stream()
                                .filter(p -> p.getName().equalsIgnoreCase(nombre.trim()))
                                .findFirst();

                if (opt.isEmpty())
                        return "No encontré ningún platillo llamado '" + nombre + "'.";

                platilloRep.deleteById(opt.get().getId()); // ← mismo método que usa PlatilloController

                return "✅ Platillo '" + nombre + "' eliminado de la BD.";
        }

        // ═════════════════════════════════════════════
        // UTILIDADES DE EXTRACCIÓN
        // ═════════════════════════════════════════════

        private int extraerNumeroMesa(String q) {
                Pattern p = Pattern.compile("mesa\\s*(?:número|numero|#)?\\s*(\\d+)");
                Matcher m = p.matcher(q);
                return m.find() ? Integer.parseInt(m.group(1)) : -1;
        }

        private String extraerMeseroId(String original) {
                Pattern p = Pattern.compile(
                                "(?:asigna|pon|agrega)?\\s*mesero\\s+([^\\s]+)",
                                Pattern.CASE_INSENSITIVE);
                Matcher m = p.matcher(original);
                if (m.find()) {
                        String t = m.group(1);
                        if (!t.equalsIgnoreCase("a") && !t.equalsIgnoreCase("de")
                                        && !t.equalsIgnoreCase("la") && !t.equalsIgnoreCase("el"))
                                return t;
                }
                return null;
        }

        /**
         * Extrae valor de texto en formato clave=valor.
         * Soporta valores con espacios hasta la siguiente clave o fin de cadena.
         * Ejemplo: "nombre=Pizza Italiana precio=12" → "Pizza Italiana"
         */
        private String extraerCampoTexto(String texto, String clave) {
                // Busca: clave=VALOR hasta que aparezca otra_clave= o fin de string
                Pattern p = Pattern.compile(
                                "(?i)" + Pattern.quote(clave) + "=([^=]+?)(?=\\s+\\w+=|$)");
                Matcher m = p.matcher(texto.trim());
                return m.find() ? m.group(1).trim() : null;
        }

        /**
         * Extrae valor numérico en formato clave=valor.
         * Retorna -1 si no se encuentra.
         */
        private double extraerCampoDouble(String texto, String clave) {
                Pattern p = Pattern.compile(
                                "(?i)" + Pattern.quote(clave) + "=([\\d.]+)");
                Matcher m = p.matcher(texto);
                if (m.find()) {
                        try {
                                return Double.parseDouble(m.group(1));
                        } catch (NumberFormatException ignored) {
                        }
                }
                return -1;
        }

        private Optional<Mesa> buscarMesaPorNum(int num) {
                return mesaRep.findAll().stream()
                                .filter(m -> m.getNum() == num)
                                .findFirst();
        }

        // ═════════════════════════════════════════════
        // RAG DINÁMICO (consultas informativas)
        // ═════════════════════════════════════════════

        private String generateSmartContext(String question) {

                if (question.contains("mas vendido") || question.contains("más vendido")
                                || question.contains("menos vendido") || question.contains("popular")
                                || question.contains("vende mas") || question.contains("vende más")) {

                        List<Pedido> pedidos = pedidoRep.findAll();
                        Map<String, Integer> ventas = new HashMap<>();
                        for (Pedido p : pedidos) {
                                if (p.getItems() != null) {
                                        for (ItemPedido item : p.getItems()) {
                                                ventas.put(item.getName(),
                                                                ventas.getOrDefault(item.getName(), 0)
                                                                                + item.getUnidades());
                                        }
                                }
                        }
                        if (ventas.isEmpty())
                                return "No hay ventas registradas.";

                        String mas = ventas.entrySet().stream().max(Map.Entry.comparingByValue())
                                        .map(e -> e.getKey() + " con " + e.getValue() + " ventas").orElse("N/A");
                        String menos = ventas.entrySet().stream().min(Map.Entry.comparingByValue())
                                        .map(e -> e.getKey() + " con " + e.getValue() + " ventas").orElse("N/A");

                        return """
                                        ESTADÍSTICAS DE VENTAS
                                        Más vendido:  %s
                                        Menos vendido: %s
                                        Detalle:
                                        %s
                                        """.formatted(mas, menos,
                                        ventas.entrySet().stream()
                                                        .sorted(Map.Entry.comparingByValue(Comparator.reverseOrder()))
                                                        .map(e -> "- " + e.getKey() + ": " + e.getValue() + " vendidos")
                                                        .collect(Collectors.joining("\n")));
                }

                if (question.contains("mesa") || question.contains("libre") || question.contains("ocupada")) {
                        List<Mesa> mesas = mesaRep.findAll();
                        long ocupadas = mesas.stream().filter(Mesa::isOcupado).count();
                        String detalle = mesas.stream()
                                        .map(m -> "- Mesa " + m.getNum()
                                                        + " | " + (m.isOcupado() ? "Ocupada" : "Libre")
                                                        + (m.getMeseroId() != null ? " | Mesero: " + m.getMeseroId()
                                                                        : "")
                                                        + " | Pedidos: "
                                                        + (m.getPedidosId() != null ? m.getPedidosId().size() : 0))
                                        .collect(Collectors.joining("\n"));
                        return """
                                        ESTADO DE MESAS
                                        Total: %d | Ocupadas: %d | Libres: %d
                                        Detalle:
                                        %s
                                        """.formatted(mesas.size(), ocupadas, mesas.size() - ocupadas, detalle);
                }

                if (question.contains("menu") || question.contains("menú")
                                || question.contains("platillo") || question.contains("comida")
                                || question.contains("pizza") || question.contains("hamburguesa")) {
                        List<Platillo> platillos = platilloRep.findAll();
                        if (platillos.isEmpty())
                                return "No hay platillos registrados.";
                        return """
                                        MENÚ DEL RESTAURANTE
                                        %s
                                        """.formatted(platillos.stream()
                                        .map(p -> "- " + p.getName() + " | $" + p.getPrice() + " | Cant: "
                                                        + p.getCant())
                                        .collect(Collectors.joining("\n")));
                }

                if (question.contains("inventario") || question.contains("stock") || question.contains("producto")) {
                        List<Producto> productos = productoRep.findAll();
                        if (productos.isEmpty())
                                return "No hay productos registrados.";
                        return """
                                        INVENTARIO
                                        %s
                                        """.formatted(productos.stream()
                                        .map(p -> "- " + p.getName() + " | Stock: " + p.getStock() + " | $"
                                                        + p.getPrice())
                                        .collect(Collectors.joining("\n")));
                }

                if (question.contains("venta") || question.contains("ingreso")
                                || question.contains("factura") || question.contains("ganancia")
                                || question.contains("dinero")) {
                        List<Factura> facturas = facturaRep.findAll();
                        double ingresos = 0;
                        int pagadas = 0, pendientes = 0;
                        for (Factura f : facturas) {
                                if (Boolean.TRUE.equals(f.isPagada())) {
                                        ingresos += f.getTotal();
                                        pagadas++;
                                } else
                                        pendientes++;
                        }
                        return """
                                        FINANZAS
                                        Facturas pagadas: %d | Pendientes: %d
                                        Ingresos totales: $%.2f
                                        """.formatted(pagadas, pendientes, ingresos);
                }

                return generateGeneralContext();
        }

        private String generateGeneralContext() {
                List<Mesa> mesas = mesaRep.findAll();
                List<Platillo> platillos = platilloRep.findAll();
                List<Producto> productos = productoRep.findAll();
                long ocupadas = mesas.stream().filter(Mesa::isOcupado).count();
                return """
                                INFORMACIÓN GENERAL
                                Mesas: %d total | %d ocupadas | %d libres
                                Platillos en menú: %d
                                Productos en inventario: %d
                                """.formatted(mesas.size(), ocupadas, mesas.size() - ocupadas,
                                platillos.size(), productos.size());
        }
}