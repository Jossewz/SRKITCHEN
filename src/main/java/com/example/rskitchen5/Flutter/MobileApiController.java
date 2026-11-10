package com.example.rskitchen5.Flutter;

import com.example.rskitchen5.DTO.*;
import com.example.rskitchen5.Model.*;
import com.example.rskitchen5.Repository.*;
import com.example.rskitchen5.Security.JwtService;
import com.example.rskitchen5.Security.TenantContext;
import com.example.rskitchen5.Security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Controlador REST diseñado para la aplicación móvil (Flutter / Android / iOS).
 * Proporciona endpoints para autenticación de restaurantes, métricas de ventas,
 * ranking de platillos e inventario clasificado por niveles de stock.
 */
@RestController
@RequestMapping("/api/mobile")
public class MobileApiController {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
    private static final int UMBRAL_STOCK_CRITICO = 5;
    private static final int UMBRAL_STOCK_BAJO = 15;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private RestaurantRep restaurantRep;

    @Autowired
    private ProductoRep productoRep;

    @Autowired
    private FacturaRep facturaRep;

    @Autowired
    private PedidoRep pedidoRep;

    // =========================================================================
    // 1. INICIO DE SESIÓN DE RESTAURANTES (Móvil)
    // =========================================================================

    /**
     * Endpoint para iniciar sesión de restaurante o administrador desde la app móvil.
     * Soporta los campos correo/mail y clave/contraseña/password.
     */
    @PostMapping({"/login", "/auth/login"})
    public ResponseEntity<?> loginRestaurante(@RequestBody MobileLoginRequest request) {
        String email = request.resolveEmail();
        String password = request.resolvePassword();

        if (email.isBlank() || password.isBlank()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "El correo y la contraseña son requeridos"));
        }

        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, password)
            );

            UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();

            String token = jwtService.generateToken(
                    principal.getUsername(),
                    principal.getRole(),
                    principal.getRestaurantId(),
                    principal.getNombre()
            );

            Map<String, Object> response = new LinkedHashMap<>();
            response.put("token", token);
            response.put("type", "Bearer");
            response.put("restaurantId", principal.getRestaurantId());
            response.put("nombre", principal.getNombre());
            response.put("email", principal.getUsername());
            response.put("role", principal.getRole());
            response.put("mensaje", "Inicio de sesión exitoso");

            return ResponseEntity.ok(response);
        } catch (DisabledException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", e.getMessage() != null ? e.getMessage() : "El restaurante o usuario se encuentra desactivado."));
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Credenciales inválidas. Verifique correo y contraseña."));
        } catch (AuthenticationException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", e.getMessage() != null ? e.getMessage() : "Error en autenticación"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error interno en el servidor: " + e.getMessage()));
        }
    }

    // =========================================================================
    // 2. ACCEDER AL INVENTARIO
    // =========================================================================

    /**
     * Lista todos los productos en el inventario del restaurante autenticado.
     * Permite filtrar por término de búsqueda y por estado activo.
     */
    @GetMapping({"/inventario", "/productos"})
    public ResponseEntity<?> getInventario(
            @RequestParam(required = false) String buscar,
            @RequestParam(required = false, defaultValue = "false") Boolean soloActivos) {
        Long restaurantId = obtenerRestaurantId();

        List<Producto> productos = Boolean.TRUE.equals(soloActivos)
                ? productoRep.findByRestaurantIdAndActivo(restaurantId, true)
                : productoRep.findByRestaurantId(restaurantId);

        if (buscar != null && !buscar.trim().isEmpty()) {
            String filtro = buscar.trim().toLowerCase();
            productos = productos.stream()
                    .filter(p -> (p.getName() != null && p.getName().toLowerCase().contains(filtro))
                            || (p.getDescripcion() != null && p.getDescripcion().toLowerCase().contains(filtro)))
                    .collect(Collectors.toList());
        }

        List<ProductoInventarioDTO> dtos = productos.stream()
                .map(this::convertirAProductoDTO)
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    /**
     * Obtiene el detalle de un producto específico del inventario por ID.
     */
    @GetMapping("/inventario/{id}")
    public ResponseEntity<?> getProductoPorId(@PathVariable Long id) {
        Long restaurantId = obtenerRestaurantId();
        Producto producto = productoRep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Producto no encontrado"));

        return ResponseEntity.ok(convertirAProductoDTO(producto));
    }

    // =========================================================================
    // 3. INVENTARIO: BAJOS, NORMALES Y CRÍTICOS
    // =========================================================================

    /**
     * Clasifica los productos del inventario en:
     * - Críticos: stock <= 5
     * - Bajos: 5 < stock <= 15
     * - Normales: stock > 15
     * Incluye conteos y listas agrupadas para dashboards móviles.
     */
    @GetMapping({"/inventario/niveles", "/inventario/estado"})
    public ResponseEntity<InventarioNivelesDTO> getInventarioNiveles() {
        Long restaurantId = obtenerRestaurantId();
        List<Producto> productos = productoRep.findByRestaurantId(restaurantId);

        List<ProductoInventarioDTO> criticos = new ArrayList<>();
        List<ProductoInventarioDTO> bajos = new ArrayList<>();
        List<ProductoInventarioDTO> normales = new ArrayList<>();

        for (Producto p : productos) {
            ProductoInventarioDTO dto = convertirAProductoDTO(p);
            if (p.getStock() <= UMBRAL_STOCK_CRITICO) {
                criticos.add(dto);
            } else if (p.getStock() <= UMBRAL_STOCK_BAJO) {
                bajos.add(dto);
            } else {
                normales.add(dto);
            }
        }

        boolean requiereAtencion = !criticos.isEmpty() || !bajos.isEmpty();

        InventarioNivelesDTO resultado = new InventarioNivelesDTO(
                productos.size(),
                criticos.size(),
                bajos.size(),
                normales.size(),
                requiereAtencion,
                criticos,
                bajos,
                normales
        );

        return ResponseEntity.ok(resultado);
    }

    @GetMapping("/inventario/criticos")
    public ResponseEntity<List<ProductoInventarioDTO>> getProductosCriticos() {
        Long restaurantId = obtenerRestaurantId();
        List<ProductoInventarioDTO> criticos = productoRep.findByRestaurantId(restaurantId).stream()
                .filter(p -> p.getStock() <= UMBRAL_STOCK_CRITICO)
                .map(this::convertirAProductoDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(criticos);
    }

    @GetMapping("/inventario/bajos")
    public ResponseEntity<List<ProductoInventarioDTO>> getProductosBajos() {
        Long restaurantId = obtenerRestaurantId();
        List<ProductoInventarioDTO> bajos = productoRep.findByRestaurantId(restaurantId).stream()
                .filter(p -> p.getStock() > UMBRAL_STOCK_CRITICO && p.getStock() <= UMBRAL_STOCK_BAJO)
                .map(this::convertirAProductoDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(bajos);
    }

    @GetMapping("/inventario/normales")
    public ResponseEntity<List<ProductoInventarioDTO>> getProductosNormales() {
        Long restaurantId = obtenerRestaurantId();
        List<ProductoInventarioDTO> normales = productoRep.findByRestaurantId(restaurantId).stream()
                .filter(p -> p.getStock() > UMBRAL_STOCK_BAJO)
                .map(this::convertirAProductoDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(normales);
    }

    // =========================================================================
    // 4. VENTAS TOTALES
    // =========================================================================

    /**
     * Calcula las ventas totales del restaurante, incluyendo transacciones y ventas de hoy.
     */
    @GetMapping("/ventas/totales")
    public ResponseEntity<VentasTotalesDTO> getVentasTotales() {
        Long restaurantId = obtenerRestaurantId();
        VentasTotalesDTO dto = calcularVentasTotalesInterno(restaurantId);
        return ResponseEntity.ok(dto);
    }

    // =========================================================================
    // 5. PROMEDIO DE VENTAS (Ticket Promedio)
    // =========================================================================

    /**
     * Calcula el promedio de venta (ticket promedio por orden/factura) global y del día.
     */
    @GetMapping("/ventas/promedio")
    public ResponseEntity<PromedioVentasDTO> getPromedioVentas() {
        Long restaurantId = obtenerRestaurantId();
        VentasTotalesDTO totales = calcularVentasTotalesInterno(restaurantId);

        double promedio = totales.getCantidadVentas() > 0
                ? totales.getTotalVentas() / totales.getCantidadVentas()
                : 0.0;

        double promedioHoy = totales.getCantidadVentasHoy() > 0
                ? totales.getVentasHoy() / totales.getCantidadVentasHoy()
                : 0.0;

        PromedioVentasDTO dto = new PromedioVentasDTO(
                redondear2(promedio),
                formatearDinero(promedio),
                redondear2(promedioHoy),
                formatearDinero(promedioHoy),
                redondear2(totales.getTotalVentas()),
                totales.getCantidadVentas()
        );

        return ResponseEntity.ok(dto);
    }

    // =========================================================================
    // 6. MEJOR VENTA
    // =========================================================================

    /**
     * Retorna la venta con el monto más alto registrada en el restaurante,
     * con información de mesa, mesero, fecha y detalle de ítems.
     */
    @GetMapping("/ventas/mejor")
    public ResponseEntity<MejorVentaDTO> getMejorVenta() {
        Long restaurantId = obtenerRestaurantId();
        MejorVentaDTO dto = obtenerMejorVentaInterno(restaurantId);
        return ResponseEntity.ok(dto);
    }

    // =========================================================================
    // 7. PLATILLO MÁS VENDIDO
    // =========================================================================

    /**
     * Identifica el platillo #1 más vendido en cantidad de unidades,
     * calculando además el total de ingresos generados y su porcentaje del total.
     */
    @GetMapping("/platillos/mas-vendido")
    public ResponseEntity<?> getPlatilloMasVendido() {
        Long restaurantId = obtenerRestaurantId();
        List<PlatilloRankingDTO> ranking = calcularRankingPlatillos(restaurantId, 1);

        if (ranking.isEmpty()) {
            return ResponseEntity.ok(Map.of(
                    "mensaje", "No hay platillos vendidos registrados aún",
                    "nombre", "Sin registros",
                    "unidadesVendidas", 0,
                    "ingresosTotales", 0.0
            ));
        }

        return ResponseEntity.ok(ranking.get(0));
    }

    // =========================================================================
    // 8. MÁS PLATILLOS VENDIDOS (Ranking / Top)
    // =========================================================================

    /**
     * Retorna el ranking de los platillos más vendidos ordenados descendentemente.
     * Incluye unidades vendidas, ingresos y porcentaje de participación.
     */
    @GetMapping({"/platillos/mas-vendidos", "/platillos/ranking"})
    public ResponseEntity<?> getMasPlatillosVendidos(@RequestParam(defaultValue = "10") int limite) {
        Long restaurantId = obtenerRestaurantId();
        List<PlatilloRankingDTO> ranking = calcularRankingPlatillos(restaurantId, limite);

        int totalUnidades = ranking.stream().mapToInt(PlatilloRankingDTO::getUnidadesVendidas).sum();

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("totalPlatillosVendidos", totalUnidades);
        respuesta.put("totalPlatillosEnRanking", ranking.size());
        respuesta.put("ranking", ranking);

        return ResponseEntity.ok(respuesta);
    }

    // =========================================================================
    // 9. DASHBOARD MÓVIL UNIFICADO (Todo en 1 sola llamada para Flutter)
    // =========================================================================

    /**
     * Endpoint consolidado para la pantalla principal de la aplicación móvil.
     * Retorna ventas totales, promedio, mejor venta, platillo estrella,
     * top de platillos y resumen de inventario en una única respuesta JSON.
     */
    @GetMapping("/dashboard")
    public ResponseEntity<MobileDashboardDTO> getDashboard() {
        Long restaurantId = obtenerRestaurantId();

        // Info básica del restaurante
        Map<String, Object> restInfo = new LinkedHashMap<>();
        restInfo.put("id", restaurantId);
        if (restaurantRep != null) {
            restaurantRep.findById(restaurantId).ifPresent(r -> {
                restInfo.put("nombre", r.getNombre());
                restInfo.put("correo", r.getCorreo());
                restInfo.put("activo", r.isActivo());
            });
        }

        // Métricas de ventas
        VentasTotalesDTO ventasTotales = calcularVentasTotalesInterno(restaurantId);

        double promedio = ventasTotales.getCantidadVentas() > 0
                ? ventasTotales.getTotalVentas() / ventasTotales.getCantidadVentas()
                : 0.0;
        double promedioHoy = ventasTotales.getCantidadVentasHoy() > 0
                ? ventasTotales.getVentasHoy() / ventasTotales.getCantidadVentasHoy()
                : 0.0;

        PromedioVentasDTO promedioVentas = new PromedioVentasDTO(
                redondear2(promedio),
                formatearDinero(promedio),
                redondear2(promedioHoy),
                formatearDinero(promedioHoy),
                redondear2(ventasTotales.getTotalVentas()),
                ventasTotales.getCantidadVentas()
        );

        MejorVentaDTO mejorVenta = obtenerMejorVentaInterno(restaurantId);

        // Platillos
        List<PlatilloRankingDTO> ranking = calcularRankingPlatillos(restaurantId, 5);
        PlatilloRankingDTO masVendido = !ranking.isEmpty() ? ranking.get(0) : null;

        // Inventario
        List<Producto> productos = productoRep.findByRestaurantId(restaurantId);
        List<ProductoInventarioDTO> criticos = new ArrayList<>();
        List<ProductoInventarioDTO> bajos = new ArrayList<>();
        List<ProductoInventarioDTO> normales = new ArrayList<>();

        for (Producto p : productos) {
            ProductoInventarioDTO dto = convertirAProductoDTO(p);
            if (p.getStock() <= UMBRAL_STOCK_CRITICO) {
                criticos.add(dto);
            } else if (p.getStock() <= UMBRAL_STOCK_BAJO) {
                bajos.add(dto);
            } else {
                normales.add(dto);
            }
        }

        InventarioNivelesDTO resumenInventario = new InventarioNivelesDTO(
                productos.size(),
                criticos.size(),
                bajos.size(),
                normales.size(),
                !criticos.isEmpty() || !bajos.isEmpty(),
                criticos,
                bajos,
                normales
        );

        MobileDashboardDTO dashboard = new MobileDashboardDTO(
                restInfo,
                ventasTotales,
                promedioVentas,
                mejorVenta,
                masVendido,
                ranking,
                resumenInventario
        );

        return ResponseEntity.ok(dashboard);
    }

    // =========================================================================
    // MÉTODOS DE SOPORTE Y CÁLCULOS
    // =========================================================================

    private Long obtenerRestaurantId() {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No se identificó el restaurante en el token JWT");
        }
        return restaurantId;
    }

    private ProductoInventarioDTO convertirAProductoDTO(Producto p) {
        String nivel;
        String color;

        if (p.getStock() <= UMBRAL_STOCK_CRITICO) {
            nivel = "CRITICO";
            color = "danger";
        } else if (p.getStock() <= UMBRAL_STOCK_BAJO) {
            nivel = "BAJO";
            color = "warning";
        } else {
            nivel = "NORMAL";
            color = "success";
        }

        String uMedida = p.getUMedida() != null ? p.getUMedida() : (p.getCant() != null ? p.getCant() : "unidad");

        return new ProductoInventarioDTO(
                p.getIdLong(),
                p.getName(),
                p.getDescripcion(),
                uMedida,
                p.getPrice(),
                p.getStock(),
                p.isActivo(),
                nivel,
                color
        );
    }

    private VentasTotalesDTO calcularVentasTotalesInterno(Long restaurantId) {
        List<Factura> facturas = facturaRep.findByRestaurantId(restaurantId);
        List<Pedido> pedidos = pedidoRep.findByRestaurantId(restaurantId);

        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();

        double totalVentas = 0.0;
        long cantidadVentas = 0;
        double ventasHoy = 0.0;
        long cantidadHoy = 0;
        long totalItemsVendidos = 0;

        if (!facturas.isEmpty()) {
            // Basado en facturas
            totalVentas = facturas.stream().mapToDouble(Factura::getTotal).sum();
            cantidadVentas = facturas.size();

            ventasHoy = facturas.stream()
                    .filter(f -> f.getFecha() != null && !f.getFecha().isBefore(startOfDay) && f.getFecha().isBefore(endOfDay))
                    .mapToDouble(Factura::getTotal)
                    .sum();

            cantidadHoy = facturas.stream()
                    .filter(f -> f.getFecha() != null && !f.getFecha().isBefore(startOfDay) && f.getFecha().isBefore(endOfDay))
                    .count();

            for (Factura f : facturas) {
                if (f.getItems() != null) {
                    for (ItemPedido it : f.getItems()) {
                        totalItemsVendidos += obtenerUnidadesItem(it);
                    }
                }
            }
        } else if (!pedidos.isEmpty()) {
            // Respaldo basado en pedidos
            totalVentas = pedidos.stream().mapToDouble(Pedido::getTotal).sum();
            cantidadVentas = pedidos.size();

            ventasHoy = pedidos.stream()
                    .filter(p -> p.getFecha() != null && !p.getFecha().isBefore(startOfDay) && p.getFecha().isBefore(endOfDay))
                    .mapToDouble(Pedido::getTotal)
                    .sum();

            cantidadHoy = pedidos.stream()
                    .filter(p -> p.getFecha() != null && !p.getFecha().isBefore(startOfDay) && p.getFecha().isBefore(endOfDay))
                    .count();

            for (Pedido p : pedidos) {
                if (p.getItems() != null) {
                    for (ItemPedido it : p.getItems()) {
                        totalItemsVendidos += obtenerUnidadesItem(it);
                    }
                }
            }
        }

        return new VentasTotalesDTO(
                redondear2(totalVentas),
                formatearDinero(totalVentas),
                cantidadVentas,
                totalItemsVendidos,
                redondear2(ventasHoy),
                formatearDinero(ventasHoy),
                cantidadHoy
        );
    }

    private MejorVentaDTO obtenerMejorVentaInterno(Long restaurantId) {
        List<Factura> facturas = facturaRep.findByRestaurantId(restaurantId);

        if (!facturas.isEmpty()) {
            Factura mejorFactura = facturas.stream()
                    .max(Comparator.comparingDouble(Factura::getTotal))
                    .orElse(null);

            if (mejorFactura != null) {
                return mapearFacturaAMejorVenta(mejorFactura);
            }
        }

        // Si no hay facturas, buscar en pedidos
        List<Pedido> pedidos = pedidoRep.findByRestaurantId(restaurantId);
        if (!pedidos.isEmpty()) {
            Pedido mejorPedido = pedidos.stream()
                    .max(Comparator.comparingDouble(Pedido::getTotal))
                    .orElse(null);

            if (mejorPedido != null) {
                return mapearPedidoAMejorVenta(mejorPedido);
            }
        }

        return new MejorVentaDTO("0", "0", 0.0, "$0.00", LocalDateTime.now(), "Sin ventas registradas", "N/A", "N/A", 0, Collections.emptyList());
    }

    private MejorVentaDTO mapearFacturaAMejorVenta(Factura f) {
        List<MejorVentaDTO.ItemVentaDTO> itemDtos = new ArrayList<>();
        int totalItemsCount = 0;

        if (f.getItems() != null) {
            for (ItemPedido it : f.getItems()) {
                int unidades = obtenerUnidadesItem(it);
                double precio = it.getPrice() != null ? it.getPrice() : 0.0;
                double subtotal = unidades * precio;
                totalItemsCount += unidades;
                itemDtos.add(new MejorVentaDTO.ItemVentaDTO(
                        it.getName() != null ? it.getName() : "Item",
                        unidades,
                        redondear2(precio),
                        redondear2(subtotal)
                ));
            }
        }

        String fechaStr = f.getFecha() != null ? f.getFecha().format(DATE_FORMATTER) : "N/D";
        String mesa = f.getMesaNum() != null ? "Mesa " + f.getMesaNum() : "Mesa N/D";
        String mesero = f.getMeseroName() != null ? f.getMeseroName() : "No especificado";

        return new MejorVentaDTO(
                f.getId() != null ? f.getId() : "0",
                f.getPedidoId() != null ? f.getPedidoId() : "N/A",
                redondear2(f.getTotal()),
                formatearDinero(f.getTotal()),
                f.getFecha(),
                fechaStr,
                mesa,
                mesero,
                totalItemsCount,
                itemDtos
        );
    }

    private MejorVentaDTO mapearPedidoAMejorVenta(Pedido p) {
        List<MejorVentaDTO.ItemVentaDTO> itemDtos = new ArrayList<>();
        int totalItemsCount = 0;

        if (p.getItems() != null) {
            for (ItemPedido it : p.getItems()) {
                int unidades = obtenerUnidadesItem(it);
                double precio = it.getPrice() != null ? it.getPrice() : 0.0;
                double subtotal = unidades * precio;
                totalItemsCount += unidades;
                itemDtos.add(new MejorVentaDTO.ItemVentaDTO(
                        it.getName() != null ? it.getName() : "Item",
                        unidades,
                        redondear2(precio),
                        redondear2(subtotal)
                ));
            }
        }

        String fechaStr = p.getFecha() != null ? p.getFecha().format(DATE_FORMATTER) : "N/D";
        String mesa = "Mesa " + p.getMesaNum();
        String mesero = p.getMeseroName() != null ? p.getMeseroName() : "No especificado";

        return new MejorVentaDTO(
                "N/A",
                p.getId() != null ? p.getId() : "0",
                redondear2(p.getTotal()),
                formatearDinero(p.getTotal()),
                p.getFecha(),
                fechaStr,
                mesa,
                mesero,
                totalItemsCount,
                itemDtos
        );
    }

    private List<PlatilloRankingDTO> calcularRankingPlatillos(Long restaurantId, int limite) {
        List<Pedido> pedidos = pedidoRep.findByRestaurantId(restaurantId);
        List<Factura> facturas = facturaRep.findByRestaurantId(restaurantId);

        // Agrupación por nombre: [unidadesVendidas, ingresosTotales]
        Map<String, double[]> acumulado = new LinkedHashMap<>();

        // 1. Extraer ítems desde Pedidos
        if (!pedidos.isEmpty()) {
            for (Pedido p : pedidos) {
                if (p.getItems() == null) continue;
                for (ItemPedido it : p.getItems()) {
                    acumularItem(acumulado, it);
                }
            }
        } else if (!facturas.isEmpty()) {
            // 2. Si no hay pedidos, extraer desde Facturas
            for (Factura f : facturas) {
                if (f.getItems() == null) continue;
                for (ItemPedido it : f.getItems()) {
                    acumularItem(acumulado, it);
                }
            }
        }

        if (acumulado.isEmpty()) {
            return Collections.emptyList();
        }

        double totalUnidadesVendidas = acumulado.values().stream()
                .mapToDouble(arr -> arr[0])
                .sum();

        List<PlatilloRankingDTO> ranking = new ArrayList<>();
        int posicion = 1;

        List<Map.Entry<String, double[]>> ordenados = acumulado.entrySet().stream()
                .sorted((a, b) -> Double.compare(b.getValue()[0], a.getValue()[0]))
                .limit(limite > 0 ? limite : 10)
                .collect(Collectors.toList());

        for (Map.Entry<String, double[]> entry : ordenados) {
            String nombre = entry.getKey();
            int unidades = (int) entry.getValue()[0];
            double ingresos = entry.getValue()[1];
            double precioUnitario = unidades > 0 ? (ingresos / unidades) : 0.0;
            double porcentaje = totalUnidadesVendidas > 0 ? ((unidades / totalUnidadesVendidas) * 100.0) : 0.0;

            ranking.add(new PlatilloRankingDTO(
                    posicion++,
                    nombre,
                    unidades,
                    redondear2(precioUnitario),
                    redondear2(ingresos),
                    formatearDinero(ingresos),
                    redondear2(porcentaje)
            ));
        }

        return ranking;
    }

    private void acumularItem(Map<String, double[]> acumulado, ItemPedido it) {
        if (it == null) return;
        String nombre = it.getName() != null && !it.getName().trim().isEmpty() ? it.getName().trim() : "Platillo";
        int unidades = obtenerUnidadesItem(it);
        double precio = it.getPrice() != null ? it.getPrice() : 0.0;
        double ingresos = unidades * precio;

        double[] datos = acumulado.computeIfAbsent(nombre, k -> new double[]{0.0, 0.0});
        datos[0] += unidades;
        datos[1] += ingresos;
    }

    private int obtenerUnidadesItem(ItemPedido it) {
        if (it == null) return 1;
        if (it.getUnidades() != null && it.getUnidades() > 0) {
            return it.getUnidades();
        }
        if (it.getCant() != null && !it.getCant().trim().isEmpty()) {
            try {
                String clean = it.getCant().replaceAll("[^0-9]", "").trim();
                if (!clean.isEmpty()) {
                    int val = Integer.parseInt(clean);
                    if (val > 0) return val;
                }
            } catch (Exception ignored) {
            }
        }
        return 1;
    }

    private double redondear2(double valor) {
        return Math.round(valor * 100.0) / 100.0;
    }

    private String formatearDinero(double valor) {
        return String.format(Locale.US, "$%.2f", valor);
    }
}

