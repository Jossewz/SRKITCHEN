package com.example.rskitchen5.Repository;

import com.example.rskitchen5.Model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRep extends JpaRepository<User, Long> {
    Optional<User> findByMail(String mail);

    default Optional<User> findById(String id) {
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

    @Query("SELECT u FROM User u WHERE UPPER(u.rol) = 'MESERO' OR UPPER(u.rol) = 'ROLE_MESERO'")
    List<User> findAllMeseros();
}
