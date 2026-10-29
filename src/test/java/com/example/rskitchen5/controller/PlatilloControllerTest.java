package com.example.rskitchen5.controller;

import com.example.rskitchen5.Controller.PlatilloController;
import com.example.rskitchen5.Model.Platillo;
import com.example.rskitchen5.Model.Producto;
import com.example.rskitchen5.Repository.PlatilloRep;
import com.example.rskitchen5.Repository.ProductoRep;
import com.example.rskitchen5.Security.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.ui.Model;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("Pruebas Unitarias - PlatilloController con Ingredientes")
class PlatilloControllerTest {

    @Mock
    private PlatilloRep platilloRep;

    @Mock
    private ProductoRep productoRep;

    @Mock
    private Model model;

    @InjectMocks
    private PlatilloController platilloController;

    private MockedStatic<TenantContext> tenantContextMock;

    @BeforeEach
    void setUp() {
        tenantContextMock = mockStatic(TenantContext.class);
        tenantContextMock.when(TenantContext::getCurrentRestaurantId).thenReturn(1L);
    }

    @AfterEach
    void tearDown() {
        tenantContextMock.close();
    }

    @Test
    @DisplayName("getAllPlatillos debe cargar productos y platillos en el modelo")
    void testGetAllPlatillos() {
        Producto prod = new Producto("kg", 1L, "Tomate", 2.0, 10);
        Platillo plat = new Platillo();
        plat.setName("Ensalada");

        when(platilloRep.findByRestaurantId(1L)).thenReturn(List.of(plat));
        when(productoRep.findByRestaurantId(1L)).thenReturn(List.of(prod));

        String view = platilloController.getAllPlatillos(model);

        assertEquals("platillos", view);
        verify(model).addAttribute(eq("platillos"), any());
        verify(model).addAttribute(eq("productos"), any());
        verify(model).addAttribute(eq("platilloNuevo"), any());
    }

    @Test
    @DisplayName("crearPlatillo debe asociar los ingredientes seleccionados y persistir")
    void testCrearPlatilloConIngredientes() {
        Platillo nuevo = new Platillo();
        nuevo.setName("Hamburguesa Doble");
        nuevo.setPrice(18.0);

        Producto carne = new Producto("unidades", 10L, "Carne", 3.0, 50);
        when(productoRep.findById(10L)).thenReturn(Optional.of(carne));

        String view = platilloController.crearPlatillo(nuevo, List.of(10L), List.of(2.0), model);

        assertEquals("redirect:/platillos", view);
        assertEquals(1, nuevo.getIngredientes().size());
        assertEquals(2.0, nuevo.getIngredientes().get(0).getCantidad());
        assertEquals(carne, nuevo.getIngredientes().get(0).getProducto());
        verify(platilloRep).save(nuevo);
    }
}

