package com.example.rskitchen5.model;

import com.example.rskitchen5.Model.Mesa;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Pruebas Unitarias - Modelo Mesa")
class MesaModelTest {

    @Test
    @DisplayName("Debe instanciar Mesa con valores por defecto y lista vacía de pedidos")
    void testConstructorVacio() {
        Mesa mesa = new Mesa();
        assertNull(mesa.getId());
        assertFalse(mesa.isOcupado());
        assertEquals(0, mesa.getNum());
        assertNotNull(mesa.getPedidosId());
        assertTrue(mesa.getPedidosId().isEmpty());
    }

    @Test
    @DisplayName("Debe asignar y recuperar propiedades correctamente")
    void testPropiedadesYSetters() {
        Mesa mesa = new Mesa();
        mesa.setId("5");
        mesa.setNum(12);
        mesa.setOcupado(true);
        mesa.setMeseroId("mesero-42");

        List<String> pedidos = new ArrayList<>();
        pedidos.add("ped-1");
        pedidos.add("ped-2");
        mesa.setPedidosId(pedidos);

        assertEquals("5", mesa.getId());
        assertEquals(5L, mesa.getIdLong());
        assertEquals(12, mesa.getNum());
        assertTrue(mesa.isOcupado());
        assertEquals("mesero-42", mesa.getMeseroId());
        assertEquals(2, mesa.getPedidosId().size());
        assertTrue(mesa.getPedidosId().contains("ped-1"));
    }

    @Test
    @DisplayName("Debe manejar conversión segura de ID numérico y no numérico")
    void testManejoIdSeguro() {
        Mesa mesa = new Mesa();
        mesa.setId("99");
        assertEquals("99", mesa.getId());
        assertEquals(99L, mesa.getIdLong());

        // Intentar setear un ID no parseable no debe romper el estado
        mesa.setId("invalido");
        assertEquals("99", mesa.getId());

        // Null o vacío no debe causar excepción
        mesa.setId(null);
        mesa.setId("   ");
        assertEquals("99", mesa.getId());
    }
}
