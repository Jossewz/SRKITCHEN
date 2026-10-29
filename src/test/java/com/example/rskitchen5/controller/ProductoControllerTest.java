package com.example.rskitchen5.controller;

import com.example.rskitchen5.Model.Producto;
import com.example.rskitchen5.Repository.ProductoRep;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.flash;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

@SpringBootTest
@AutoConfigureMockMvc
@DisplayName("Pruebas Unitarias e Integración - ProductoController")
class ProductoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ProductoRep productoRep;

    private Producto productoEjemplo;

    @BeforeEach
    void setUp() {
        productoRep.deleteAll();
        productoEjemplo = new Producto();
        productoEjemplo.setName("Harina de Trigo");
        productoEjemplo.setDescripcion("Harina de trigo especial para pastas y panes");
        productoEjemplo.setUMedida("kg (kilogramo)");
        productoEjemplo.setCant("kg (kilogramo)");
        productoEjemplo.setPrice(12.50);
        productoEjemplo.setStock(40);
        productoEjemplo.setActivo(true);
        productoEjemplo = productoRep.save(productoEjemplo);
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("GET /producto debe mostrar la vista 'productos' con lista y modelo de formulario")
    void testGetAllProductos() throws Exception {
        mockMvc.perform(get("/producto"))
                .andExpect(status().isOk())
                .andExpect(view().name("productos"))
                .andExpect(model().attributeExists("productos"))
                .andExpect(model().attributeExists("productoForm"));
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("POST /producto/guardar o /producto/agregar debe registrar un nuevo producto con su uMedida")
    void testAgregarProducto() throws Exception {
        mockMvc.perform(post("/producto/guardar")
                        .with(csrf())
                        .param("name", "Ajo")
                        .param("uMedida", "kg (kilogramo)")
                        .param("stock", "15"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/producto"))
                .andExpect(flash().attributeExists("mensajeExito"));

        Producto creado = productoRep.findByName("Ajo").orElseThrow();
        assertEquals("kg (kilogramo)", creado.getUMedida());
        assertEquals("kg (kilogramo)", creado.getCant());
        assertEquals(15, creado.getStock());
        assertTrue(creado.isActivo());
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("GET /producto/editar/{id} debe cargar el producto en 'productoForm'")
    void testEditarProductoGet() throws Exception {
        mockMvc.perform(get("/producto/editar/" + productoEjemplo.getId()))
                .andExpect(status().isOk())
                .andExpect(view().name("productos"))
                .andExpect(model().attributeExists("productos"))
                .andExpect(model().attributeExists("productoForm"));
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("POST /producto/actualizar debe modificar los datos y la unidad de medida del producto")
    void testActualizarProducto() throws Exception {
        mockMvc.perform(post("/producto/actualizar")
                        .with(csrf())
                        .param("id", productoEjemplo.getId())
                        .param("name", "Harina de Trigo Integral")
                        .param("uMedida", "Cartón")
                        .param("stock", "30"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/producto"))
                .andExpect(flash().attributeExists("mensajeExito"));

        Producto actualizado = productoRep.findById(productoEjemplo.getId()).orElseThrow();
        assertEquals("Harina de Trigo Integral", actualizado.getName());
        assertEquals("Cartón", actualizado.getUMedida());
        assertEquals(30, actualizado.getStock());
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("POST /producto/desactivar/{id} debe cambiar el estado activo a false")
    void testDesactivarProducto() throws Exception {
        mockMvc.perform(post("/producto/desactivar/" + productoEjemplo.getId())
                        .with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/producto"))
                .andExpect(flash().attributeExists("mensajeExito"));

        Producto desactivado = productoRep.findById(productoEjemplo.getId()).orElseThrow();
        assertFalse(desactivado.isActivo());
    }

    @Test
    @WithMockUser(username = "admin@rskitchen.com", authorities = {"ROLE_ADMIN"})
    @DisplayName("POST /producto/{id}/toggle-estado debe alternar entre activo e inactivo")
    void testToggleEstadoProducto() throws Exception {
        mockMvc.perform(post("/producto/" + productoEjemplo.getId() + "/toggle-estado")
                        .with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/producto"));

        Producto modificado = productoRep.findById(productoEjemplo.getId()).orElseThrow();
        assertFalse(modificado.isActivo());

        mockMvc.perform(post("/producto/" + productoEjemplo.getId() + "/toggle-estado")
                        .with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/producto"));

        modificado = productoRep.findById(productoEjemplo.getId()).orElseThrow();
        assertTrue(modificado.isActivo());
    }
}
