package com.example.rskitchen5.controller;

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
class LogisControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("GET /home debe cargar el dashboard con todas las métricas operativas requeridas")
    void testHomeDashboardMetricsPresent() throws Exception {
        mockMvc.perform(get("/home"))
                .andExpect(status().isOk())
                .andExpect(view().name("start"))
                .andExpect(model().attributeExists("totalMesas"))
                .andExpect(model().attributeExists("mesasOcupadas"))
                .andExpect(model().attributeExists("mesasLibres"))
                .andExpect(model().attributeExists("mesas"))
                .andExpect(model().attributeExists("pedidosHoy"))
                .andExpect(model().attributeExists("pedidosActivos"))
                .andExpect(model().attributeExists("ingresosHoy"))
                .andExpect(model().attributeExists("meserosActivos"))
                .andExpect(model().attributeExists("productosCriticos"));
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("GET /start debe ser un alias funcional de /home")
    void testStartEndpointAlias() throws Exception {
        mockMvc.perform(get("/start"))
                .andExpect(status().isOk())
                .andExpect(view().name("start"))
                .andExpect(model().attributeExists("totalMesas"));
    }
}
