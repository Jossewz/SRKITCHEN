package com.example.rskitchen5.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class LandingAndLoginControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("GET / debe renderizar la vista 'landing'")
    void testRootEndpointRendersLanding() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(view().name("landing"));
    }

    @Test
    @DisplayName("GET /landing debe renderizar la vista 'landing'")
    void testLandingEndpointRendersLanding() throws Exception {
        mockMvc.perform(get("/landing"))
                .andExpect(status().isOk())
                .andExpect(view().name("landing"));
    }

    @Test
    @DisplayName("GET /login debe renderizar la vista 'logis'")
    void testLoginEndpointRendersLogis() throws Exception {
        mockMvc.perform(get("/login"))
                .andExpect(status().isOk())
                .andExpect(view().name("logis"));
    }
}
