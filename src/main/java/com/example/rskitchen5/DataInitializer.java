package com.example.rskitchen5;

import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.UserRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRep userRep;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // Inicializar usuario administrador
        if (userRep.findByMail("admin@rskitchen.com").isEmpty()) {
            User admin = new User();
            admin.setName("Admin User");
            admin.setMail("admin@rskitchen.com");
            admin.setPassword(passwordEncoder.encode("admin123"));
            admin.setRol("ROLE_ADMIN");
            
            userRep.save(admin);
            System.out.println("Usuario Admin creado correctamente.");
        }

        // Inicializar usuario normal / mesero
        if (userRep.findByMail("user@rskitchen.com").isEmpty()) {
            User user = new User();
            user.setName("Normal User");
            user.setMail("user@rskitchen.com");
            user.setPassword(passwordEncoder.encode("user123"));
            user.setRol("ROLE_MESERO"); // Utilizo ROLE_MESERO ya que lo veo autorizado en tus rutas de Spring Security
            
            userRep.save(user);
            System.out.println("Usuario User (Mesero) creado correctamente.");
        }
    }
}
