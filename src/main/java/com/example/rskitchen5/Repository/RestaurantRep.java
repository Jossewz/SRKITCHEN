package com.example.rskitchen5.Repository;

import com.example.rskitchen5.Model.Restaurant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RestaurantRep extends JpaRepository<Restaurant, Long> {
    Optional<Restaurant> findByCorreo(String correo);
}
