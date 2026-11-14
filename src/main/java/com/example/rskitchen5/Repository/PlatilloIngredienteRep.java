package com.example.rskitchen5.Repository;

import com.example.rskitchen5.Model.PlatilloIngrediente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PlatilloIngredienteRep extends JpaRepository<PlatilloIngrediente, Long> {
    List<PlatilloIngrediente> findByPlatilloId(Long platilloId);
    void deleteByPlatilloId(Long platilloId);
}

