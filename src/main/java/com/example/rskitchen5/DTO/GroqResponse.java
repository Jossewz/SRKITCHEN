package com.example.rskitchen5.DTO;

import java.util.List;

public class GroqResponse {
    private List<Choice> choices;

    public List<Choice> getChoices() {
        return choices;
    }

    public void setChoices(List<Choice> choices) {
        this.choices = choices;
    }

    public static class Choice {
        private GroqMessage message;

        public GroqMessage getMessage() {
            return message;
        }

        public void setMessage(GroqMessage message) {
            this.message = message;
        }
    }
}
