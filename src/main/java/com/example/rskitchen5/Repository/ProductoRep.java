package com.example.rskitchen5.Repository;

import com.example.rskitchen5.Model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductoRep extends JpaRepository<Producto, Long> {

    Optional<Producto> findByName(String name);

    List<Producto> findByRestaurantId(Long restaurantId);

    List<Producto> findByRestaurantIdAndActivo(Long restaurantId, boolean activo);

    Optional<Producto> findByIdAndRestaurantId(Long id, Long restaurantId);

    default Optional<Producto> findByIdAndRestaurantId(String id, Long restaurantId) {
        if (id == null || id.trim().isEmpty() || restaurantId == null) return Optional.empty();
        try {
            return findByIdAndRestaurantId(Long.parseLong(id), restaurantId);
        } catch (NumberFormatException e) {
            return Optional.empty();
        }
    }

    default Optional<Producto> findById(String id) {
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
