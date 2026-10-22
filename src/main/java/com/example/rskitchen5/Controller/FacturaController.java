package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Service.FacturaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/factura")
public class FacturaController {

    @Autowired
    private FacturaRep facturaRep;
    @Autowired
    private FacturaService facturaService;

    @GetMapping({ "", "/{id}" })
    public String mostrarFacturasOFactura(
            @PathVariable(required = false) String id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "30") int size,
            Model model) {

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "fecha"));
        Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
        Page<Factura> facturasPage = (restaurantId != null) 
                ? facturaRep.findByRestaurantId(restaurantId, pageable) 
                : Page.empty();

        model.addAttribute("facturas", facturasPage.getContent());
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", facturasPage.getTotalPages());

        if (id != null) {
            if (restaurantId != null) {
                facturaRep.findByIdAndRestaurantId(Long.parseLong(id), restaurantId).ifPresent(f -> model.addAttribute("factura", f));
            } else {
                facturaRep.findById(id).ifPresent(f -> model.addAttribute("factura", f));
            }
        }

        return "factura";
    }

    @GetMapping("/imprimir/{id}")
    public String imprimirFactura(@PathVariable String id, Model model) {
        Factura factura = facturaService.getById(id);
        model.addAttribute("factura", factura);
        return "factura-imprimir";
    }

    @GetMapping("/detalle/{id}")
    public String detalleFactura(@PathVariable String id, Model model) {
        Factura factura = facturaService.getById(id);
        model.addAttribute("factura", factura);
        return "fragments/detalle-factura :: detalle";
    }

}