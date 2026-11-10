package com.example.rskitchen5.controller;

import com.example.rskitchen5.Model.Restaurant;
import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.RestaurantRep;
import com.example.rskitchen5.Repository.UserRep;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private RestaurantRep restaurantRep;

    @Autowired
    private UserRep userRep;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Test
    @DisplayName("Mesero con restaurante activo puede iniciar sesión en /api/auth/login")
    void testMeseroLoginRestauranteActivo() throws Exception {
        Restaurant restaurant = new Restaurant();
        restaurant.setNombre("Restaurante Login Activo");
        restaurant.setCorreo("rest_login_activo@test.com");
        restaurant.setContraseña(passwordEncoder.encode("clave123"));
        restaurant.setActivo(true);
        restaurant = restaurantRep.save(restaurant);

        User mesero = new User();
        mesero.setName("Mesero Activo");
        mesero.setMail("mesero_login_activo@test.com");
        mesero.setPassword(passwordEncoder.encode("clave123"));
        mesero.setRol("ROLE_MESERO");
        mesero.setRestaurantId(restaurant.getId());
        mesero.setActivo(true);
        userRep.save(mesero);

        String json = """
            {
                "mail": "mesero_login_activo@test.com",
                "password": "clave123"
            }
            """;

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.email").value("mesero_login_activo@test.com"))
                .andExpect(jsonPath("$.restaurant_id").value(restaurant.getId()));
    }

    @Test
    @DisplayName("Mesero con restaurante desactivado NO puede iniciar sesión (403 Forbidden)")
    void testMeseroLoginRestauranteDesactivado() throws Exception {
        Restaurant restaurant = new Restaurant();
        restaurant.setNombre("Restaurante Login Inactivo");
        restaurant.setCorreo("rest_login_inactivo@test.com");
        restaurant.setContraseña(passwordEncoder.encode("clave123"));
        restaurant.setActivo(false); // DESACTIVADO
        restaurant = restaurantRep.save(restaurant);

        User mesero = new User();
        mesero.setName("Mesero Inactivo");
        mesero.setMail("mesero_login_inactivo@test.com");
        mesero.setPassword(passwordEncoder.encode("clave123"));
        mesero.setRol("ROLE_MESERO");
        mesero.setRestaurantId(restaurant.getId());
        mesero.setActivo(true);
        userRep.save(mesero);

        String json = """
            {
                "mail": "mesero_login_inactivo@test.com",
                "password": "clave123"
            }
            """;

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error", containsString("desactivado")));
    }
}

