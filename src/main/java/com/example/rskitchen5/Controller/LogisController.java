package com.example.rskitchen5.Controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class LogisController {

    @GetMapping("/login")
    public String showLoginPage() {
        return "logis";
    }

    @GetMapping("/home")
    public String showHomePage() {
        return "start";
    }
}
