package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Mesero;
import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.RestaurantRep;
import com.example.rskitchen5.Repository.UserRep;
import com.example.rskitchen5.Security.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

@Controller
@RequestMapping("/mesero")
public class MeseroController {

    @Autowired
    private UserRep userRep;

    @Autowired
    private RestaurantRep restaurantRep;

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
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        List<User> meseros = (restaurantId != null) 
                ? userRep.findMeserosByRestaurantId(restaurantId) 
                : Collections.emptyList();

        long totalMeseros = meseros.size();
        long activos = meseros.stream().filter(User::isActivo).count();
        long inactivos = totalMeseros - activos;

        model.addAttribute("mesero", new Mesero());
        model.addAttribute("meseros", meseros);
        model.addAttribute("totalMeseros", totalMeseros);
        model.addAttribute("activos", activos);
        model.addAttribute("inactivos", inactivos);
        return "mesero";
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/guardar")
    public String guardarMesero(@ModelAttribute Mesero mesero, RedirectAttributes redirect) {
        try {
            Long restaurantId = TenantContext.getCurrentRestaurantId();
            if (restaurantId == null) {
                redirect.addFlashAttribute("mensajeError", "No se puede registrar personal sin un restaurante activo.");
                return "redirect:/mesero/registro";
            }

            if (mesero.getName() == null || mesero.getName().trim().isEmpty()) {
                redirect.addFlashAttribute("mensajeError", "El nombre del mesero es obligatorio.");
                return "redirect:/mesero/registro";
            }

            if (mesero.getMail() == null || mesero.getMail().trim().isEmpty()) {
                redirect.addFlashAttribute("mensajeError", "El correo electrónico es obligatorio.");
                return "redirect:/mesero/registro";
            }

            String correo = mesero.getMail().trim().toLowerCase();
            if (userRep.findByMail(correo).isPresent() || restaurantRep.findByCorreo(correo).isPresent()) {
                redirect.addFlashAttribute("mensajeError", "El correo '" + correo + "' ya se encuentra registrado en el sistema.");
                return "redirect:/mesero/registro";
            }

            if (mesero.getPassword() == null || mesero.getPassword().trim().isEmpty()) {
                redirect.addFlashAttribute("mensajeError", "La contraseña de acceso es obligatoria.");
                return "redirect:/mesero/registro";
            }

            User nuevoUsuario = new User();
            nuevoUsuario.setId_mesero(mesero.getId_mesero() != null && !mesero.getId_mesero().trim().isEmpty() 
                    ? mesero.getId_mesero().trim() : null);
            nuevoUsuario.setName(mesero.getName().trim());
            nuevoUsuario.setMail(correo);
            nuevoUsuario.setPassword(passwordEncoder.encode(mesero.getPassword().trim()));
            nuevoUsuario.setRol("ROLE_MESERO");
            nuevoUsuario.setRestaurantId(restaurantId);
            nuevoUsuario.setActivo(true);

            userRep.save(nuevoUsuario);

            redirect.addFlashAttribute("mensajeExito", "Mesero '" + nuevoUsuario.getName() + "' registrado exitosamente.");
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al registrar mesero: " + e.getMessage());
        }
        return "redirect:/mesero/registro";
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/editar")
    public String editarMesero(@RequestParam("id") Long id,
                               @RequestParam("name") String name,
                               @RequestParam("mail") String mail,
                               @RequestParam(value = "id_mesero", required = false) String id_mesero,
                               @RequestParam(value = "nuevaPassword", required = false) String nuevaPassword,
                               RedirectAttributes redirect) {
        try {
            Long restaurantId = TenantContext.getCurrentRestaurantId();
            if (restaurantId == null) {
                redirect.addFlashAttribute("mensajeError", "Sesión inválida.");
                return "redirect:/mesero/registro";
            }

            Optional<User> optionalUser = userRep.findByIdAndRestaurantId(id, restaurantId);
            if (optionalUser.isEmpty()) {
                redirect.addFlashAttribute("mensajeError", "Empleado no encontrado en su restaurante.");
                return "redirect:/mesero/registro";
            }

            User user = optionalUser.get();
            String nuevoCorreo = mail.trim().toLowerCase();

            // Si el correo cambió, verificar que no esté ocupado
            if (!user.getMail().equalsIgnoreCase(nuevoCorreo)) {
                if (userRep.findByMail(nuevoCorreo).isPresent() || restaurantRep.findByCorreo(nuevoCorreo).isPresent()) {
                    redirect.addFlashAttribute("mensajeError", "El correo '" + nuevoCorreo + "' ya está registrado por otra cuenta.");
                    return "redirect:/mesero/registro";
                }
                user.setMail(nuevoCorreo);
            }

            user.setName(name.trim());
            user.setId_mesero(id_mesero != null && !id_mesero.trim().isEmpty() ? id_mesero.trim() : user.getId_mesero());

            if (nuevaPassword != null && !nuevaPassword.trim().isEmpty()) {
                user.setPassword(passwordEncoder.encode(nuevaPassword.trim()));
            }

            userRep.save(user);
            redirect.addFlashAttribute("mensajeExito", "Empleado '" + user.getName() + "' actualizado correctamente.");
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al actualizar empleado: " + e.getMessage());
        }
        return "redirect:/mesero/registro";
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/{id}/toggle-estado")
    public String alternarEstadoMesero(@PathVariable Long id, RedirectAttributes redirect) {
        try {
            Long restaurantId = TenantContext.getCurrentRestaurantId();
            if (restaurantId == null) {
                redirect.addFlashAttribute("mensajeError", "Sesión inválida.");
                return "redirect:/mesero/registro";
            }

            Optional<User> optionalUser = userRep.findByIdAndRestaurantId(id, restaurantId);
            if (optionalUser.isEmpty()) {
                redirect.addFlashAttribute("mensajeError", "Empleado no encontrado en su restaurante.");
                return "redirect:/mesero/registro";
            }

            User user = optionalUser.get();
            boolean nuevoEstado = !user.isActivo();
            user.setActivo(nuevoEstado);
            userRep.save(user);

            String estadoStr = nuevoEstado ? "activado" : "desactivado";
            redirect.addFlashAttribute("mensajeExito", "Empleado '" + user.getName() + "' " + estadoStr + " correctamente.");
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al cambiar estado del empleado: " + e.getMessage());
        }
        return "redirect:/mesero/registro";
    }
}
