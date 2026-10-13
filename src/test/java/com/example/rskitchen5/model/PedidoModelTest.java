package com.example.rskitchen5.model;

import com.example.rskitchen5.Model.ItemPedido;
import com.example.rskitchen5.Model.Pedido;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Pruebas Unitarias - Modelo Pedido e ItemPedido")
class PedidoModelTest {

    @Test
    @DisplayName("Debe inicializar fecha por defecto y lista de items vacía")
    void testConstructorPorDefecto() {
        Pedido pedido = new Pedido();
        assertNotNull(pedido.getFecha());
        assertNotNull(pedido.getItems());
        assertTrue(pedido.getItems().isEmpty());
        assertFalse(pedido.isPagado());
        assertEquals(0.0, pedido.getTotal());
    }

    @Test
    @DisplayName("Debe asociar items y vincular referencia bidireccional correctamente")
    void testAsociacionItems() {
        Pedido pedido = new Pedido();
        pedido.setMesaNum(4);
        pedido.setMeseroName("Carlos Mesero");
        pedido.setTotal(45.50);

        ItemPedido item1 = new ItemPedido();
        item1.setProductId("item-1");
        item1.setName("Lomo Saltado");
        item1.setUnidades(2);
        item1.setPrice(18.00);

        ItemPedido item2 = new ItemPedido();
        item2.setProductId("item-2");
        item2.setName("Chicha Morada");
        item2.setUnidades(1);
        item2.setPrice(9.50);

        List<ItemPedido> items = new ArrayList<>();
        items.add(item1);
        items.add(item2);

        pedido.setItems(items);

        assertEquals(2, pedido.getItems().size());
        assertEquals(pedido, item1.getPedido());
        assertEquals(pedido, item2.getPedido());
        assertEquals(4, pedido.getMesaNum());
        assertEquals("Carlos Mesero", pedido.getMeseroName());
        assertEquals(45.50, pedido.getTotal());
    }

    @Test
    @DisplayName("Debe cambiar estado de pago a pagado correctamente")
    void testEstadoPagado() {
        Pedido pedido = new Pedido();
        assertFalse(pedido.isPagado());

        pedido.setPagado(true);
        assertTrue(pedido.isPagado());
    }
}
