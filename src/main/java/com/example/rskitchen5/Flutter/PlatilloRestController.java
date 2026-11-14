package com.example.rskitchen5.Flutter;

import com.example.rskitchen5.Model.Platillo;
import com.example.rskitchen5.Repository.PlatilloRep;
import com.example.rskitchen5.Security.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/platillos")
public class PlatilloRestController {

    @Autowired
    private PlatilloRep rep;

    @GetMapping
    public List<Platillo> getAll() {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No se identificó el restaurante en la sesión");
        }
        return rep.findByRestaurantId(restaurantId);
    }

    @PostMapping
    public Platillo create(@RequestBody Platillo p) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No se identificó el restaurante en el token JWT");
        }
        p.setRestaurantId(restaurantId);
        return rep.save(p);
    }

    @PutMapping("/{id}")
    public Platillo update(@PathVariable Long id, @RequestBody Platillo p) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Sesión inválida");
        }
        Platillo existing = rep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Platillo no encontrado en este restaurante"));

        existing.setName(p.getName());
        existing.setPrice(p.getPrice());
        existing.setCant(p.getCant());
        return rep.save(existing);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Sesión inválida");
        }
        Platillo existing = rep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Platillo no encontrado en este restaurante"));
        rep.delete(existing);
    }
}
