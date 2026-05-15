package com.example.rskitchen5.weka;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class ViewController {

    @GetMapping("/datos")
    public String mostrarVistaWeka() {
        return "datos";
    }
}