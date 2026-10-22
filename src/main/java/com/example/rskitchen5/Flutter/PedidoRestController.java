package com.example.rskitchen5.Flutter;

import com.example.rskitchen5.Model.ItemPedido;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Repository.PedidoRep;
import com.example.rskitchen5.Security.TenantContext;
import com.example.rskitchen5.Security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/pedidos")
public class PedidoRestController {

    @Autowired
    private PedidoRep pedidoRep;

    @GetMapping
    public List<Pedido> listarPedidos() {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No se identificó el restaurante en la sesión");
        }
        return pedidoRep.findByRestaurantIdOrderByFechaDesc(restaurantId);
    }

    @GetMapping("/{id}")
    public Pedido obtenerPedido(@PathVariable Long id) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Sesión inválida");
        }
        return pedidoRep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pedido no encontrado en este restaurante"));
    }

    @PostMapping
    public ResponseEntity<?> crearPedido(@RequestBody Pedido pedido) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No se identificó el restaurante en el token JWT"));
        }

        // Asignación automática del tenant
        pedido.setRestaurantId(restaurantId);

        UserPrincipal user = TenantContext.getCurrentUser();
        if (user != null) {
            if (pedido.getMeseroName() == null || pedido.getMeseroName().isEmpty()) {
                pedido.setMeseroName(user.getNombre());
            }
        }

        if (pedido.getFecha() == null) {
            pedido.setFecha(LocalDateTime.now());
        }

        // Vincular items con el pedido
        if (pedido.getItems() != null) {
            double totalCalculado = 0.0;
            for (ItemPedido item : pedido.getItems()) {
                item.setPedido(pedido);
                int cantidad = item.getUnidades() != null && item.getUnidades() > 0 ? item.getUnidades() : 1;
                if (item.getCant() != null) {
                    try {
                        cantidad = Integer.parseInt(item.getCant().trim());
                    } catch (NumberFormatException ignored) {}
                }
                totalCalculado += (item.getPrice() * cantidad);
            }
            if (pedido.getTotal() == 0.0) {
                pedido.setTotal(totalCalculado);
            }
        }

        Pedido guardado = pedidoRep.save(pedido);
        return ResponseEntity.status(HttpStatus.CREATED).body(guardado);
    }

    @PutMapping("/{id}/pagar")
    public ResponseEntity<?> marcarPagado(@PathVariable Long id) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Sesión inválida"));
        }

        Pedido pedido = pedidoRep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pedido no encontrado en este restaurante"));

        pedido.setPagado(true);
        pedidoRep.save(pedido);
        return ResponseEntity.ok(Map.of("mensaje", "Pedido marcado como pagado exitosamente"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> eliminarPedido(@PathVariable Long id) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        if (restaurantId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Sesión inválida"));
        }

        Pedido pedido = pedidoRep.findByIdAndRestaurantId(id, restaurantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pedido no encontrado en este restaurante"));

        pedidoRep.delete(pedido);
        return ResponseEntity.ok(Map.of("mensaje", "Pedido eliminado correctamente"));
    }
}
