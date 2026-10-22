package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Restaurant;
import com.example.rskitchen5.Repository.RestaurantRep;
import com.example.rskitchen5.Repository.UserRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Optional;

@Controller
@RequestMapping("/admin/restaurantes")
@PreAuthorize("hasRole('CREATOR')")
public class RestaurantWebController {

    @Autowired
    private RestaurantRep restaurantRep;

    @Autowired
    private UserRep userRep;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @GetMapping
    public String listarRestaurantes(Model model) {
        List<Restaurant> restaurantes = restaurantRep.findAll();
        long totalRestaurantes = restaurantes.size();
        long activos = restaurantes.stream().filter(Restaurant::isActivo).count();
        long inactivos = totalRestaurantes - activos;

        model.addAttribute("restaurantes", restaurantes);
        model.addAttribute("totalRestaurantes", totalRestaurantes);
        model.addAttribute("activos", activos);
        model.addAttribute("inactivos", inactivos);
        model.addAttribute("nuevoRestaurante", new Restaurant());

        return "restaurantes";
    }

    @PostMapping("/crear")
    public String crearRestaurante(@ModelAttribute Restaurant restaurante, RedirectAttributes redirect) {
        try {
            if (restaurante.getCorreo() == null || restaurante.getCorreo().trim().isEmpty()) {
                redirect.addFlashAttribute("mensajeError", "El correo electrónico es obligatorio");
                return "redirect:/admin/restaurantes";
            }

            if (restaurantRep.findByCorreo(restaurante.getCorreo()).isPresent() || userRep.findByMail(restaurante.getCorreo()).isPresent()) {
                redirect.addFlashAttribute("mensajeError", "El correo ya está registrado en el sistema");
                return "redirect:/admin/restaurantes";
            }

            String password = restaurante.getContraseña() != null && !restaurante.getContraseña().trim().isEmpty()
                    ? restaurante.getContraseña()
                    : restaurante.getPassword();

            if (password == null || password.trim().isEmpty()) {
                redirect.addFlashAttribute("mensajeError", "La contraseña es obligatoria");
                return "redirect:/admin/restaurantes";
            }

            restaurante.setContraseña(passwordEncoder.encode(password));
            restaurante.setActivo(true);
            restaurantRep.save(restaurante);

            redirect.addFlashAttribute("mensajeExito", "Restaurante '" + restaurante.getNombre() + "' creado exitosamente");
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al crear restaurante: " + e.getMessage());
        }
        return "redirect:/admin/restaurantes";
    }

    @PostMapping("/editar")
    public String editarRestaurante(@RequestParam("id") Long id,
                                   @RequestParam("nombre") String nombre,
                                   @RequestParam("correo") String correo,
                                   @RequestParam(value = "nuevaPassword", required = false) String nuevaPassword,
                                   RedirectAttributes redirect) {
        try {
            Optional<Restaurant> optionalRest = restaurantRep.findById(id);
            if (optionalRest.isEmpty()) {
                redirect.addFlashAttribute("mensajeError", "Restaurante no encontrado");
                return "redirect:/admin/restaurantes";
            }

            Restaurant restaurant = optionalRest.get();

            // Si el correo cambió, verificar que no esté ocupado por otro
            if (!restaurant.getCorreo().equalsIgnoreCase(correo)) {
                if (restaurantRep.findByCorreo(correo).isPresent() || userRep.findByMail(correo).isPresent()) {
                    redirect.addFlashAttribute("mensajeError", "El nuevo correo ya está en uso por otra cuenta");
                    return "redirect:/admin/restaurantes";
                }
                restaurant.setCorreo(correo);
            }

            restaurant.setNombre(nombre);

            // Si se suministró nueva contraseña, actualizarla
            if (nuevaPassword != null && !nuevaPassword.trim().isEmpty()) {
                restaurant.setContraseña(passwordEncoder.encode(nuevaPassword.trim()));
            }

            restaurantRep.save(restaurant);
            redirect.addFlashAttribute("mensajeExito", "Restaurante '" + restaurant.getNombre() + "' actualizado exitosamente");
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al actualizar restaurante: " + e.getMessage());
        }
        return "redirect:/admin/restaurantes";
    }

    @PostMapping("/{id}/toggle-estado")
    public String alternarEstado(@PathVariable Long id, RedirectAttributes redirect) {
        try {
            Optional<Restaurant> optionalRest = restaurantRep.findById(id);
            if (optionalRest.isEmpty()) {
                redirect.addFlashAttribute("mensajeError", "Restaurante no encontrado");
                return "redirect:/admin/restaurantes";
            }

            Restaurant restaurant = optionalRest.get();
            boolean nuevoEstado = !restaurant.isActivo();
            restaurant.setActivo(nuevoEstado);
            restaurantRep.save(restaurant);

            String accion = nuevoEstado ? "activado" : "desactivado";
            redirect.addFlashAttribute("mensajeExito", "Restaurante '" + restaurant.getNombre() + "' " + accion + " correctamente");
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al cambiar estado: " + e.getMessage());
        }
        return "redirect:/admin/restaurantes";
    }
}
