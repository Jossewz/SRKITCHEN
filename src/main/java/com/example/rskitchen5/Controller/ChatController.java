package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Service.ChatbotService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    @Autowired
    private ChatbotService chatbotService;

    @PostMapping
    public String chat(@RequestBody String pregunta) {
        return chatbotService.askQuestion(pregunta);
    }
}