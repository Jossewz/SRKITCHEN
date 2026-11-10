package com.example.rskitchen5.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class MesaControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @WithMockUser(username = "mesero@rskitchen.com", authorities = {"ROLE_MESERO"})
    @DisplayName("GET /mesa debe retornar la vista 'mesa' con lista de mesas y modelos")
    void testMostrarVistaMesa() throws Exception {
        mockMvc.perform(get("/mesa"))
                .andExpect(status().isOk())
                .andExpect(view().name("mesa"))
                .andExpect(model().attributeExists("listar"))
                .andExpect(model().attributeExists("nuevaMesa"))
                .andExpect(model().attributeExists("nombresMeseros"))
                .andExpect(model().attributeExists("pedidosPorMesa"));
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("POST /mesa/crear debe crear la mesa y redirigir a /mesa")
    void testCrearMesa() throws Exception {
        mockMvc.perform(post("/mesa/crear")
                        .with(csrf())
                        .param("num", "99")
                        .param("ocupado", "false"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/mesa"))
                .andExpect(flash().attributeExists("mensajeExito"));
    }
}
