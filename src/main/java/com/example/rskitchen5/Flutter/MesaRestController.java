package com.example.rskitchen5.Flutter;

import com.example.rskitchen5.Model.Mesa;
import com.example.rskitchen5.Repository.MesaRep;
import com.example.rskitchen5.Security.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/mesas")
public class MesaRestController {

    @Autowired
    private MesaRep mesaRep;

    @GetMapping
    public List<Mesa> listarMesas() {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No se identificó el restaurante en la sesión");
        }
        return mesaRep.findByRestaurantId(restaurantId);
    }

    @GetMapping("/{id}")
    public Mesa obtenerMesa(@PathVariable Long id) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Sesión inválida");
        }
        return mesaRep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Mesa no encontrada en este restaurante"));
    }

    @PostMapping
    public ResponseEntity<?> crearMesa(@RequestBody Mesa mesa) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No se identificó el restaurante en el token JWT"));
        }

        // Asignación automática del tenant extraído del JWT
        mesa.setRestaurantId(restaurantId);
        if (mesa.getPedidosId() == null) {
            mesa.setPedidosId(new ArrayList<>());
        }

        Mesa guardada = mesaRep.save(mesa);
        return ResponseEntity.status(HttpStatus.CREATED).body(guardada);
    }

    @PutMapping("/{id}")
    public Mesa actualizarMesa(@PathVariable Long id, @RequestBody Mesa mesa) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Sesión inválida");
        }

        Mesa existing = mesaRep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Mesa no encontrada en este restaurante"));

        existing.setNum(mesa.getNum());
        existing.setOcupado(mesa.isOcupado());
        existing.setMeseroId(mesa.getMeseroId());
        if (mesa.getPedidosId() != null) {
            existing.setPedidosId(mesa.getPedidosId());
        }

        return mesaRep.save(existing);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> eliminarMesa(@PathVariable Long id) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Sesión inválida"));
        }

        Mesa existing = mesaRep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Mesa no encontrada en este restaurante"));

        mesaRep.delete(existing);
        return ResponseEntity.ok(Map.of("mensaje", "Mesa eliminada correctamente"));
    }
}
