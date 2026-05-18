package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Repository.MesaRep;
import com.example.rskitchen5.Repository.PedidoRep;
import com.example.rskitchen5.Repository.UserRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Controller
public class LogisController {

    @Autowired
    private MesaRep mesaRep;

    @Autowired
    private PedidoRep pedidoRep;

    @Autowired
    private FacturaRep facturaRep;

    @Autowired
    private UserRep userRep;

    @GetMapping("/login")
    public String showLoginPage() {
        return "logis";
    }

    @GetMapping({"/home", "/start"})
    public String showHomePage(Model model) {
        long totalMesas = mesaRep.count();
        
        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();
        
        // Pedidos Hoy
        List<Pedido> pedidos = pedidoRep.findAll();
        long pedidosHoy = pedidos.stream()
                .filter(p -> p.getFecha() != null && !p.getFecha().isBefore(startOfDay) && p.getFecha().isBefore(endOfDay))
                .count();
                
        // Ingresos Hoy
        List<Factura> facturas = facturaRep.findAll();
        double ingresosHoy = facturas.stream()
                .filter(f -> f.getFecha() != null && !f.getFecha().isBefore(startOfDay) && f.getFecha().isBefore(endOfDay))
                .mapToDouble(f -> f.getTotal() != null ? f.getTotal() : 0.0)
                .sum();
                
        // Meseros Activos
        long meserosActivos = userRep.findAllMeseros().size();

        model.addAttribute("totalMesas", totalMesas);
        model.addAttribute("pedidosHoy", pedidosHoy);
        model.addAttribute("ingresosHoy", ingresosHoy);
        model.addAttribute("meserosActivos", meserosActivos);

        return "start";
    }
}
