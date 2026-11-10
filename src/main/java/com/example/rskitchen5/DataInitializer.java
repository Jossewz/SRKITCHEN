package com.example.rskitchen5;

import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.UserRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRep userRep;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Value("${creator.email:creator@rskitchen.com}")
    private String creatorEmail;

    @Value("${creator.password:creator123}")
    private String creatorPassword;

    @Override
    public void run(String... args) throws Exception {
        // Inicializar usuario maestro con rol CREATOR si no existe
        if (userRep.findByMail(creatorEmail).isEmpty()) {
            User creator = new User();
            creator.setName("Super Admin Creador");
            creator.setMail(creatorEmail);
            creator.setPassword(passwordEncoder.encode(creatorPassword));
            creator.setRol("ROLE_CREATOR");
            creator.setRestaurantId(null);
            userRep.save(creator);
            System.out.println("✅ Usuario Maestro CREATOR creado: " + creatorEmail);
        } else {
            System.out.println("ℹ️ Usuario Maestro CREATOR ya existe: " + creatorEmail);
        }
    }
}
