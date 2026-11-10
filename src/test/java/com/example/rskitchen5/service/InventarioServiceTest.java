package com.example.rskitchen5.service;

import com.example.rskitchen5.Model.*;
import com.example.rskitchen5.Repository.PlatilloIngredienteRep;
import com.example.rskitchen5.Repository.PlatilloRep;
import com.example.rskitchen5.Repository.ProductoRep;
import com.example.rskitchen5.Service.InventarioService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("Pruebas Unitarias - InventarioService (Deducción de Stock al pagar)")
class InventarioServiceTest {

    @Mock
    private ProductoRep productoRep;

    @Mock
    private PlatilloRep platilloRep;

    @Mock
    private PlatilloIngredienteRep platilloIngredienteRep;

    @InjectMocks
    private InventarioService inventarioService;

    private Producto productoCarne;
    private Producto productoPan;
    private Platillo platilloHamburguesa;

    @BeforeEach
    void setUp() {
        productoCarne = new Producto("unidades", 101L, "Carne Hamburguesa", 5.0, 20);
        productoPan = new Producto("unidades", 102L, "Pan Brioche", 2.0, 15);

        platilloHamburguesa = new Platillo();
        platilloHamburguesa.setId("1");
        platilloHamburguesa.setIdLong(1L);
        platilloHamburguesa.setName("Hamburguesa Especial");
        platilloHamburguesa.setPrice(12.0);

        PlatilloIngrediente ingCarne = new PlatilloIngrediente(platilloHamburguesa, productoCarne, 2.0); // 2 carnes por hamburguesa
        PlatilloIngrediente ingPan = new PlatilloIngrediente(platilloHamburguesa, productoPan, 1.0);     // 1 pan por hamburguesa

        platilloHamburguesa.addIngrediente(ingCarne);
        platilloHamburguesa.addIngrediente(ingPan);
    }

    @Test
    @DisplayName("Debe descontar stock de productos correctamente al procesar pedido pagado")
    void testDescontarStockPorPedido() {
        Pedido pedido = new Pedido();
        pedido.setId("500");

        ItemPedido item = new ItemPedido();
        item.setProductId("1"); // Platillo ID 1
        item.setName("Hamburguesa Especial");
        item.setUnidades(3);   // 3 hamburguesas pedidas

        List<ItemPedido> items = new ArrayList<>();
        items.add(item);
        pedido.setItems(items);

        when(platilloRep.findById("1")).thenReturn(Optional.of(platilloHamburguesa));
        when(productoRep.findById(101L)).thenReturn(Optional.of(productoCarne));
        when(productoRep.findById(102L)).thenReturn(Optional.of(productoPan));

        // Ejecutar descuento
        inventarioService.descontarStockPorPedido(pedido);

        // 3 hamburguesas * 2 carnes = 6 carnes -> 20 - 6 = 14
        assertEquals(14, productoCarne.getStock());
        // 3 hamburguesas * 1 pan = 3 panes -> 15 - 3 = 12
        assertEquals(12, productoPan.getStock());

        verify(productoRep, times(1)).save(productoCarne);
        verify(productoRep, times(1)).save(productoPan);
    }

    @Test
    @DisplayName("Debe descontar stock de productos al procesar factura pagada")
    void testDescontarStockPorFactura() {
        Factura factura = new Factura();
        factura.setId("900");

        ItemPedido item = new ItemPedido();
        item.setProductId("1");
        item.setName("Hamburguesa Especial");
        item.setUnidades(2);

        factura.setItems(List.of(item));

        when(platilloRep.findById("1")).thenReturn(Optional.of(platilloHamburguesa));
        when(productoRep.findById(101L)).thenReturn(Optional.of(productoCarne));
        when(productoRep.findById(102L)).thenReturn(Optional.of(productoPan));

        inventarioService.descontarStockPorFactura(factura);

        // 2 hamburguesas * 2 carnes = 4 carnes -> 20 - 4 = 16
        assertEquals(16, productoCarne.getStock());
        // 2 hamburguesas * 1 pan = 2 panes -> 15 - 2 = 13
        assertEquals(13, productoPan.getStock());
    }

    @Test
    @DisplayName("No debe permitir stock negativo si el consumo supera el stock existente")
    void testStockNoNegativo() {
        productoCarne.setStock(2); // Solo quedan 2 carnes

        Pedido pedido = new Pedido();
        ItemPedido item = new ItemPedido();
        item.setProductId("1");
        item.setUnidades(5); // 5 hamburguesas * 2 carnes = 10 necesarias

        pedido.setItems(List.of(item));

        when(platilloRep.findById("1")).thenReturn(Optional.of(platilloHamburguesa));
        when(productoRep.findById(101L)).thenReturn(Optional.of(productoCarne));
        when(productoRep.findById(102L)).thenReturn(Optional.of(productoPan));

        inventarioService.descontarStockPorPedido(pedido);

        // Debería quedar en 0 y no en -8
        assertEquals(0, productoCarne.getStock());
    }
}

