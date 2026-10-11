package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Mesero;
import com.example.rskitchen5.Repository.MeseroRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/mesero")
public class MeseroController {

    @Autowired
    private MeseroRep usuarioRep;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping
    public String redirectToRegistro() {
        return "redirect:/mesero/registro";
    }

    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/registro")
    public String mostrarFormulario(Model model) {
        model.addAttribute("mesero", new Mesero());
        model.addAttribute("meseros", usuarioRep.findAll());
        return "mesero";
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/guardar")
    public String guardarMesero(@ModelAttribute Mesero mesero, Model model) {
        mesero.setRol("ROLE_MESERO");
        mesero.setPassword(passwordEncoder.encode(mesero.getPassword()));
        usuarioRep.save(mesero);
        model.addAttribute("mensajeExito", "Mesero registrado correctamente.");
        model.addAttribute("mesero", new Mesero());
        model.addAttribute("meseros", usuarioRep.findAll());
        return "mesero";
    }
}
