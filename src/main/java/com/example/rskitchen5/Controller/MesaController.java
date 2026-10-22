package com.example.rskitchen5.Controller;

import com.example.rskitchen5.DTO.ItemPedidoDetalleDTO;
import com.example.rskitchen5.DTO.PedidoDetalleDTO;
import com.example.rskitchen5.Model.Factura;
import com.example.rskitchen5.Model.ItemPedido;
import com.example.rskitchen5.Model.Mesa;
import com.example.rskitchen5.Model.Pedido;
import com.example.rskitchen5.Repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.LocalDateTime;
import java.util.*;

@CrossOrigin(origins = "*")
@Controller
@RequestMapping("/mesa")
public class MesaController {

    private final MesaRep mesaRepository;
    private final PedidoRep pedidoRep;
    private final UserRep userRep;
    private final PlatilloRep platilloRep;
    private final FacturaRep facturaRep;

    @Autowired
    public MesaController(MesaRep mesaRepository, PedidoRep pedidoRep,
                          UserRep userRep, PlatilloRep platilloRep, FacturaRep facturaRep) {
        this.mesaRepository = mesaRepository;
        this.pedidoRep = pedidoRep;
        this.userRep = userRep;
        this.platilloRep = platilloRep;
        this.facturaRep = facturaRep;
    }

    @GetMapping("")
    public String mostrarVistaMesa(Model model) {
        Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
        List<Mesa> mesas = (restaurantId != null) 
                ? mesaRepository.findByRestaurantId(restaurantId) 
                : Collections.emptyList();

        Map<String, String> nombresMeseros = new HashMap<>();
        Map<String, List<PedidoDetalleDTO>> pedidosPorMesa = new HashMap<>();

        for (Mesa mesa : mesas) {
            if (mesa.getMeseroId() != null) {
                userRep.findById(mesa.getMeseroId())
                        .ifPresent(mesero -> nombresMeseros.put(mesa.getId(), mesero.getName()));
            }

            List<PedidoDetalleDTO> pedidosDTO = new ArrayList<>();
            if (mesa.getPedidosId() != null) {
                for (String pedidoId : mesa.getPedidosId()) {
                    pedidoRep.findById(pedidoId).ifPresent(pedido -> {
                        PedidoDetalleDTO dto = convertirPedidoADTO(pedido);
                        pedidosDTO.add(dto);
                    });
                }
            }
            pedidosPorMesa.put(mesa.getId(), pedidosDTO);
        }

        model.addAttribute("listar", mesas);
        model.addAttribute("nuevaMesa", new Mesa());
        model.addAttribute("nombresMeseros", nombresMeseros);
        model.addAttribute("pedidosPorMesa", pedidosPorMesa);
        return "mesa";
    }

    @PostMapping("/crear")
    public String crearMesa(@ModelAttribute Mesa mesa, RedirectAttributes redirect) {
        try {
            Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
            if (restaurantId == null) {
                redirect.addFlashAttribute("mensajeError", "No se puede crear mesa sin un restaurante activo");
                return "redirect:/mesa";
            }
            mesa.setRestaurantId(restaurantId);
            mesaRepository.save(mesa);
            redirect.addFlashAttribute("mensajeExito", "Mesa creada exitosamente");
        } catch (Exception e) {
            redirect.addFlashAttribute("mensajeError", "Error al crear la mesa: " + e.getMessage());
        }
        return "redirect:/mesa";
    }

    @GetMapping("/{id}")
    public String mostrarMesaDetalle(@PathVariable String id, Model model) {
        mesaRepository.findById(id).ifPresent(mesa -> {
            model.addAttribute("mesaDetalle", mesa);

            List<PedidoDetalleDTO> pedidosDTO = new ArrayList<>();
            if (mesa.getPedidosId() != null) {
                for (String pedidoId : mesa.getPedidosId()) {
                    pedidoRep.findById(pedidoId).ifPresent(pedido -> {
                        PedidoDetalleDTO dto = convertirPedidoADTO(pedido);
                        pedidosDTO.add(dto);
                    });
                }
            }
            model.addAttribute("pedidos", pedidosDTO);

            if (mesa.getMeseroId() != null) {
                userRep.findById(mesa.getMeseroId())
                        .ifPresent(mesero -> model.addAttribute("nombreMesero", mesero.getName()));
            }
        });

        return "mesa";
    }

    private PedidoDetalleDTO convertirPedidoADTO(Pedido pedido) {
        PedidoDetalleDTO dto = new PedidoDetalleDTO();
        dto.setId(pedido.getId());
        dto.setFecha(pedido.getFecha());
        dto.setTotal(pedido.getTotal());
        dto.setPagado(pedido.isPagado());

        if (pedido.getMeseroId() != null) {
            userRep.findById(pedido.getMeseroId())
                    .ifPresent(mesero -> dto.setNombreMesero(mesero.getName()));
        }

        List<ItemPedidoDetalleDTO> itemsDTO = new ArrayList<>();
        if (pedido.getItems() != null) {
            for (ItemPedido item : pedido.getItems()) {
                ItemPedidoDetalleDTO itemDTO = new ItemPedidoDetalleDTO();
                itemDTO.setCantidad(item.getCant());
                itemDTO.setPrecio(item.getPrice());
                itemDTO.setNombrePlatillo(item.getName());
                itemsDTO.add(itemDTO);
            }
        }
        dto.setItems(itemsDTO);

        return dto;
    }

    @PostMapping("/{id}/generar-factura")
    @Transactional
    public String generarFactura(@PathVariable String id, RedirectAttributes redirect) {
        Optional<Mesa> optionalMesa = mesaRepository.findById(id);

        if (optionalMesa.isEmpty()) {
            redirect.addFlashAttribute("mensajeError", "Mesa no encontrada");
            return "redirect:/mesa";
        }

        Mesa mesa = optionalMesa.get();

        if (mesa.getPedidosId() == null || mesa.getPedidosId().isEmpty()) {
            redirect.addFlashAttribute("mensajeError", "La mesa no tiene pedidos para facturar");
            return "redirect:/mesa";
        }

        List<ItemPedido> allItems = new ArrayList<>();
        double totalMesa = 0.0;
        String mainPedidoId = mesa.getPedidosId().get(0);

        for (String pedidoId : mesa.getPedidosId()) {
            Optional<Pedido> optionalPedido = pedidoRep.findById(pedidoId);
            if (optionalPedido.isPresent()) {
                Pedido pedido = optionalPedido.get();
                if (pedido.getItems() != null) {
                    allItems.addAll(pedido.getItems());
                }
                totalMesa += pedido.getTotal();
            }
        }

        Factura factura = new Factura();
        factura.setPedidoId(mainPedidoId);
        factura.setMesaNum(String.valueOf(mesa.getNum()));

        if (mesa.getMeseroId() != null) {
            userRep.findById(mesa.getMeseroId())
                    .ifPresent(mesero -> factura.setMeseroName(mesero.getName()));
        }

        factura.setFecha(LocalDateTime.now());
        factura.setItems(allItems);
        factura.setTotal(totalMesa);
        factura.setRestaurantId(mesa.getRestaurantId());

        facturaRep.save(factura);

        mesa.setOcupado(false);
        mesa.setMeseroId(null);
        mesa.setPedidosId(new ArrayList<>());
        mesaRepository.save(mesa);

        redirect.addFlashAttribute("mensajeExito", "Factura generada y mesa liberada con éxito");

        return "redirect:/mesa";
    }
}