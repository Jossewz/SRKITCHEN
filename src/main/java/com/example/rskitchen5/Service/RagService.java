package com.example.rskitchen5.Service;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;

@Service
public class RagService {

    private final GroqApiClient groqApiClient;

    public RagService(GroqApiClient groqApiClient) {
        this.groqApiClient = groqApiClient;
    }

    public String askWithRag(String question) {
        String context = loadKnowledge();

        String finalPrompt = """
                Responde amablemente la pregunta del usuario utilizando la información del restaurante.
                Si no tienes datos suficientes en el contexto, indícalo cortésmente.

                Contexto del Restaurante:
                %s

                Pregunta:
                %s
                """.formatted(context, question);

        return groqApiClient.askGroq(finalPrompt);
    }

    private String loadKnowledge() {
        try {
            ClassPathResource resource = new ClassPathResource("docs/info.txt");
            try (InputStream is = resource.getInputStream()) {
                return new String(is.readAllBytes(), StandardCharsets.UTF_8);
            }
        } catch (Exception e) {
            return "SR Kitchen: Restaurante y Bar. Abierto todos los días de 12:00 a 22:00.";
        }
    }
}