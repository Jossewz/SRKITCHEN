package com.example.rskitchen5;

import com.example.rskitchen5.Model.Mesero;
import com.example.rskitchen5.Repository.MeseroRep;
import com.example.rskitchen5.Repository.UserRep;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * Inicializador de datos predeterminados.
 *
 * Usa @EventListener(ApplicationReadyEvent) en lugar de CommandLineRunner
 * para garantizar que se ejecuta incluso si el InteractiveTerminalRunner
 * bloquea el hilo principal con su bucle while(true).
 *
 * Credenciales predeterminadas:
 * ─────────────────────────────────────────────────────
 *  ROL          │ CORREO                  │ CONTRASEÑA
 * ─────────────────────────────────────────────────────
 *  ROLE_ADMIN   │ admin@srkitchen.com     │ admin123
 *  ROLE_MESERO  │ mesero@srkitchen.com    │ mesero123
 * ─────────────────────────────────────────────────────
 */
@Configuration
public class DataInitializer implements InitializingBean {

    @Autowired
    private UserRep userRep;

    @Autowired
    private MeseroRep meseroRep;

    @Autowired
    private BCryptPasswordEncoder encoder;

    @Override
    public void afterPropertiesSet() throws Exception {

        System.out.println("=================================================");
        System.out.println("🚀 [DataInitializer] Verificando usuarios...");
        System.out.println("=================================================");

        // ── ADMINISTRADOR ──────────────────────────────────────────────
        String adminMail = "admin@srkitchen.com";
        if (userRep.findByMail(adminMail).isEmpty()) {
            Mesero admin = new Mesero();
            admin.setId_mesero("admin-001");
            admin.setName("Administrador SR Kitchen");
            admin.setMail(adminMail);
            admin.setPassword(encoder.encode("admin123"));
            admin.setRole("ROLE_ADMIN");
            meseroRep.save(admin);
            System.out.println("✅ ADMIN creado: " + adminMail + " / admin123");
        } else {
            System.out.println("ℹ️  ADMIN ya existe: " + adminMail);
        }

        // ── MESERO PREDETERMINADO ──────────────────────────────────────
        String meseroMail = "mesero@srkitchen.com";
        if (userRep.findByMail(meseroMail).isEmpty()) {
            Mesero mesero = new Mesero();
            mesero.setId_mesero("mesero-001");
            mesero.setName("Mesero Predeterminado");
            mesero.setMail(meseroMail);
            mesero.setPassword(encoder.encode("mesero123"));
            mesero.setRole("ROLE_MESERO");
            meseroRep.save(mesero);
            System.out.println("✅ MESERO creado: " + meseroMail + " / mesero123");
        } else {
            System.out.println("ℹ️  MESERO ya existe: " + meseroMail);
        }

        // ── DIAGNÓSTICO: mostrar todos los usuarios en BD ──────────────
        System.out.println("📋 Usuarios en colección 'usuarios':");
        userRep.findAll().forEach(u ->
            System.out.println("   → mail=" + u.getMail()
                + " | rol=" + u.getRol()
                + " | pass=" + (u.getPassword() != null
                    ? u.getPassword().substring(0, 12) + "..." : "NULL"))
        );
        System.out.println("=================================================");
    }
}
