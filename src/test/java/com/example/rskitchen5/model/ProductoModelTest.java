package com.example.rskitchen5.model;

import com.example.rskitchen5.Model.Producto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

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

    @Test
    @DisplayName("Debe gestionar descripción y alias en español e inglés")
    void testDescripcionHandling() {
        Producto producto = new Producto();
        producto.setDescripcion("Aceite de oliva virgen extra 500ml");

        assertEquals("Aceite de oliva virgen extra 500ml", producto.getDescripcion());
        assertEquals("Aceite de oliva virgen extra 500ml", producto.getDescription());

        producto.setDescription("Tomates orgánicos seleccionados");
        assertEquals("Tomates orgánicos seleccionados", producto.getDescripcion());
        assertEquals("Tomates orgánicos seleccionados", producto.getDescription());
    }

    @Test
    @DisplayName("Debe gestionar unidad de medida (U.medida)")
    void testUMedidaHandling() {
        Producto producto = new Producto();
        producto.setUMedida("kg (kilogramo)");

        assertEquals("kg (kilogramo)", producto.getUMedida());
        assertEquals("kg (kilogramo)", producto.getUnidadMedida());
        assertEquals("kg (kilogramo)", producto.getCant());

        producto.setUnidadMedida("L (litro)");
        assertEquals("L (litro)", producto.getUMedida());
        assertEquals("L (litro)", producto.getUnidadMedida());
    }

    @Test
    @DisplayName("Debe gestionar estado activo, desactivar y activar")
    void testEstadoActivoDesactivarActivar() {
        Producto producto = new Producto();
        assertTrue(producto.isActivo(), "Un producto nuevo debe estar activo por defecto");
        assertTrue(producto.getActivo());

        producto.desactivar();
        assertFalse(producto.isActivo(), "Tras desactivar(), el producto debe estar inactivo");

        producto.activar();
        assertTrue(producto.isActivo(), "Tras activar(), el producto debe volver a estar activo");

        producto.setActivo(false);
        assertFalse(producto.isActivo());
    }

    @Test
    @DisplayName("Debe inicializar correctamente con constructores sobrecargados")
    void testConstructores() {
        Producto p1 = new Producto("1 kg", 1L, "Sal Marina", "Sal de grano puro", 4.50, 100);
        assertEquals("Sal Marina", p1.getName());
        assertEquals("Sal de grano puro", p1.getDescripcion());
        assertEquals("1 kg", p1.getUMedida());
        assertTrue(p1.isActivo());

        Producto p2 = new Producto(2L, "Pimienta Negra", "Pimienta molida", "250 g", "g (gramo)", 3.00, 50, false);
        assertEquals(2L, p2.getIdLong());
        assertEquals("Pimienta Negra", p2.getName());
        assertEquals("Pimienta molida", p2.getDescripcion());
        assertEquals("g (gramo)", p2.getUMedida());
        assertFalse(p2.isActivo());
    }
}
