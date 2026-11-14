package com.example.rskitchen5.model;

import com.example.rskitchen5.Model.User;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Pruebas Unitarias - Modelo User")
class UserModelTest {

    @Test
    @DisplayName("Debe gestionar usuario con rol ADMIN correctamente")
    void testUsuarioAdmin() {
        User user = new User(1L, "admin@rskitchen.com", "Administrador Principal", "hash123", "ROLE_ADMIN");

        assertEquals(1L, user.getId());
        assertEquals("admin@rskitchen.com", user.getMail());
        assertEquals("Administrador Principal", user.getName());
        assertEquals("hash123", user.getPassword());
        assertEquals("ROLE_ADMIN", user.getRol());
        assertEquals("1", user.getId_mesero());
    }

    @Test
    @DisplayName("Debe gestionar mesero con id_mesero explícito")
    void testUsuarioMeseroConIdMesero() {
        User user = new User();
        user.setId(2L);
        user.setName("Carlos Mesero");
        user.setMail("carlos@rskitchen.com");
        user.setRol("ROLE_MESERO");
        user.setId_mesero("M-101");

        assertEquals("M-101", user.getId_mesero());
        assertEquals("ROLE_MESERO", user.getRol());
        assertEquals("Carlos Mesero", user.getName());
    }
}
