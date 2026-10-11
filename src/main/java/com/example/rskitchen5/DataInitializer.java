package com.example.rskitchen5;

import com.example.rskitchen5.Model.Mesa;
import com.example.rskitchen5.Model.Platillo;
import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.MesaRep;
import com.example.rskitchen5.Repository.PlatilloRep;
import com.example.rskitchen5.Repository.UserRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.ArrayList;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRep userRep;

    @Autowired
    private MesaRep mesaRep;

    @Autowired
    private PlatilloRep platilloRep;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // Inicializar usuario administrador
        if (userRep.findByMail("admin@rskitchen.com").isEmpty()) {
            User admin = new User();
            admin.setName("Administrador");
            admin.setMail("admin@rskitchen.com");
            admin.setPassword(passwordEncoder.encode("admin123"));
            admin.setRol("ROLE_ADMIN");
            userRep.save(admin);
            System.out.println("✅ Usuario Admin creado: admin@rskitchen.com / admin123");
        }

        // Inicializar usuario mesero
        if (userRep.findByMail("mesero@rskitchen.com").isEmpty()) {
            User mesero = new User();
            mesero.setName("Carlos Mesero");
            mesero.setMail("mesero@rskitchen.com");
            mesero.setPassword(passwordEncoder.encode("mesero123"));
            mesero.setRol("ROLE_MESERO");
            mesero.setId_mesero("MES001");
            userRep.save(mesero);
            System.out.println("✅ Usuario Mesero creado: mesero@rskitchen.com / mesero123");
        }

        // Inicializar mesas iniciales si no existen
        if (mesaRep.count() == 0) {
            for (int i = 1; i <= 6; i++) {
                Mesa mesa = new Mesa();
                mesa.setNum(i);
                mesa.setOcupado(false);
                mesa.setPedidosId(new ArrayList<>());
                mesaRep.save(mesa);
            }
            System.out.println("✅ Mesas 1 a 6 inicializadas correctamente.");
        }

        // Inicializar menú inicial si está vacío
        if (platilloRep.count() == 0) {
            platilloRep.save(new Platillo("Plato Fuerte", "", null, "Hamburguesa Clásica", 25000.0));
            platilloRep.save(new Platillo("Plato Fuerte", "", null, "Pizza Margarita Artesanal", 32000.0));
            platilloRep.save(new Platillo("Plato Fuerte", "", null, "Costillas BBQ", 42000.0));
            platilloRep.save(new Platillo("Plato Sencillo", "", null, "Papas a la Francesa", 12000.0));
            platilloRep.save(new Platillo("Plato Sencillo", "", null, "Ensalada César", 18000.0));
            platilloRep.save(new Platillo("Bebida", "", null, "Limonada Natural", 8000.0));
            platilloRep.save(new Platillo("Bebida", "", null, "Cerveza Artesanal", 14000.0));
            System.out.println("✅ Platillos del menú inicializados correctamente.");
        }
    }
}
