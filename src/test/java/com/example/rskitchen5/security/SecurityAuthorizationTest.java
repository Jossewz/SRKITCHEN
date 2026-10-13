package com.example.rskitchen5.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class SecurityAuthorizationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("Rutas públicas como /landing deben ser accesibles anónimamente")
    void testPublicLandingAccessibleWithoutAuth() throws Exception {
        mockMvc.perform(get("/landing"))
                .andExpect(status().isOk())
                .andExpect(view().name("landing"));
    }

    @Test
    @DisplayName("Ruta /login debe ser accesible anónimamente")
    void testLoginPageAccessibleWithoutAuth() throws Exception {
        mockMvc.perform(get("/login"))
                .andExpect(status().isOk())
                .andExpect(view().name("logis"));
    }

    @Test
    @DisplayName("Acceso no autenticado a /home debe redirigir a /login")
    void testUnauthenticatedHomeRedirectsToLogin() throws Exception {
        mockMvc.perform(get("/home"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/login"));
    }

    @Test
    @DisplayName("Acceso no autenticado a /mesa debe redirigir a /login")
    void testUnauthenticatedMesaRedirectsToLogin() throws Exception {
        mockMvc.perform(get("/mesa"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/login"));
    }

    @Test
    @WithMockUser(username = "mesero@rskitchen.com", authorities = {"ROLE_MESERO"})
    @DisplayName("Usuario con ROLE_MESERO puede acceder a /home")
    void testMeseroCanAccessHome() throws Exception {
        mockMvc.perform(get("/home"))
                .andExpect(status().isOk())
                .andExpect(view().name("start"));
    }

    @Test
    @WithMockUser(username = "mesero@rskitchen.com", authorities = {"ROLE_MESERO"})
    @DisplayName("Usuario con ROLE_MESERO puede acceder a /mesa")
    void testMeseroCanAccessMesa() throws Exception {
        mockMvc.perform(get("/mesa"))
                .andExpect(status().isOk())
                .andExpect(view().name("mesa"));
    }

    @Test
    @WithMockUser(username = "mesero@rskitchen.com", authorities = {"ROLE_MESERO"})
    @DisplayName("Usuario con ROLE_MESERO NO puede acceder a /platillos (recibe 403 Forbidden)")
    void testMeseroForbiddenFromPlatillos() throws Exception {
        mockMvc.perform(get("/platillos"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "mesero@rskitchen.com", authorities = {"ROLE_MESERO"})
    @DisplayName("Usuario con ROLE_MESERO NO puede acceder a /producto (recibe 403 Forbidden)")
    void testMeseroForbiddenFromProducto() throws Exception {
        mockMvc.perform(get("/producto"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("Usuario con ROLE_ADMIN puede acceder a /platillos")
    void testAdminCanAccessPlatillos() throws Exception {
        mockMvc.perform(get("/platillos"))
                .andExpect(status().isOk())
                .andExpect(view().name("platillos"));
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("Usuario con ROLE_ADMIN puede acceder a /producto")
    void testAdminCanAccessProducto() throws Exception {
        mockMvc.perform(get("/producto"))
                .andExpect(status().isOk())
                .andExpect(view().name("productos"));
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("Usuario con ROLE_ADMIN puede acceder a /home")
    void testAdminCanAccessHome() throws Exception {
        mockMvc.perform(get("/home"))
                .andExpect(status().isOk())
                .andExpect(view().name("start"));
    }
}
