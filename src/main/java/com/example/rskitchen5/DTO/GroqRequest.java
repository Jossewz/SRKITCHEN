package com.example.rskitchen5.DTO;

import java.util.List;

public class GroqRequest {
    private String model;
    private List<GroqMessage> messages;
    private double temperature;
    
    public GroqRequest() {}

    public GroqRequest(String model, List<GroqMessage> messages) {
        this.model = model;
        this.messages = messages;
        this.temperature = 0.5; // default temperature
    }

    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }

    public List<GroqMessage> getMessages() { return messages; }
    public void setMessages(List<GroqMessage> messages) { this.messages = messages; }

    public double getTemperature() { return temperature; }
    public void setTemperature(double temperature) { this.temperature = temperature; }
}
