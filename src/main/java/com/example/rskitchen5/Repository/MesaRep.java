package com.example.rskitchen5.Repository;

import com.example.rskitchen5.Model.Mesa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MesaRep extends JpaRepository<Mesa, Long> {

    List<Mesa> findByOcupadoFalse();

    Optional<Mesa> findByNum(int num);

    List<Mesa> findByRestaurantId(Long restaurantId);

    List<Mesa> findByRestaurantIdAndOcupadoFalse(Long restaurantId);

    Optional<Mesa> findByRestaurantIdAndNum(Long restaurantId, int num);

    Optional<Mesa> findByIdAndRestaurantId(Long id, Long restaurantId);

    default Optional<Mesa> findById(String id) {
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
