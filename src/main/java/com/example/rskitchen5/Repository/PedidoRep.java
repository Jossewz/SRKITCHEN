package com.example.rskitchen5.Repository;

import com.example.rskitchen5.Model.Pedido;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PedidoRep extends JpaRepository<Pedido, Long> {

    List<Pedido> findTop5ByOrderByFechaDesc();

    List<Pedido> findTop5ByRestaurantIdOrderByFechaDesc(Long restaurantId);

    List<Pedido> findByMesaId(String mesaId);

    List<Pedido> findByRestaurantId(Long restaurantId);

    List<Pedido> findByRestaurantIdAndMesaId(Long restaurantId, String mesaId);

    List<Pedido> findByRestaurantIdOrderByFechaDesc(Long restaurantId);

    Optional<Pedido> findByIdAndRestaurantId(Long id, Long restaurantId);

    default Optional<Pedido> findById(String id) {
        if (id == null || id.trim().isEmpty()) return Optional.empty();
        try {
            return findById(Long.parseLong(id));
        } catch (NumberFormatException e) {
            return Optional.empty();
        }
    }

    default boolean existsById(String id) {
        if (id == null || id.trim().isEmpty()) return false;
        try {
            return existsById(Long.parseLong(id));
        } catch (NumberFormatException e) {
            return false;
        }
    }

    default void deleteById(String id) {
        if (id != null && !id.trim().isEmpty()) {
            try {
                deleteById(Long.parseLong(id));
            } catch (NumberFormatException ignored) {}
        }
    }
}
