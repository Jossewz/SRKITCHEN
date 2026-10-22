package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Platillo;
import com.example.rskitchen5.Repository.PlatilloRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@Controller
@RequestMapping("/platillos")
public class PlatilloController {

    @Autowired
    private PlatilloRep platilloRep;

    @GetMapping
    public String getAllPlatillos(Model model) {
        try {
            Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
            List<Platillo> platillos = (restaurantId != null) 
                    ? platilloRep.findByRestaurantId(restaurantId) 
                    : java.util.Collections.emptyList();
            model.addAttribute("platillos", platillos);
            model.addAttribute("platilloNuevo", new Platillo());
            return "platillos";
        } catch (Exception e) {
            model.addAttribute("error", "Error al cargar los platillos");
            return "platillos";
        }
    }

    @PostMapping("/guardar")
    public String crearPlatillo(@ModelAttribute("platilloNuevo") Platillo platillo, Model model) {
        try {
            Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
            if (restaurantId == null) {
                model.addAttribute("error", "No se puede guardar platillo sin un restaurante activo");
                return "platillos";
            }
            platillo.setRestaurantId(restaurantId);
            platilloRep.save(platillo);
            return "redirect:/platillos";
        } catch (Exception e) {
            model.addAttribute("error", "Error al guardar el platillo");
            return "platillos";
        }
    }

    @PostMapping("/editar/{id}")
    public String updatePlatillo(@PathVariable String id, @ModelAttribute Platillo platillo) {
        try {
            Platillo existingPlatillo = platilloRep.findById(id).orElseThrow();
            existingPlatillo.setName(platillo.getName());
            existingPlatillo.setCant(platillo.getCant());
            existingPlatillo.setPrice(platillo.getPrice());
            platilloRep.save(existingPlatillo);
            return "redirect:/platillos";
        } catch (Exception e) {
            return "redirect:/platillos?error=update";
        }
    }

    @PostMapping("/eliminar/{id}")
    public String deletePlatillo(@PathVariable String id) {
        try {
            platilloRep.deleteById(id);
            return "redirect:/platillos";
        } catch (Exception e) {
            return "redirect:/platillos?error=delete";
        }
    }

    @GetMapping("/editar/{id}")
    public String mostrarFormularioEditarPlatillo(@PathVariable String id, Model model) {
        try {
            Platillo platillo = platilloRep.findById(id).orElseThrow(() -> new IllegalArgumentException("Platillo no encontrado"));
            model.addAttribute("platillo", platillo);
            return "editar-platillo";
        } catch (Exception e) {
            model.addAttribute("error", "Error al cargar el platillo para editar");
            return "platillos";
        }
    }
}
