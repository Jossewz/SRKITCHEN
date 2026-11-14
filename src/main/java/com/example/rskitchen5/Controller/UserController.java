package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.RestaurantRep;
import com.example.rskitchen5.Repository.UserRep;
import com.example.rskitchen5.Security.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping({"/usuarios", "/api/usuarios"})
@PreAuthorize("hasRole('ADMIN')")
public class UserController {

    @Autowired
    private UserRep userRep;

    @Autowired
    private RestaurantRep restaurantRep;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @GetMapping
    public List<User> getAllUsers() {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No se identificó el restaurante en la sesión");
        }
        return userRep.findByRestaurantId(restaurantId);
    }

    @PostMapping
    public ResponseEntity<?> crearUser(@RequestBody User user) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No se identificó el restaurante en el token JWT"));
        }

        if (user.getMail() == null || user.getMail().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "El correo es obligatorio"));
        }

        if (userRep.findByMail(user.getMail()).isPresent() || restaurantRep.findByCorreo(user.getMail()).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "El correo ya está registrado"));
        }

        if (user.getPassword() != null && !user.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        } else {
            return ResponseEntity.badRequest().body(Map.of("error", "La contraseña es obligatoria"));
        }

        // Asignación automática del tenant extraído del token JWT
        user.setRestaurantId(restaurantId);

        if (user.getRol() == null || user.getRol().isEmpty()) {
            user.setRol("ROLE_MESERO");
        } else if (!user.getRol().toUpperCase().startsWith("ROLE_")) {
            user.setRol("ROLE_" + user.getRol().toUpperCase());
        } else {
            user.setRol(user.getRol().toUpperCase());
        }

        User guardado = userRep.save(user);
        return ResponseEntity.status(HttpStatus.CREATED).body(guardado);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateUsuario(@PathVariable Long id, @RequestBody User user) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Sesión inválida"));
        }

        User existingUser = userRep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Usuario no encontrado en este restaurante"));

        existingUser.setName(user.getName());
        existingUser.setMail(user.getMail());
        if (user.getRol() != null && !user.getRol().isEmpty()) {
            String rol = user.getRol().toUpperCase();
            existingUser.setRol(rol.startsWith("ROLE_") ? rol : "ROLE_" + rol);
        }
        if (user.getPassword() != null && !user.getPassword().isEmpty()) {
            existingUser.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        return ResponseEntity.ok(userRep.save(existingUser));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable Long id) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Sesión inválida"));
        }

        User existingUser = userRep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Usuario no encontrado en este restaurante"));

        userRep.delete(existingUser);
        return ResponseEntity.ok(Map.of("mensaje", "Usuario eliminado correctamente"));
    }
}
