package com.example.rskitchen5.Repository;

import com.example.rskitchen5.Model.Foro;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ForoRep extends JpaRepository<Foro, Long> {

    default Optional<Foro> findById(String id) {
        if (id == null || id.trim().isEmpty()) return Optional.empty();
        try {
            return findById(Long.parseLong(id));
        } catch (NumberFormatException e) {
            return Optional.empty();
        }
    }
}
