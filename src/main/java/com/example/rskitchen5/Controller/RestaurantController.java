package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Restaurant;
import com.example.rskitchen5.Repository.RestaurantRep;
import com.example.rskitchen5.Repository.UserRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/restaurantes")
@PreAuthorize("hasRole('CREATOR')")
public class RestaurantController {

    @Autowired
    private RestaurantRep restaurantRep;

    @Autowired
    private UserRep userRep;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @GetMapping
    public List<Restaurant> listarRestaurantes() {
        return restaurantRep.findAll();
    }

    @GetMapping("/{id}")
    public Restaurant obtenerPorId(@PathVariable Long id) {
        return restaurantRep.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Restaurante no encontrado"));
    }

    @PostMapping
    public ResponseEntity<?> crearRestaurante(@RequestBody Restaurant restaurant) {
        String password = restaurant.getContraseña() != null && !restaurant.getContraseña().trim().isEmpty()
                ? restaurant.getContraseña()
                : restaurant.getPassword();

        if (restaurant.getCorreo() == null || restaurant.getCorreo().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "El correo es obligatorio"));
        }
        if (password == null || password.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "La contraseña es obligatoria"));
        }
        if (restaurant.getNombre() == null || restaurant.getNombre().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "El nombre es obligatorio"));
        }

        // Verificar unicidad de correo
        if (restaurantRep.findByCorreo(restaurant.getCorreo()).isPresent() || userRep.findByMail(restaurant.getCorreo()).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "El correo ya está registrado en el sistema"));
        }

        restaurant.setContraseña(passwordEncoder.encode(password));
        Restaurant guardado = restaurantRep.save(restaurant);
        return ResponseEntity.status(HttpStatus.CREATED).body(guardado);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> eliminarRestaurante(@PathVariable Long id) {
        if (!restaurantRep.existsById(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Restaurante no encontrado"));
        }
        restaurantRep.deleteById(id);
        return ResponseEntity.ok(Map.of("mensaje", "Restaurante eliminado correctamente"));
    }
}
