package com.example.rskitchen5.service;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Service.FacturaServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FacturaServiceImplTest {

    @Mock
    private FacturaRep facturaRep;

    @InjectMocks
    private FacturaServiceImpl facturaService;

    private Factura factura1;
    private Factura factura2;

    @BeforeEach
    void setUp() {
        factura1 = new Factura();
        factura1.setId("1");
        factura1.setMesaNum("1");
        factura1.setTotal(55000.0);
        factura1.setFecha(LocalDateTime.now());

        factura2 = new Factura();
        factura2.setId("2");
        factura2.setMesaNum("2");
        factura2.setTotal(32000.0);
        factura2.setFecha(LocalDateTime.now());
    }

    @Test
    @DisplayName("Debe retornar la lista completa de facturas")
    void testGetAllFacturas() {
        when(facturaRep.findAll()).thenReturn(Arrays.asList(factura1, factura2));

        List<Factura> facturas = facturaService.getAll();

        assertNotNull(facturas);
        assertEquals(2, facturas.size());
        assertEquals(55000.0, facturas.get(0).getTotal());
        verify(facturaRep, times(1)).findAll();
    }

    @Test
    @DisplayName("Debe retornar una factura por ID cuando existe")
    void testGetById_Found() {
        when(facturaRep.findById("1")).thenReturn(Optional.of(factura1));

        Factura encontrada = facturaService.getById("1");

        assertNotNull(encontrada);
        assertEquals("1", encontrada.getId());
        assertEquals("1", encontrada.getMesaNum());
        verify(facturaRep, times(1)).findById("1");
    }

    @Test
    @DisplayName("Debe retornar null cuando la factura no existe")
    void testGetById_NotFound() {
        when(facturaRep.findById("999")).thenReturn(Optional.empty());

        Factura encontrada = facturaService.getById("999");

        assertNull(encontrada);
        verify(facturaRep, times(1)).findById("999");
    }
}
