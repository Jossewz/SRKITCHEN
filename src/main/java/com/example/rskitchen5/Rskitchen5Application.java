package com.example.rskitchen5;
import com.example.rskitchen5.Model.User;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.example.rskitchen5.Repository.*;
import com.example.rskitchen5.Service.AiAnalysisService;
@SpringBootApplication
@EnableMethodSecurity
public class Rskitchen5Application {

	public static void main(String[] args) {
		SpringApplication.run(Rskitchen5Application.class, args);
	}

    @Bean
    CommandLineRunner init(UserRep userRepository, PasswordEncoder passwordEncoder, AiAnalysisService aiAnalysisService) {
        return args -> {

            System.out.println("🔥 RUNNER EJECUTÁNDOSE");

            // Comentado para evitar errores de duplicado: IncorrectResultSizeDataAccessException
            // User user = new User();
            // user.setName("Prueba Mesero");
            // user.setMail("prueba123@rskitchen.com");
            // user.setPassword(passwordEncoder.encode("123456"));
            // user.setRol("MESERO");
            // userRepository.save(user);

            // System.out.println("🔥 USUARIO GUARDADO");
            
            // Probar el asistente de IA al arrancar
            System.out.println("\n==============================================");
            System.out.println("🤖 PROBANDO ANÁLISIS DE IA CON GROQ EN TERMINAL");
            System.out.println("==============================================");
            try {
                System.out.println("\n➡️ Consultando reporte de Platillos Populares...");
                String platillos = aiAnalysisService.analyzeTopDishes();
                System.out.println(platillos);
                
                System.out.println("\n➡️ Consultando reporte de Facturación...");
                String facturas = aiAnalysisService.analyzeInvoicesReport();
                System.out.println(facturas);
            } catch (Exception e) {
                System.err.println("❌ ERROR AL CONECTAR CON GROQ: " + e.getMessage());
            }
            System.out.println("==============================================\n");
        };
    }

}
