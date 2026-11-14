package com.example.rskitchen5.repository;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Model.Mesa;
import com.example.rskitchen5.Model.Producto;
import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Repository.MesaRep;
import com.example.rskitchen5.Repository.ProductoRep;
import com.example.rskitchen5.Repository.UserRep;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class RepositoryIntegrationTest {

    @Autowired
    private UserRep userRep;

    @Autowired
    private MesaRep mesaRep;

    @Autowired
    private ProductoRep productoRep;

    @Autowired
    private FacturaRep facturaRep;

    @Test
    @DisplayName("UserRep: Debe encontrar los usuarios predeterminados y filtrar meseros")
    void testUserRepQueries() {
        Optional<User> admin = userRep.findByMail("admin@rskitchen.com");
        assertTrue(admin.isPresent());
        assertEquals("ROLE_ADMIN", admin.get().getRol());

        Optional<User> mesero = userRep.findByMail("mesero@rskitchen.com");
        assertTrue(mesero.isPresent());
        assertEquals("ROLE_MESERO", mesero.get().getRol());

        List<User> meseros = userRep.findAllMeseros();
        assertFalse(meseros.isEmpty());
        assertTrue(meseros.stream().anyMatch(u -> "mesero@rskitchen.com".equals(u.getMail())));
    }

    @Test
    @DisplayName("UserRep: Creación, consulta y eliminación segura con ID tipo String")
    void testUserRepCrudAndStringId() {
        User nuevo = new User();
        nuevo.setName("Tester Temporal");
        nuevo.setMail("temp_test@rskitchen.com");
        nuevo.setPassword("pass123");
        nuevo.setRol("ROLE_MESERO");
        User guardado = userRep.save(nuevo);

        assertNotNull(guardado.getId());
        String strId = String.valueOf(guardado.getId());

        assertTrue(userRep.existsById(strId));
        Optional<User> recuperado = userRep.findById(strId);
        assertTrue(recuperado.isPresent());
        assertEquals("Tester Temporal", recuperado.get().getName());

        userRep.deleteById(strId);
        assertFalse(userRep.existsById(strId));
    }

    @Test
    @DisplayName("MesaRep: Consultas de mesas libres, búsqueda por número y conversión segura de ID")
    void testMesaRepQueries() {
        List<Mesa> libres = mesaRep.findByOcupadoFalse();
        assertFalse(libres.isEmpty(), "Deben existir mesas libres inicializadas");

        Optional<Mesa> mesa1 = mesaRep.findByNum(1);
        assertTrue(mesa1.isPresent());
        assertEquals(1, mesa1.get().getNum());

        String mesa1Id = mesa1.get().getId();
        Optional<Mesa> mesaPorStringId = mesaRep.findById(mesa1Id);
        assertTrue(mesaPorStringId.isPresent());
        assertEquals(1, mesaPorStringId.get().getNum());

        // ID no numérico debe retornar Optional.empty() sin lanzar excepción
        Optional<Mesa> invalida = mesaRep.findById("abc_invalido");
        assertTrue(invalida.isEmpty());
    }

    @Test
    @DisplayName("ProductoRep: Guardar producto, buscar por nombre y consultar por ID seguro")
    void testProductoRepCrud() {
        Producto prod = new Producto();
        prod.setName("Tomates Chonto Test");
        prod.setStock(25);
        Producto guardado = productoRep.save(prod);

        assertNotNull(guardado.getId());
        Optional<Producto> porNombre = productoRep.findByName("Tomates Chonto Test");
        assertTrue(porNombre.isPresent());
        assertEquals(25, porNombre.get().getStock());

        Optional<Producto> porId = productoRep.findById(guardado.getId());
        assertTrue(porId.isPresent());
    }

    @Test
    @DisplayName("FacturaRep: Guardar y consultar factura por ID numérico y String")
    void testFacturaRepCrud() {
        Factura f = new Factura();
        f.setMesaNum("3");
        f.setTotal(85000.0);
        f.setFecha(LocalDateTime.now());
        Factura guardada = facturaRep.save(f);

        assertNotNull(guardada.getId());
        Optional<Factura> encontrada = facturaRep.findById(guardada.getId());
        assertTrue(encontrada.isPresent());
        assertEquals(85000.0, encontrada.get().getTotal());
    }
}
