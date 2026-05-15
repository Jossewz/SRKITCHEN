package com.example.rskitchen5.Service;

import com.example.rskitchen5.DTO.GroqMessage;
import com.example.rskitchen5.DTO.GroqRequest;
import com.example.rskitchen5.DTO.GroqResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Collections;

@Service
public class GroqApiClient {

    @Value("${groq.api.key}")
    private String apiKey;

    @Value("${groq.api.url}")
    private String apiUrl;

    @Value("${groq.api.model}")
    private String modelName;

    private final RestTemplate restTemplate;

    public GroqApiClient() {
        this.restTemplate = new RestTemplate();
    }

    public String askGroq(String prompt) {
        if (apiKey.equals("AQUI_PONER_TU_API_KEY") || apiKey.isEmpty()) {
            return "Error: API Key de Groq no configurada. Edita el archivo application.properties.";
        }

        GroqMessage userMessage = new GroqMessage("user", prompt);
        GroqRequest requestPayload = new GroqRequest(modelName, Collections.singletonList(userMessage));

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + apiKey);
        headers.set("Content-Type", "application/json");

        HttpEntity<GroqRequest> request = new HttpEntity<>(requestPayload, headers);

        try {
            ResponseEntity<GroqResponse> response = restTemplate.postForEntity(apiUrl, request, GroqResponse.class);

            if (response.getBody() != null && response.getBody().getChoices() != null && !response.getBody().getChoices().isEmpty()) {
                return response.getBody().getChoices().get(0).getMessage().getContent();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "Error comunicándose con Groq API: " + e.getMessage();
        }

        return "No se obtuvo respuesta válida de Groq.";
    }
}
