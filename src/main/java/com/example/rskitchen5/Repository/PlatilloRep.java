package com.example.rskitchen5.Repository;

import com.example.rskitchen5.Model.Platillo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PlatilloRep extends JpaRepository<Platillo, Long> {

    Optional<Platillo> findByName(String name);

    default Optional<Platillo> findById(String id) {
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
