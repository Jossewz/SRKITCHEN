
package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Platillo;
import com.example.rskitchen5.Model.PlatilloIngrediente;
import com.example.rskitchen5.Model.Producto;
import com.example.rskitchen5.Repository.PlatilloRep;
import com.example.rskitchen5.Repository.ProductoRep;
import com.example.rskitchen5.Security.TenantContext;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

@Controller
@RequestMapping("/platillos")
public class PlatilloController {

    @Autowired
    private PlatilloRep platilloRep;

    @Autowired
    private ProductoRep productoRep;

    @GetMapping
    public String getAllPlatillos(Model model) {
        try {
            Long restaurantId = TenantContext.getCurrentRestaurantId();

            List<Platillo> platillos = (restaurantId != null)
                    ? platilloRep.findByRestaurantId(restaurantId)
                    : Collections.emptyList();

            // ==========================================
            // DIAGNOSTICO DE PLATILLOS
            // ==========================================

            System.out.println("=== DIAGNOSTICO PLATILLOS ===");

            System.out.println("Restaurante ID: " + restaurantId);

            System.out.println("Cantidad: " +
                    (platillos != null ? platillos.size() : "LISTA NULL"));

            if (platillos != null) {
                for (int i = 0; i < platillos.size(); i++) {

                    Platillo p = platillos.get(i);

                    if (p == null) {
                        System.out.println(
                                "PLATILLO NULL en posicion: " + i);
                    } else {
                        System.out.println(
                                "ID: " + p.getId()
                                        + " | Nombre: " + p.getName());
                    }
                }
            }

            System.out.println("=== FIN DIAGNOSTICO ===");

            // ==========================================
            // CARGA DE PRODUCTOS
            // ==========================================

            List<Producto> productos = (restaurantId != null)
                    ? productoRep.findByRestaurantId(restaurantId)
                    : Collections.emptyList();

            model.addAttribute("platillos", platillos);
            model.addAttribute("productos", productos);
            model.addAttribute("platilloNuevo", new Platillo());

            return "platillos";

        } catch (Exception e) {

            e.printStackTrace();

            model.addAttribute("platillos", Collections.emptyList());
            model.addAttribute("productos", Collections.emptyList());
            model.addAttribute("platilloNuevo", new Platillo());

            model.addAttribute(
                    "error",
                    "Error al cargar los platillos: " + e.getMessage());

            return "platillos";
        }
    }

    @PostMapping("/guardar")
    @Transactional
    public String crearPlatillo(
            @ModelAttribute("platilloNuevo") Platillo platillo,
            @RequestParam(value = "productoIds", required = false) List<Long> productoIds,
            @RequestParam(value = "cantidades", required = false) List<Double> cantidades,
            Model model) {

        try {
            Long restaurantId = TenantContext.getCurrentRestaurantId();

            if (restaurantId == null) {
                model.addAttribute(
                        "error",
                        "No se puede guardar platillo sin un restaurante activo");
                return "redirect:/platillos";
            }

            platillo.setRestaurantId(restaurantId);
            platillo.setCant("");

            if (productoIds != null && cantidades != null) {

                for (int i = 0; i < productoIds.size(); i++) {

                    Long prodId = productoIds.get(i);

                    Double cant = (i < cantidades.size()
                            && cantidades.get(i) != null)
                                    ? cantidades.get(i)
                                    : 1.0;

                    if (prodId != null && cant > 0) {

                        Optional<Producto> prodOpt = productoRep.findById(prodId);

                        if (prodOpt.isPresent()) {

                            PlatilloIngrediente pi = new PlatilloIngrediente(
                                    platillo,
                                    prodOpt.get(),
                                    cant);

                            platillo.addIngrediente(pi);
                        }
                    }
                }
            }

            platilloRep.save(platillo);

            return "redirect:/platillos";

        } catch (Exception e) {

            e.printStackTrace();

            model.addAttribute(
                    "error",
                    "Error al guardar el platillo: " + e.getMessage());

            return "redirect:/platillos?error=save";
        }
    }

    @PostMapping("/editar/{id}")
    @Transactional
    public String updatePlatillo(
            @PathVariable String id,
            @ModelAttribute Platillo platillo,
            @RequestParam(value = "productoIds", required = false) List<Long> productoIds,
            @RequestParam(value = "cantidades", required = false) List<Double> cantidades) {

        try {
            Platillo existingPlatillo = platilloRep.findById(id).orElseThrow();

            existingPlatillo.setName(platillo.getName());
            existingPlatillo.setPrice(platillo.getPrice());

            existingPlatillo.getIngredientes().clear();

            if (productoIds != null && cantidades != null) {

                for (int i = 0; i < productoIds.size(); i++) {

                    Long prodId = productoIds.get(i);

                    Double cant = (i < cantidades.size()
                            && cantidades.get(i) != null)
                                    ? cantidades.get(i)
                                    : 1.0;

                    if (prodId != null && cant > 0) {

                        Optional<Producto> prodOpt = productoRep.findById(prodId);

                        if (prodOpt.isPresent()) {

                            PlatilloIngrediente pi = new PlatilloIngrediente(
                                    existingPlatillo,
                                    prodOpt.get(),
                                    cant);

                            existingPlatillo.addIngrediente(pi);
                        }
                    }
                }
            }

            platilloRep.save(existingPlatillo);

            return "redirect:/platillos";

        } catch (Exception e) {

            e.printStackTrace();

            return "redirect:/platillos?error=update";
        }
    }

    @PostMapping("/eliminar/{id}")
    public String deletePlatillo(@PathVariable String id) {

        try {
            platilloRep.deleteById(id);

            return "redirect:/platillos";

        } catch (Exception e) {

            e.printStackTrace();

            return "redirect:/platillos?error=delete";
        }
    }

    @GetMapping("/editar/{id}")
    public String mostrarFormularioEditarPlatillo(
            @PathVariable String id,
            Model model) {

        try {
            Platillo platillo = platilloRep.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException(
                            "Platillo no encontrado"));

            Long restaurantId = TenantContext.getCurrentRestaurantId();

            List<Producto> productos = (restaurantId != null)
                    ? productoRep.findByRestaurantId(restaurantId)
                    : Collections.emptyList();

            model.addAttribute("platillo", platillo);
            model.addAttribute("productos", productos);

            return "editar-platillo";

        } catch (Exception e) {

            e.printStackTrace();

            return "redirect:/platillos?error=edit";
        }
    }
}
