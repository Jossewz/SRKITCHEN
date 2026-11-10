package com.example.rskitchen5.controller;

import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.UserRep;
import com.example.rskitchen5.Security.UserPrincipal;
import org.junit.jupiter.api.BeforeEach;
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

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class MeseroControllerTest {

        @Autowired
        private MockMvc mockMvc;

        @Autowired
        private UserRep userRep;

        private UsernamePasswordAuthenticationToken createAdminAuth(Long restaurantId) {
                UserPrincipal principal = new UserPrincipal(
                                "admin@rskitchen.com",
                                "admin123",
                                "ROLE_ADMIN",
                                restaurantId,
                                "Admin",
                                List.of(new SimpleGrantedAuthority("ROLE_ADMIN")));
                return new UsernamePasswordAuthenticationToken(
                                principal, "admin123", principal.getAuthorities());
        }

        @Test
        @DisplayName("GET /mesero/registro con meseros debe renderizar mesero.html con data-attributes para Alpine.js")
        void testRenderMeseroTemplate() throws Exception {
                User mesero = new User();
                mesero.setName("Pedro Mesero");
                mesero.setMail("pedro_render@test.com");
                mesero.setPassword("pass123");
                mesero.setRol("ROLE_MESERO");
                mesero.setRestaurantId(1L);
                mesero.setActivo(true);
                mesero.setId_mesero("M01");
                userRep.save(mesero);

                MvcResult result = mockMvc.perform(get("/mesero/registro").with(authentication(createAdminAuth(1L))))
                                .andExpect(status().isOk())
                                .andExpect(view().name("mesero"))
                                .andReturn();

                String html = result.getResponse().getContentAsString();
                assertTrue(html.contains(
                                "@click=\"openEdit($el.dataset.id, $el.dataset.idmesero, $el.dataset.name, $el.dataset.mail)\""),
                                "El botón de editar debe invocar openEdit con los dataset attributes");
                assertTrue(html.contains("data-idmesero=\"M01\""),
                                "El atributo data-idmesero debe estar presente en el botón");
                assertTrue(html.contains("data-name=\"Pedro Mesero\""),
                                "El atributo data-name debe estar presente en el botón");
        }

        @Test
        @DisplayName("POST /mesero/editar debe actualizar los datos del mesero")
        void testEditarMesero() throws Exception {
                User mesero = new User();
                mesero.setName("Carlos Original");
                mesero.setMail("carlos.orig@test.com");
                mesero.setPassword("pass123");
                mesero.setRol("ROLE_MESERO");
                mesero.setRestaurantId(1L);
                mesero.setActivo(true);
                mesero.setId_mesero("MES-ORIG");
                mesero = userRep.save(mesero);

                mockMvc.perform(post("/mesero/editar")
                                .with(authentication(createAdminAuth(1L)))
                                .with(csrf())
                                .param("id", String.valueOf(mesero.getId()))
                                .param("name", "Carlos Actualizado")
                                .param("mail", "carlos.nuevo@test.com")
                                .param("id_mesero", "MES-MOD")
                                .param("nuevaPassword", "nuevaClave123"))
                                .andExpect(status().is3xxRedirection())
                                .andExpect(redirectedUrl("/mesero/registro"))
                                .andExpect(flash().attributeExists("mensajeExito"));

                User updated = userRep.findById(mesero.getId()).orElseThrow();
                assertEquals("Carlos Actualizado", updated.getName());
                assertEquals("carlos.nuevo@test.com", updated.getMail());
                assertEquals("MES-MOD", updated.getId_mesero());
        }

        @Test
        @DisplayName("POST /mesero/editar con nombre vacío debe mostrar mensaje de error")
        void testEditarMeseroNombreVacio() throws Exception {
                User mesero = new User();
                mesero.setName("Ana Mesero");
                mesero.setMail("ana.val@test.com");
                mesero.setPassword("pass123");
                mesero.setRol("ROLE_MESERO");
                mesero.setRestaurantId(1L);
                mesero.setActivo(true);
                mesero = userRep.save(mesero);

                mockMvc.perform(post("/mesero/editar")
                                .with(authentication(createAdminAuth(1L)))
                                .with(csrf())
                                .param("id", String.valueOf(mesero.getId()))
                                .param("name", "   ")
                                .param("mail", "ana.val@test.com")
                                .param("id_mesero", "")
                                .param("nuevaPassword", ""))
                                .andExpect(status().is3xxRedirection())
                                .andExpect(redirectedUrl("/mesero/registro"))
                                .andExpect(flash().attributeExists("mensajeError"));
        }

        @Test
        @DisplayName("POST /mesero/{id}/toggle-estado debe cambiar estado activo")
        void testToggleEstado() throws Exception {
                User mesero = new User();
                mesero.setName("Luis Toggle");
                mesero.setMail("luis.toggle@test.com");
                mesero.setPassword("pass123");
                mesero.setRol("ROLE_MESERO");
                mesero.setRestaurantId(1L);
                mesero.setActivo(true);
                mesero = userRep.save(mesero);

                mockMvc.perform(post("/mesero/" + mesero.getId() + "/toggle-estado")
                                .with(authentication(createAdminAuth(1L)))
                                .with(csrf()))
                                .andExpect(status().is3xxRedirection())
                                .andExpect(redirectedUrl("/mesero/registro"))
                                .andExpect(flash().attributeExists("mensajeExito"));

                User updated = userRep.findById(mesero.getId()).orElseThrow();
                assertFalse(updated.isActivo());
        }
}