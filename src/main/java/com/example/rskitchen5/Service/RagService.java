package com.example.rskitchen5.Service;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.nio.file.Files;

@Service
public class RagService {

    private final GroqApiClient groqApiClient;

    public RagService(GroqApiClient groqApiClient) {
        this.groqApiClient = groqApiClient;
    }

    public String askWithRag(String question) {

        String context = loadKnowledge();

        String finalPrompt = """
                Responde SOLO usando este contexto.

                Contexto:
                %s

                Pregunta:
                %s
                """.formatted(context, question);

        return groqApiClient.askGroq(finalPrompt);
    }

    public String loadKnowledge() {
        try {

            ClassPathResource resource =
                    new ClassPathResource("docs/info.txt");

            return Files.readString(resource.getFile().toPath());

        } catch (Exception e) {
            e.printStackTrace();
            return "No se pudo cargar el contexto.";
        }
    }
}