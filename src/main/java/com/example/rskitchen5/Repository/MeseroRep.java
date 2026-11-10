package com.example.rskitchen5.Repository;

import com.example.rskitchen5.Model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MeseroRep extends JpaRepository<User, Long> {
    Optional<User> findByMail(String mail);

    default Optional<User> findById(String id) {
        if (id == null || id.trim().isEmpty()) return Optional.empty();
        try {
            return findById(Long.parseLong(id));
        } catch (NumberFormatException e) {
            return Optional.empty();
        }
    }
}
