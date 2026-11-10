package com.example.rskitchen5.Controller;

import com.example.rskitchen5.DTO.EstadoFacturaDTO;
import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Model.Pago;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Repository.FacturaRep;
import com.example.rskitchen5.Repository.PagoRep;
import com.example.rskitchen5.Repository.PedidoRep;
import com.example.rskitchen5.Service.InventarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.LocalDateTime;

@Controller
@RequestMapping("/pagos")
public class PagoController {

    @Autowired
    private PagoRep pagoRep;

    @Autowired
    private FacturaRep facturaRep;

    @Autowired
    private PedidoRep pedidoRep;

    @Autowired
    private InventarioService inventarioService;

    @GetMapping("/nuevo/{facturaId}")
    public String mostrarFormularioPago(@PathVariable String facturaId, Model model) {
        Factura factura = facturaRep.findById(facturaId)
                .orElseThrow(() -> new RuntimeException("Factura no encontrada"));
        model.addAttribute("factura", factura);
        return "pago_form";
    }

    @PostMapping("/procesar")
    @Transactional
    public String procesarPago(@RequestParam String facturaId,
            @RequestParam String metodo,
            @RequestParam double monto,
            @RequestParam(required = false) boolean imprimirCopia,
            RedirectAttributes redirect) {

        Pago pago = new Pago();
        pago.setFacturaId(facturaId);
        pago.setMetodo(metodo);
        pago.setMonto(monto);
        pago.setFecha(LocalDateTime.now());
        pago.setImprimirCopia(imprimirCopia);
        pagoRep.save(pago);

        Factura factura = facturaRep.findById(facturaId)
                .orElseThrow(() -> new RuntimeException("Factura no encontrada"));

        boolean yaPagada = factura.isPagada();
        factura.setEstado(EstadoFacturaDTO.APROBADA);
        factura.setPagada(true);
        facturaRep.save(factura);

        if (factura.getPedidoId() != null) {
            pedidoRep.findById(factura.getPedidoId()).ifPresent(pedido -> {
                pedido.setPagado(true);
                pedidoRep.save(pedido);
            });
        }

        // Restar el stock de los productos/ingredientes al finalizar el pago
        if (!yaPagada) {
            inventarioService.descontarStockPorFactura(factura);
        }

        redirect.addFlashAttribute("msg", "Pago procesado exitosamente. Stock de productos actualizado.");

        return "redirect:/factura/" + facturaId;
    }
}
