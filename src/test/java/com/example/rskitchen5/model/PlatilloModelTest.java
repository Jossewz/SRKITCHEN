package com.example.rskitchen5.model;

import com.example.rskitchen5.Model.Platillo;
import com.example.rskitchen5.Model.PlatilloIngrediente;
import com.example.rskitchen5.Model.Producto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Pruebas Unitarias - Modelo Platillo y PlatilloIngrediente")
class PlatilloModelTest {

    @Test
    @DisplayName("Platillo sin ingredientes debe estar disponible por defecto")
    void testDisponibilidadSinIngredientes() {
        Platillo platillo = new Platillo();
        platillo.setName("Ceviche Clásico");
        platillo.setPrice(25.0);

        assertTrue(platillo.isDisponible());
        assertNotNull(platillo.getIngredientes());
        assertTrue(platillo.getIngredientes().isEmpty());
    }

    @Test
    @DisplayName("Platillo con ingredientes suficientes debe estar disponible")
    void testDisponibilidadConStockSuficiente() {
        Platillo platillo = new Platillo();
        platillo.setName("Hamburguesa Doble");
        platillo.setPrice(15.0);

        Producto pan = new Producto("unidades", 1L, "Pan Hamburguesa", 1.0, 10);
        Producto carne = new Producto("unidades", 2L, "Carne de Res", 5.0, 8);

        PlatilloIngrediente ing1 = new PlatilloIngrediente(platillo, pan, 1.0);
        PlatilloIngrediente ing2 = new PlatilloIngrediente(platillo, carne, 2.0);

        platillo.addIngrediente(ing1);
        platillo.addIngrediente(ing2);

        assertEquals(2, platillo.getIngredientes().size());
        assertTrue(platillo.isDisponible());
    }

    @Test
    @DisplayName("Platillo con algún ingrediente sin stock suficiente debe estar no disponible")
    void testDisponibilidadConStockInsuficiente() {
        Platillo platillo = new Platillo();
        platillo.setName("Lomo Saltado");
        platillo.setPrice(30.0);

        Producto carne = new Producto("kg", 1L, "Lomo de Res", 10.0, 0); // 0 en stock
        Producto cebolla = new Producto("unidades", 2L, "Cebolla Morada", 0.5, 5);

        platillo.addIngrediente(new PlatilloIngrediente(platillo, carne, 1.0));
        platillo.addIngrediente(new PlatilloIngrediente(platillo, cebolla, 1.0));

        assertFalse(platillo.isDisponible());
    }
}

