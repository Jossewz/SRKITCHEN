package com.example.rskitchen5;

import com.example.rskitchen5.Service.ChatbotService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.Scanner;

import org.springframework.context.annotation.Profile;

@Component
@Profile("cli")
public class InteractiveTerminalRunner implements CommandLineRunner {

    @Autowired
    private ChatbotService chatbotService;

    @Override
    public void run(String... args) throws Exception {
        Scanner scanner = new Scanner(System.in);
        System.out.println("=================================================");
        System.out.println("🤖 BIENVENIDO AL ASISTENTE VIRTUAL DE RSKITCHEN");
        System.out.println("=================================================");

        while (true) {
            System.out.println("\nSeleccione una opción e ingrese el número:");
            System.out.println("1. ¿Qué platillo se vende más?");
            System.out.println("2. ¿Cuáles son las ganancias actuales?");
            System.out.println("3. ¿Qué mesero ha hecho más pedidos?");
            System.out.println("4. ¿Cuál es el estado de las mesas actualmente?");
            System.out.println("5. ¿Cómo está el nivel de inventario de los productos?");
            System.out.println("6. Hacer una pregunta personalizada");
            System.out.println("7. Salir del Asistente");
            System.out.print("\nOpción: ");

            String input = scanner.nextLine().trim();

            if (input.equals("7")) {
                System.out.println("Saliendo del asistente... ¡Hasta pronto!");
                break;
            }

            String pregunta = "";

            switch (input) {
                case "1":
                    pregunta = "¿Qué platillo se vende más y cuál se vende menos?";
                    break;
                case "2":
                    pregunta = "Hazme un reporte de las ganancias actuales, pagadas y pendientes.";
                    break;
                case "3":
                    pregunta = "¿Qué mesero ha atendido la mayor cantidad de pedidos?";
                    break;
                case "4":
                    pregunta = "¿Cuál es el estado actual de las mesas (ocupadas vs libres)?";
                    break;
                case "5":
                    pregunta = "Dime cómo está el inventario de los productos y alerta si alguno tiene bajo stock.";
                    break;
                case "6":
                    System.out.print("\nEscribe tu pregunta: ");
                    pregunta = scanner.nextLine().trim();
                    if (pregunta.isEmpty()) {
                        System.out.println("La pregunta no puede estar vacía.");
                        continue;
                    }
                    break;
                default:
                    System.out.println("Opción no válida. Intente nuevamente.");
                    continue;
            }

            System.out.println("\n⏳ Analizando datos y consultando a Groq...");
            try {
                String respuesta = chatbotService.askQuestion(pregunta);
                System.out.println("\n================ RESPUESTA ================\n");
                System.out.println(respuesta);
                System.out.println("\n===========================================\n");
            } catch (Exception e) {
                System.out.println("❌ Ocurrió un error al consultar la IA: " + e.getMessage());
            }

            System.out.println("Presione ENTER para continuar...");
            scanner.nextLine();
        }
    }
}
