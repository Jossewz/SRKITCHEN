package com.example.rskitchen5.controller;

import com.example.rskitchen5.Model.*;
import com.example.rskitchen5.Repository.*;
import com.example.rskitchen5.Security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class MobileApiControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private RestaurantRep restaurantRep;

    @Autowired
    private ProductoRep productoRep;

    @Autowired
    private PedidoRep pedidoRep;

    @Autowired
    private FacturaRep facturaRep;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    private Restaurant testRestaurant;
    private String jwtToken;

    @BeforeEach
    void setup() {
        testRestaurant = new Restaurant();
        testRestaurant.setNombre("Restaurante Móvil Test");
        testRestaurant.setCorreo("movil_test_" + System.currentTimeMillis() + "@test.com");
        testRestaurant.setContraseña(passwordEncoder.encode("clave123"));
        testRestaurant.setActivo(true);
        testRestaurant = restaurantRep.save(testRestaurant);

        jwtToken = "Bearer " + jwtService.generateToken(
                testRestaurant.getCorreo(),
                "ROLE_ADMIN",
                testRestaurant.getId(),
                testRestaurant.getNombre()
        );
    }

    @Test
    @DisplayName("Inicio de sesión de restaurante en /api/mobile/login retorna JWT y datos")
    void testLoginRestaurante() throws Exception {
        String json = String.format("""
            {
                "correo": "%s",
                "contraseña": "clave123"
            }
            """, testRestaurant.getCorreo());

        mockMvc.perform(post("/api/mobile/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.type").value("Bearer"))
                .andExpect(jsonPath("$.restaurantId").value(testRestaurant.getId()))
                .andExpect(jsonPath("$.nombre").value("Restaurante Móvil Test"))
                .andExpect(jsonPath("$.role").value("ADMIN"));
    }

    @Test
    @DisplayName("Inicio de sesión de restaurante con credenciales erróneas retorna 401")
    void testLoginCredencialesInvalidas() throws Exception {
        String json = String.format("""
            {
                "mail": "%s",
                "password": "clave_incorrecta"
            }
            """, testRestaurant.getCorreo());

        mockMvc.perform(post("/api/mobile/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").exists());
    }

    @Test
    @DisplayName("Acceso a inventario lista productos con niveles de stock")
    void testAccesoInventario() throws Exception {
        Producto p1 = new Producto();
        p1.setName("Arroz Extra");
        p1.setStock(20);
        p1.setPrice(3.50);
        p1.setUMedida("kg");
        p1.setRestaurantId(testRestaurant.getId());
        p1.setActivo(true);
        productoRep.save(p1);

        mockMvc.perform(get("/api/mobile/inventario")
                        .header("Authorization", jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$[0].nivelStock").value("NORMAL"));
    }

    @Test
    @DisplayName("Inventario niveles clasifica en críticos, bajos y normales")
    void testInventarioNiveles() throws Exception {
        Producto pCritico = new Producto();
        pCritico.setName("Aceite");
        pCritico.setStock(2); // <= 5 (Crítico)
        pCritico.setPrice(10.0);
        pCritico.setRestaurantId(testRestaurant.getId());
        pCritico.setActivo(true);
        productoRep.save(pCritico);

        Producto pBajo = new Producto();
        pBajo.setName("Harina");
        pBajo.setStock(10); // 6..15 (Bajo)
        pBajo.setPrice(4.0);
        pBajo.setRestaurantId(testRestaurant.getId());
        pBajo.setActivo(true);
        productoRep.save(pBajo);

        Producto pNormal = new Producto();
        pNormal.setName("Papas");
        pNormal.setStock(50); // > 15 (Normal)
        pNormal.setPrice(2.0);
        pNormal.setRestaurantId(testRestaurant.getId());
        pNormal.setActivo(true);
        productoRep.save(pNormal);

        mockMvc.perform(get("/api/mobile/inventario/niveles")
                        .header("Authorization", jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.conteoCriticos").value(greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.conteoBajos").value(greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.conteoNormales").value(greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.requiereAtencion").value(true));
    }

    @Test
    @DisplayName("Ventas totales y promedio de ventas calculan métricas correctamente")
    void testVentasTotalesYPromedio() throws Exception {
        Factura f1 = new Factura();
        f1.setRestaurantId(testRestaurant.getId());
        f1.setTotal(100.0);
        f1.setFecha(LocalDateTime.now());
        f1.setMesaNum("1");
        facturaRep.save(f1);

        Factura f2 = new Factura();
        f2.setRestaurantId(testRestaurant.getId());
        f2.setTotal(200.0);
        f2.setFecha(LocalDateTime.now());
        f2.setMesaNum("2");
        facturaRep.save(f2);

        mockMvc.perform(get("/api/mobile/ventas/totales")
                        .header("Authorization", jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalVentas").value(300.0))
                .andExpect(jsonPath("$.cantidadVentas").value(2));

        mockMvc.perform(get("/api/mobile/ventas/promedio")
                        .header("Authorization", jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.promedioVenta").value(150.0))
                .andExpect(jsonPath("$.cantidadVentas").value(2));
    }

    @Test
    @DisplayName("Mejor venta obtiene la venta de mayor valor")
    void testMejorVenta() throws Exception {
        Factura f1 = new Factura();
        f1.setRestaurantId(testRestaurant.getId());
        f1.setTotal(50.0);
        f1.setFecha(LocalDateTime.now());
        f1.setMesaNum("1");
        facturaRep.save(f1);

        Factura f2 = new Factura();
        f2.setRestaurantId(testRestaurant.getId());
        f2.setTotal(350.0);
        f2.setFecha(LocalDateTime.now());
        f2.setMesaNum("5");
        f2.setMeseroName("Juan Mesero");
        facturaRep.save(f2);

        mockMvc.perform(get("/api/mobile/ventas/mejor")
                        .header("Authorization", jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.monto").value(350.0))
                .andExpect(jsonPath("$.mesa").value("Mesa 5"))
                .andExpect(jsonPath("$.mesero").value("Juan Mesero"));
    }

    @Test
    @DisplayName("Platillo más vendido y ranking de ventas")
    void testPlatilloMasVendidoYRanking() throws Exception {
        Pedido pedido = new Pedido();
        pedido.setRestaurantId(testRestaurant.getId());
        pedido.setFecha(LocalDateTime.now());
        pedido.setMesaNum(3);

        List<ItemPedido> items = new ArrayList<>();
        ItemPedido item1 = new ItemPedido("Lomo Saltado", "fuerte", 35.0, 5, "1");
        item1.setPedido(pedido);
        items.add(item1);

        ItemPedido item2 = new ItemPedido("Ceviche Clásico", "fuerte", 30.0, 12, "2");
        item2.setPedido(pedido);
        items.add(item2);

        pedido.setItems(items);
        pedido.setTotal(535.0);
        pedidoRep.save(pedido);

        // Platillo más vendido debe ser Ceviche Clásico con 12 unidades
        mockMvc.perform(get("/api/mobile/platillos/mas-vendido")
                        .header("Authorization", jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Ceviche Clásico"))
                .andExpect(jsonPath("$.unidadesVendidas").value(12));

        // Ranking completo
        mockMvc.perform(get("/api/mobile/platillos/mas-vendidos")
                        .header("Authorization", jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalPlatillosVendidos").value(17))
                .andExpect(jsonPath("$.ranking[0].nombre").value("Ceviche Clásico"))
                .andExpect(jsonPath("$.ranking[1].nombre").value("Lomo Saltado"));
    }

    @Test
    @DisplayName("Dashboard móvil unificado devuelve todas las métricas en un solo objeto")
    void testDashboardMovil() throws Exception {
        mockMvc.perform(get("/api/mobile/dashboard")
                        .header("Authorization", jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.restaurante.id").value(testRestaurant.getId()))
                .andExpect(jsonPath("$.ventasTotales").exists())
                .andExpect(jsonPath("$.promedioVentas").exists())
                .andExpect(jsonPath("$.mejorVenta").exists())
                .andExpect(jsonPath("$.resumenInventario").exists());
    }
}
