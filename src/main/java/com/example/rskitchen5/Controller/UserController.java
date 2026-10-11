package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.UserRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/usuarios")
@PreAuthorize("hasRole('ADMIN')")
public class UserController {

    @Autowired
    private UserRep userRep;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @GetMapping
    public List<User> getAllUsers() {
        return userRep.findAll();
    }

    @PostMapping
    public User crearUser(@RequestBody User user) {
        if (user.getPassword() != null && !user.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        if (user.getRol() == null || user.getRol().isEmpty()) {
            user.setRol("ROLE_MESERO");
        } else if (!user.getRol().startsWith("ROLE_")) {
            user.setRol("ROLE_" + user.getRol().toUpperCase());
        }
        return userRep.save(user);
    }

    @PutMapping("/{id}")
    public User updateUsuario(@PathVariable String id, @RequestBody User user) {
        User existingUser = userRep.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Usuario no encontrado"));
        existingUser.setName(user.getName());
        existingUser.setMail(user.getMail());
        if (user.getRol() != null && !user.getRol().isEmpty()) {
            existingUser.setRol(user.getRol().startsWith("ROLE_") ? user.getRol() : "ROLE_" + user.getRol().toUpperCase());
        }
        if (user.getPassword() != null && !user.getPassword().isEmpty()) {
            existingUser.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        return userRep.save(existingUser);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable String id) {
        if (!userRep.existsById(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Usuario no encontrado.");
        }
        userRep.deleteById(id);
        return ResponseEntity.ok("Usuario eliminado correctamente.");
    }
}
