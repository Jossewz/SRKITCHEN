package com.example.rskitchen5.controller;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Security.UserPrincipal;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;

import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class FacturaViewTest {

        @Autowired
        private MockMvc mockMvc;

        @Autowired
        private FacturaRep facturaRep;

        private UsernamePasswordAuthenticationToken createAuth() {
                UserPrincipal principal = new UserPrincipal(
                                "admin@rskitchen.com", "pass", "ROLE_ADMIN", 1L, "Admin",
                                List.of(new SimpleGrantedAuthority("ROLE_ADMIN")));
                return new UsernamePasswordAuthenticationToken(
                                principal, "pass", principal.getAuthorities());
        }

        @Test
        @DisplayName("factura.html debe renderizar data-url y @click='openDetail($el.dataset.url)' en el botón Ver Detalle")
        void testRenderFacturaTemplate() throws Exception {
                Factura f = new Factura();
                f.setRestaurantId(1L);
                f.setMesaNum("5");
                f.setMeseroName("Carlos");
                f.setTotal(40000.0);
                f = facturaRep.save(f);

                MvcResult result = mockMvc.perform(get("/factura").with(authentication(createAuth())))
                                .andExpect(status().isOk())
                                .andReturn();

                String html = result.getResponse().getContentAsString();
                assertTrue(html.contains("<button type=\"button\""),
                                "Debe existir la etiqueta <button type=\"button\">");
                assertTrue(html.contains("@click=\"openDetail($el.dataset.url)\""),
                                "El botón de ver detalle debe invocar openDetail con $el.dataset.url");
                assertTrue(html.contains("data-url=\"/factura/detalle/" + f.getId() + "\""),
                                "El botón debe contener data-url con la ruta de la factura");
                assertTrue(!html.contains("th:data-url"),
                                "No debe existir texto sin procesar th:data-url en el HTML");
        }

        @Test
        @DisplayName("GET /factura/detalle/{id} debe retornar el fragmento HTML del detalle")
        void testDetalleFacturaEndpoint() throws Exception {
                Factura f = new Factura();
                f.setRestaurantId(1L);
                f.setMesaNum("8");
                f.setMeseroName("Ana");
                f.setTotal(25000.0);
                f = facturaRep.save(f);

                mockMvc.perform(get("/factura/detalle/" + f.getId()).with(authentication(createAuth())))
                                .andExpect(status().isOk())
                                .andExpect(content().string(containsString("Mesa 8")))
                                .andExpect(content().string(containsString("Ana")))
                                .andExpect(content().string(containsString("Comprobante Fiscal")));
        }
}