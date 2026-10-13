package com.example.rskitchen5.model;

import com.example.rskitchen5.Model.Producto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Pruebas Unitarias - Modelo Producto")
class ProductoModelTest {

    @Test
    @DisplayName("Debe gestionar stock numérico y cadena de texto de forma segura")
    void testStockManagement() {
        Producto producto = new Producto();
        producto.setName("Arroz Extra");
        producto.setCant("5 kg");
        producto.setPrice(15.50);
        producto.setStock(20);

        assertEquals("Arroz Extra", producto.getName());
        assertEquals("5 kg", producto.getCant());
        assertEquals(15.50, producto.getPrice());
        assertEquals(20, producto.getStock());

        // Probar setter con String
        producto.setStock("35");
        assertEquals(35, producto.getStock());

        // Probar setter con String inválido (no debe lanzar excepción ni romper valor previo)
        producto.setStock("invalido");
        assertEquals(35, producto.getStock());
    }

    @Test
    @DisplayName("Debe manejar ID numérico y conversor seguro de String")
    void testIdHandling() {
        Producto producto = new Producto();
        producto.setId("10");

        assertEquals("10", producto.getId());
        assertEquals(10L, producto.getIdLong());

        producto.setIdLong(25L);
        assertEquals("25", producto.getId());
        assertEquals(25L, producto.getIdLong());
    }
}
