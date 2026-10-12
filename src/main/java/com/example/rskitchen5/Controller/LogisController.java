package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Model.Mesa;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Model.Producto;
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

    @Autowired
    private com.example.rskitchen5.Repository.ProductoRep productoRep;

    @GetMapping("/login")
    public String showLoginPage() {
        return "logis";
    }

    @GetMapping({"/home", "/start"})
    public String showHomePage(Model model) {
        List<Mesa> mesas = mesaRep.findAll();
        long totalMesas = mesas.size();
        long mesasOcupadas = mesas.stream().filter(Mesa::isOcupado).count();
        long mesasLibres = totalMesas - mesasOcupadas;
        
        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();
        
        // Pedidos Hoy
        List<Pedido> todosPedidos = pedidoRep.findAll();
        long pedidosHoy = todosPedidos.stream()
                .filter(p -> p.getFecha() != null && !p.getFecha().isBefore(startOfDay) && p.getFecha().isBefore(endOfDay))
                .count();
                
        // Pedidos activos (no pagados / en cocina)
        List<Pedido> pedidosActivos = todosPedidos.stream()
                .filter(p -> !p.isPagado())
                .sorted((a, b) -> {
                    if (a.getFecha() == null || b.getFecha() == null) return 0;
                    return b.getFecha().compareTo(a.getFecha());
                })
                .limit(6)
                .toList();

        // Ingresos Hoy
        List<Factura> facturas = facturaRep.findAll();
        double ingresosHoy = facturas.stream()
                .filter(f -> f.getFecha() != null && !f.getFecha().isBefore(startOfDay) && f.getFecha().isBefore(endOfDay))
                .mapToDouble(Factura::getTotal)
                .sum();
                
        // Meseros Activos
        long meserosActivos = userRep.findAllMeseros().size();

        // Alertas de insumos / stock crítico (stock <= 5)
        List<com.example.rskitchen5.Model.Producto> todosProductos = productoRep.findAll();
        List<com.example.rskitchen5.Model.Producto> productosCriticos = todosProductos.stream()
                .filter(p -> p.getStock() <= 5)
                .limit(6)
                .toList();

        model.addAttribute("totalMesas", totalMesas);
        model.addAttribute("mesasOcupadas", mesasOcupadas);
        model.addAttribute("mesasLibres", mesasLibres);
        model.addAttribute("mesas", mesas);
        model.addAttribute("pedidosHoy", pedidosHoy);
        model.addAttribute("pedidosActivos", pedidosActivos);
        model.addAttribute("ingresosHoy", ingresosHoy);
        model.addAttribute("meserosActivos", meserosActivos);
        model.addAttribute("productosCriticos", productosCriticos);

        return "start";
    }
}
