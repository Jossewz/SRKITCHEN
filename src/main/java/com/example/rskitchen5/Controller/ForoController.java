package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Foro;
import com.example.rskitchen5.Service.ForoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@Controller
public class ForoController {

    private final ForoService foroService;

    @Autowired
    public ForoController(ForoService foroService) {
        this.foroService = foroService;
    }

    @GetMapping("/foro")
    public String verForo(Model model) {
        List<Foro> foros = foroService.obtenerTodosLosForos();
        model.addAttribute("foros", foros);
        return "foro";
    }

    @PostMapping("/foro")
    public String crearComentario(@RequestParam("Fnombre") String fnombre,
                                  @RequestParam("Fcomentario") String fcomentario,
                                  Model model) {
        Foro foro = foroService.crearComentario(fnombre, fcomentario);
        model.addAttribute("message", "Comentario enviado con éxito.");
        return "redirect:/foro";
    }
}
