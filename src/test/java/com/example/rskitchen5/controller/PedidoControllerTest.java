package com.example.rskitchen5.controller;

import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Repository.PedidoRep;
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
class PedidoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private PedidoRep pedidoRep;

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = { "ROLE_ADMIN" })
    @DisplayName("GET /pedidos debe renderizar la vista 'pedido' correctamente con pedidos pagados y pendientes")
    void testGetPedidos() throws Exception {
        Pedido pedido1 = new Pedido();
        pedido1.setPagado(false);
        pedidoRep.save(pedido1);

        Pedido pedido2 = new Pedido();
        pedido2.setPagado(true);
        pedidoRep.save(pedido2);

        mockMvc.perform(get("/pedidos"))
                .andExpect(status().isOk())
                .andExpect(view().name("pedido"));
    }
}