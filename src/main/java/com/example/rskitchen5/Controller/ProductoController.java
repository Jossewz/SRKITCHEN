package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Producto;
import com.example.rskitchen5.Repository.ProductoRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Controller
@RequestMapping("/producto")
public class ProductoController {

    @Autowired
    private ProductoRep productoRep;

    @GetMapping
    public String getAllProductos(Model model) {
        Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
        List<Producto> productos = (restaurantId != null) 
                ? productoRep.findByRestaurantId(restaurantId) 
                : java.util.Collections.emptyList();
        model.addAttribute("productos", productos);
        model.addAttribute("productoForm", new Producto());
        return "productos";
    }

    @PostMapping("/guardar")
    public String guardarProducto(@ModelAttribute("productoForm") Producto producto) {
        Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
        if (restaurantId != null) {
            producto.setRestaurantId(restaurantId);
        }
        if (producto.getId() == null || producto.getId().isEmpty()) {
            producto.setId(null);
        }
        productoRep.save(producto);
        return "redirect:/producto";
    }


    @GetMapping("/editar/{id}")
    public String editarProducto(@PathVariable String id, Model model) {
        Producto producto = productoRep.findById(id).orElse(new Producto());
        model.addAttribute("productoForm", producto);
        return "productos";
    }

    @PostMapping("/actualizar")
    public String actualizarProducto(@ModelAttribute("productoForm") Producto producto) {
        productoRep.save(producto);
        return "redirect:/producto";
    }

    @GetMapping("/eliminar/{id}")
    public String eliminarProducto(@PathVariable String id) {
        productoRep.deleteById(id);
        return "redirect:/producto";
    }
}

