package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Producto;
import com.example.rskitchen5.Repository.ProductoRep;
import com.example.rskitchen5.Security.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Optional;

@Controller
@RequestMapping("/producto")
public class ProductoController {

    @Autowired
    private ProductoRep productoRep;

    @GetMapping
    public String getAllProductos(Model model) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        List<Producto> productos = (restaurantId != null) 
                ? productoRep.findByRestaurantId(restaurantId) 
                : java.util.Collections.emptyList();
        model.addAttribute("productos", productos);

        long criticosCount = productos.stream().filter(p -> p.getStock() <= 5).count();
        model.addAttribute("criticosCount", criticosCount);
        if (!model.containsAttribute("productoForm")) {
            model.addAttribute("productoForm", new Producto());
        }
        return "productos";
    }

    /**
     * Método para agregar un nuevo producto.
     */
    @PostMapping({"/guardar", "/agregar"})
    public String agregarProducto(@ModelAttribute("productoForm") Producto producto, RedirectAttributes redirect) {
        try {
            Long restaurantId = TenantContext.getCurrentRestaurantId();
            if (restaurantId != null) {
                producto.setRestaurantId(restaurantId);
            }
            if (producto.getId() == null || producto.getId().trim().isEmpty()) {
                producto.setId(null);
            }
            if (producto.getId() == null) {
                producto.setActivo(true);
            }
            if (producto.getUMedida() != null && !producto.getUMedida().trim().isEmpty()) {
                producto.setCant(producto.getUMedida());
            } else if (producto.getCant() != null && !producto.getCant().trim().isEmpty()) {
                producto.setUMedida(producto.getCant());
            }
            productoRep.save(producto);
            redirect.addFlashAttribute("mensajeExito", "Producto '" + producto.getName() + "' agregado exitosamente.");
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al agregar el producto: " + e.getMessage());
        }
        return "redirect:/producto";
    }

    /**
     * Muestra la vista con el producto a editar cargado en el formulario/modal.
     */
    @GetMapping("/editar/{id}")
    public String editarProducto(@PathVariable String id, Model model) {
        Long restaurantId = TenantContext.getCurrentRestaurantId();
        List<Producto> productos = (restaurantId != null) 
                ? productoRep.findByRestaurantId(restaurantId) 
                : java.util.Collections.emptyList();
        model.addAttribute("productos", productos);

        Producto producto = productoRep.findById(id).orElse(new Producto());
        model.addAttribute("productoForm", producto);
        return "productos";
    }

    /**
     * Método para procesar la actualización / edición del producto.
     */
    @PostMapping({"/actualizar", "/editar"})
    public String actualizarProducto(@ModelAttribute("productoForm") Producto producto, RedirectAttributes redirect) {
        try {
            Long restaurantId = TenantContext.getCurrentRestaurantId();
            if (producto.getIdLong() != null) {
                Optional<Producto> existingOpt = productoRep.findById(producto.getIdLong());
                if (existingOpt.isPresent()) {
                    Producto existing = existingOpt.get();
                    existing.setName(producto.getName());
                    if (producto.getDescripcion() != null && !producto.getDescripcion().isEmpty()) {
                        existing.setDescripcion(producto.getDescripcion());
                    }
                    if (producto.getUMedida() != null && !producto.getUMedida().trim().isEmpty()) {
                        existing.setUMedida(producto.getUMedida());
                        existing.setCant(producto.getUMedida());
                    } else if (producto.getCant() != null && !producto.getCant().trim().isEmpty()) {
                        existing.setCant(producto.getCant());
                        existing.setUMedida(producto.getCant());
                    }
                    if (producto.getPrice() > 0) {
                        existing.setPrice(producto.getPrice());
                    }
                    existing.setStock(producto.getStock());
                    existing.setActivo(producto.isActivo());
                    if (restaurantId != null) {
                        existing.setRestaurantId(restaurantId);
                    }
                    productoRep.save(existing);
                    redirect.addFlashAttribute("mensajeExito", "Producto '" + existing.getName() + "' actualizado exitosamente.");
                    return "redirect:/producto";
                }
            }
            if (restaurantId != null) {
                producto.setRestaurantId(restaurantId);
            }
            if (producto.getUMedida() != null && (producto.getCant() == null || producto.getCant().isEmpty())) {
                producto.setCant(producto.getUMedida());
            }
            productoRep.save(producto);
            redirect.addFlashAttribute("mensajeExito", "Producto guardado exitosamente.");
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al actualizar el producto: " + e.getMessage());
        }
        return "redirect:/producto";
    }

    /**
     * Método para desactivar un producto.
     */
    @PostMapping("/desactivar/{id}")
    public String desactivarProducto(@PathVariable String id, RedirectAttributes redirect) {
        try {
            Optional<Producto> opt = productoRep.findById(id);
            if (opt.isPresent()) {
                Producto producto = opt.get();
                producto.desactivar();
                productoRep.save(producto);
                redirect.addFlashAttribute("mensajeExito", "Producto '" + producto.getName() + "' desactivado exitosamente.");
            } else {
                redirect.addFlashAttribute("mensajeError", "Producto no encontrado.");
            }
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al desactivar el producto: " + e.getMessage());
        }
        return "redirect:/producto";
    }

    @GetMapping("/desactivar/{id}")
    public String desactivarProductoGet(@PathVariable String id, RedirectAttributes redirect) {
        return desactivarProducto(id, redirect);
    }

    /**
     * Método para activar un producto.
     */
    @PostMapping("/activar/{id}")
    public String activarProducto(@PathVariable String id, RedirectAttributes redirect) {
        try {
            Optional<Producto> opt = productoRep.findById(id);
            if (opt.isPresent()) {
                Producto producto = opt.get();
                producto.activar();
                productoRep.save(producto);
                redirect.addFlashAttribute("mensajeExito", "Producto '" + producto.getName() + "' activado exitosamente.");
            } else {
                redirect.addFlashAttribute("mensajeError", "Producto no encontrado.");
            }
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al activar el producto: " + e.getMessage());
        }
        return "redirect:/producto";
    }

    @GetMapping("/activar/{id}")
    public String activarProductoGet(@PathVariable String id, RedirectAttributes redirect) {
        return activarProducto(id, redirect);
    }

    /**
     * Alternar estado activo / desactivado del producto.
     */
    @PostMapping("/{id}/toggle-estado")
    public String toggleEstadoProducto(@PathVariable String id, RedirectAttributes redirect) {
        try {
            Optional<Producto> opt = productoRep.findById(id);
            if (opt.isPresent()) {
                Producto producto = opt.get();
                boolean nuevoEstado = !producto.isActivo();
                producto.setActivo(nuevoEstado);
                productoRep.save(producto);
                String estadoStr = nuevoEstado ? "activado" : "desactivado";
                redirect.addFlashAttribute("mensajeExito", "Producto '" + producto.getName() + "' " + estadoStr + " correctamente.");
            } else {
                redirect.addFlashAttribute("mensajeError", "Producto no encontrado.");
            }
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al cambiar el estado del producto: " + e.getMessage());
        }
        return "redirect:/producto";
    }

    @GetMapping("/{id}/toggle-estado")
    public String toggleEstadoProductoGet(@PathVariable String id, RedirectAttributes redirect) {
        return toggleEstadoProducto(id, redirect);
    }

    @GetMapping("/eliminar/{id}")
    public String eliminarProducto(@PathVariable String id, RedirectAttributes redirect) {
        try {
            productoRep.deleteById(id);
            redirect.addFlashAttribute("mensajeExito", "Producto eliminado del inventario correctamente.");
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al eliminar el producto: " + e.getMessage());
        }
        return "redirect:/producto";
    }
}
