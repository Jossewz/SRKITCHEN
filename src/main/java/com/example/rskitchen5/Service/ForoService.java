package com.example.rskitchen5.Service;

import com.example.rskitchen5.Model.Foro;
import com.example.rskitchen5.Repository.ForoRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ForoService {

    private final ForoRep foroRep;

    @Autowired
    public ForoService(ForoRep foroRep) {
        this.foroRep = foroRep;
    }

    public List<Foro> obtenerTodosLosForos() {
        return foroRep.findAll();
    }

    public Foro crearComentario(String fnombre, String fcomentario) {
        Foro foro = new Foro(fnombre, fcomentario, LocalDateTime.now());
        return foroRep.save(foro);
    }
}

