package com.example.rskitchen5.Controller;

import com.example.rskitchen5.Model.*;
import com.example.rskitchen5.Repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Controller
@RequestMapping({ "/pedidos", "/pedido" })
@Transactional
public class PedidoController {

    @Autowired
    private PedidoRep pedidoRep;
    @Autowired
    private MesaRep mesaRep;
    @Autowired
    private PlatilloRep platilloRep;
    @Autowired
    private UserRep userRep;
    @Autowired
    private FacturaRep facturaRep;

    @GetMapping
    public String mostrarFormularioPedido(@RequestParam(name = "id", required = false) String id, Model model) {
        try {
            Pedido pedido;
            boolean modoEdicion = false;

            if (id != null && !id.isEmpty()) {
                pedido = pedidoRep.findById(id)
                        .orElseThrow(() -> new IllegalArgumentException("Pedido no encontrado"));
                modoEdicion = true;
            } else {
                pedido = new Pedido();
            }

            Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
            model.addAttribute("pedido", pedido);
            model.addAttribute("modoEdicion", modoEdicion);
            model.addAttribute("mesas", (restaurantId != null) ? mesaRep.findByRestaurantIdAndOcupadoFalse(restaurantId)
                    : Collections.emptyList());
            model.addAttribute("platillos",
                    (restaurantId != null) ? platilloRep.findByRestaurantId(restaurantId) : Collections.emptyList());

            List<User> meseros = (restaurantId != null) ? userRep.findMeserosByRestaurantId(restaurantId)
                    : Collections.emptyList();
            model.addAttribute("meseros", meseros);

            model.addAttribute("pedidosRecientes", getPedidosConDetalles());
            return "pedido";

        } catch (Exception e) {
            model.addAttribute("error", "Error al cargar el formulario de pedidos: " + e.getMessage());
            model.addAttribute("pedido", new Pedido());
            model.addAttribute("modoEdicion", false);
            model.addAttribute("mesas", Collections.emptyList());
            model.addAttribute("platillos", Collections.emptyList());
            model.addAttribute("meseros", Collections.emptyList());
            model.addAttribute("pedidosRecientes", Collections.emptyList());
            return "pedido";
        }
    }

    @GetMapping("/editar/{id}")
    public String mostrarFormularioEdicion(@PathVariable("id") String id, Model model) {
        try {
            Pedido pedido = pedidoRep.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Pedido no encontrado"));

            if (pedido.getMeseroId() != null) {
                User mesero = userRep.findById(pedido.getMeseroId()).orElse(new User());
                pedido.setMeseroName(mesero.getName());
            }

            Mesa mesaActual = null;
            if (pedido.getMesaId() != null) {
                mesaActual = mesaRep.findById(pedido.getMesaId()).orElse(null);
            }

            Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
            List<Mesa> mesas = (restaurantId != null) ? mesaRep.findByRestaurantId(restaurantId)
                    : Collections.emptyList();

            model.addAttribute("pedido", pedido);
            model.addAttribute("mesas", mesas);
            model.addAttribute("mesaActual", mesaActual);
            model.addAttribute("platillosDisponibles",
                    (restaurantId != null) ? platilloRep.findByRestaurantId(restaurantId) : Collections.emptyList());

            List<User> meseros = (restaurantId != null) ? userRep.findMeserosByRestaurantId(restaurantId)
                    : Collections.emptyList();
            model.addAttribute("meseros", meseros);

            return "pedido-editar";

        } catch (Exception e) {
            model.addAttribute("error", "Error al cargar el formulario de edición: " + e.getMessage());
            model.addAttribute("pedido", new Pedido());
            model.addAttribute("modoEdicion", false);
            model.addAttribute("mesas", Collections.emptyList());
            model.addAttribute("platillos", Collections.emptyList());
            model.addAttribute("meseros", Collections.emptyList());
            model.addAttribute("pedidosRecientes", Collections.emptyList());
            return "pedido";
        }
    }

    @PostMapping("/editar")
    public String editarPedido(
            @RequestParam("id") String pedidoId,
            @RequestParam("mesaId") String mesaId,
            @RequestParam(value = "itemsExistentes", required = false) List<String> platillosExistentesIds,
            @RequestParam(value = "cantidadesExistentes", required = false) List<Integer> cantidadesExistentes,
            @RequestParam(value = "nuevosPlatillos", required = false) List<String> platillosNuevosIds,
            @RequestParam(value = "nuevasCantidades", required = false) List<Integer> cantidadesNuevas,
            Model model) {
        try {
            Pedido pedido = pedidoRep.findById(pedidoId)
                    .orElseThrow(() -> new IllegalArgumentException("Pedido no encontrado con ID: " + pedidoId));

            Mesa mesa = mesaRep.findById(mesaId)
                    .orElseThrow(() -> new IllegalArgumentException("Mesa no encontrada con ID: " + mesaId));
            pedido.setMesaId(mesaId);
            pedido.setMesaNum(mesa.getNum());
            pedido.setFecha(LocalDateTime.now());

            List<ItemPedido> itemsActualizados = new ArrayList<>();
            Map<String, ItemPedido> existingItemsMap = pedido.getItems().stream()
                    .collect(Collectors.toMap(ItemPedido::getProductId, item -> item));

            if (platillosExistentesIds != null && cantidadesExistentes != null &&
                    platillosExistentesIds.size() == cantidadesExistentes.size()) {
                for (int i = 0; i < platillosExistentesIds.size(); i++) {
                    String platilloId = platillosExistentesIds.get(i);
                    Integer cantidad = cantidadesExistentes.get(i);

                    if (platilloId != null && !platilloId.isEmpty() && cantidad != null && cantidad > 0
                            && existingItemsMap.containsKey(platilloId)) {
                        ItemPedido item = existingItemsMap.get(platilloId);
                        item.setUnidades(cantidad);
                        item.setCant(String.valueOf(cantidad));
                        itemsActualizados.add(item);
                        existingItemsMap.remove(platilloId);
                    }
                }
            }

            itemsActualizados.addAll(existingItemsMap.values());

            if (platillosNuevosIds != null && cantidadesNuevas != null &&
                    platillosNuevosIds.size() == cantidadesNuevas.size()) {
                for (int i = 0; i < platillosNuevosIds.size(); i++) {
                    String platilloId = platillosNuevosIds.get(i);
                    if (platilloId != null && !platilloId.isEmpty()) {
                        Integer cantidad = cantidadesNuevas.get(i);
                        if (cantidad != null && cantidad > 0 && !existingItemsMap.containsKey(platilloId)) { // Evitar
                                                                                                             // duplicados
                            Platillo platillo = platilloRep.findById(platilloId)
                                    .orElseThrow(() -> new IllegalArgumentException(
                                            "Platillo nuevo no encontrado con ID: " + platilloId));
                            ItemPedido nuevoItem = new ItemPedido();
                            nuevoItem.setProductId(platilloId);
                            nuevoItem.setName(platillo.getName());
                            nuevoItem.setPrice(platillo.getPrice());
                            nuevoItem.setUnidades(cantidad);
                            nuevoItem.setCant(String.valueOf(cantidad));
                            itemsActualizados.add(nuevoItem);
                        } else if (cantidad != null && cantidad > 0 && existingItemsMap.containsKey(platilloId)) {

                            ItemPedido itemExistente = existingItemsMap.get(platilloId);
                            itemExistente.setUnidades(itemExistente.getUnidades() + cantidad);
                            itemExistente.setCant(String.valueOf(itemExistente.getUnidades()));
                            if (!itemsActualizados.contains(itemExistente)) {
                                itemsActualizados.add(itemExistente);
                            }
                        }
                    }
                }
            }

            pedido.setItems(itemsActualizados);
            pedido.setTotal(calcularTotal(itemsActualizados));
            pedidoRep.save(pedido);
            actualizarEstadoMesa(mesa, pedidoId, pedido.getMeseroId());

            return "redirect:/pedidos?exito=Pedido+editado+correctamente";

        } catch (IllegalArgumentException e) {
            model.addAttribute("error", "Error al editar el pedido: " + e.getMessage());
            recargarDatosModeloParaEdicion(model, pedidoRep.findById(pedidoId).orElse(new Pedido()));
            return "pedido-editar";
        } catch (Exception e) {
            model.addAttribute("error", "Error inesperado al editar el pedido: " + e.getMessage());
            recargarDatosModeloParaEdicion(model, pedidoRep.findById(pedidoId).orElse(new Pedido()));
            return "pedido-editar";
        }
    }

    private void recargarDatosModeloParaEdicion(Model model, Pedido pedido) {
        model.addAttribute("pedido", pedido);
        if (pedido.getMesaId() != null) {
            model.addAttribute("mesaActual", mesaRep.findById(pedido.getMesaId()).orElse(null));
        } else {
            model.addAttribute("mesaActual", null);
        }
        Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
        model.addAttribute("mesas",
                (restaurantId != null) ? mesaRep.findByRestaurantId(restaurantId) : Collections.emptyList());
        model.addAttribute("platillosDisponibles",
                (restaurantId != null) ? platilloRep.findByRestaurantId(restaurantId) : Collections.emptyList());
        List<User> meseros = (restaurantId != null) ? userRep.findMeserosByRestaurantId(restaurantId)
                : Collections.emptyList();
        model.addAttribute("meseros", meseros);
    }

    @PostMapping
    public String guardarPedido(@ModelAttribute("pedido") Pedido pedido,
            BindingResult result,
            @RequestParam(name = "platillosSeleccionados", required = false) List<String> platillosSeleccionadosIds,
            @RequestParam Map<String, String> allParams,
            Model model) {
        boolean esEdicion = pedido.getId() != null && !pedido.getId().isEmpty();
        if (platillosSeleccionadosIds == null || platillosSeleccionadosIds.isEmpty()) {
            model.addAttribute("error", "Debe seleccionar al menos un platillo");
            model.addAttribute("modoEdicion", esEdicion);
            return cargarDatosModelo(model, pedido);
        }
        if (result.hasErrors()) {
            model.addAttribute("error", "Errores de binding detectados.");
            model.addAttribute("modoEdicion", esEdicion);
            return cargarDatosModelo(model, pedido);
        }

        try {
            Mesa mesa = mesaRep.findById(pedido.getMesaId())
                    .orElseThrow(() -> new IllegalArgumentException("Mesa no encontrada"));
            User mesero = userRep.findById(pedido.getMeseroId())
                    .orElseThrow(() -> new IllegalArgumentException("Mesero no encontrado"));

            List<ItemPedido> items = new ArrayList<>();
            for (String platilloId : platillosSeleccionadosIds) {
                String cantidadStr = allParams.get("cantidad_" + platilloId);
                int cantidad = parseCantidad(cantidadStr);
                Platillo platillo = platilloRep.findById(platilloId)
                        .orElseThrow(() -> new IllegalArgumentException("Platillo no encontrado: " + platilloId));
                ItemPedido item = new ItemPedido();
                item.setName(platillo.getName());
                item.setCant(String.valueOf(cantidad));
                item.setPrice(platillo.getPrice());
                item.setProductId(platilloId);
                item.setUnidades(cantidad);
                items.add(item);
            }

            if (esEdicion) {
                return actualizarPedidoExistente(pedido, mesa, mesero, platillosSeleccionadosIds, allParams, model);
            } else {
                return crearNuevoPedido(pedido, mesa, mesero, platillosSeleccionadosIds, allParams, model);
            }

        } catch (IllegalArgumentException e) {
            model.addAttribute("error", "Error al guardar el pedido: " + e.getMessage());
            model.addAttribute("modoEdicion", esEdicion);
            return cargarDatosModelo(model, pedido);
        } catch (Exception e) {
            model.addAttribute("error", "Error inesperado al guardar el pedido: " + e.getMessage());
            model.addAttribute("modoEdicion", esEdicion);
            return cargarDatosModelo(model, pedido);
        }
    }

    private List<Pedido> getPedidosConDetalles() {
        Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
        List<Pedido> pedidos = (restaurantId != null)
                ? pedidoRep.findTop5ByRestaurantIdOrderByFechaDesc(restaurantId)
                : Collections.emptyList();

        return pedidos.stream()
                .map(pedido -> {
                    if (pedido.getMesaId() != null) {
                        Mesa mesa = mesaRep.findById(pedido.getMesaId()).orElse(new Mesa());
                        pedido.setMesaNum(mesa.getNum());
                    }
                    if (pedido.getMeseroId() != null) {
                        User mesero = userRep.findById(pedido.getMeseroId()).orElse(new User());
                        pedido.setMeseroName(mesero.getName());
                    }
                    return pedido;
                })
                .collect(Collectors.toList());
    }

    private String validarDatos(Pedido pedido, List<String> platillosIds) {
        if (pedido.getMesaId() == null || pedido.getMesaId().isEmpty())
            return "Debe seleccionar una mesa";
        if (pedido.getMeseroId() == null || pedido.getMeseroId().isEmpty())
            return "Debe seleccionar un mesero";
        return null;
    }

    private int parseCantidad(String cantidadStr) {
        try {
            int cantidad = Integer.parseInt(cantidadStr);
            return Math.max(cantidad, 1);
        } catch (NumberFormatException e) {
            return 1;
        }
    }

    private void actualizarEstadoMesa(Mesa mesa, String pedidoId, String meseroId) {
        if (mesa.getPedidosId() == null) {
            mesa.setPedidosId(new ArrayList<>());
        }
        if (!mesa.getPedidosId().contains(pedidoId)) {
            mesa.getPedidosId().add(pedidoId);
        }
        mesa.setOcupado(true);
        if (meseroId != null && !meseroId.isEmpty()) {
            mesa.setMeseroId(meseroId);
        }
        mesaRep.save(mesa);
    }

    private double calcularTotal(List<ItemPedido> items) {
        if (items == null) {
            return 0.0;
        }
        return items.stream()
                .mapToDouble(item -> (item.getPrice() != null ? item.getPrice() : 0.0)
                        * (item.getUnidades() != null ? item.getUnidades() : 0))
                .sum();
    }

    private String actualizarPedidoExistente(Pedido pedidoForm, Mesa mesa, User mesero,
            List<String> platillosIds, Map<String, String> allParams, Model model) {
        Pedido pedidoExistente = pedidoRep.findById(pedidoForm.getId())
                .orElseThrow(() -> new IllegalArgumentException("Pedido no encontrado para actualizar"));

        pedidoExistente.setMesaId(mesa.getId());
        pedidoExistente.setMesaNum(mesa.getNum());
        pedidoExistente.setMeseroId(String.valueOf(mesero.getId()));
        pedidoExistente.setMeseroName(mesero.getName());
        pedidoExistente.setFecha(LocalDateTime.now());

        List<ItemPedido> items = new ArrayList<>();
        if (platillosIds != null) {
            for (String platilloId : platillosIds) {
                String cantidadStr = allParams.get("cantidad_" + platilloId);
                int cantidad = parseCantidad(cantidadStr);
                Platillo platillo = platilloRep.findById(platilloId)
                        .orElseThrow(() -> new IllegalArgumentException("Platillo no encontrado: " + platilloId));
                ItemPedido item = new ItemPedido();
                item.setName(platillo.getName());
                item.setCant(String.valueOf(cantidad));
                item.setPrice(platillo.getPrice());
                item.setProductId(platilloId);
                item.setUnidades(cantidad);
                items.add(item);
            }
        }
        if (items.isEmpty()) {
            model.addAttribute("error", "Un pedido debe tener al menos un platillo.");
            cargarDatosModelo(model, pedidoExistente);
            model.addAttribute("modoEdicion", true);
            return "pedido";
        }

        pedidoExistente.setItems(items);
        pedidoExistente.setTotal(calcularTotal(items));
        pedidoRep.save(pedidoExistente);
        actualizarEstadoMesa(mesa, pedidoExistente.getId(), String.valueOf(mesero.getId()));
        return "redirect:/pedidos?exito=Pedido+editado+correctamente";
    }

    private String crearNuevoPedido(Pedido pedidoData, Mesa mesa, User mesero,
            List<String> platillosIds, Map<String, String> allParams, Model model) {
        Pedido nuevoPedido = new Pedido();
        Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
        nuevoPedido.setRestaurantId(restaurantId);
        nuevoPedido.setMesaId(mesa.getId());
        nuevoPedido.setMesaNum(mesa.getNum());
        nuevoPedido.setMeseroId(String.valueOf(mesero.getId()));
        nuevoPedido.setMeseroName(mesero.getName());
        nuevoPedido.setFecha(LocalDateTime.now());

        List<ItemPedido> items = new ArrayList<>();
        if (platillosIds != null) {
            for (String platilloId : platillosIds) {
                String cantidadStr = allParams.get("cantidad_" + platilloId);
                int cantidad = parseCantidad(cantidadStr);
                Platillo platillo = platilloRep.findById(platilloId)
                        .orElseThrow(() -> new IllegalArgumentException("Platillo no encontrado: " + platilloId));
                ItemPedido item = new ItemPedido();
                item.setName(platillo.getName());
                item.setCant(String.valueOf(cantidad));
                item.setPrice(platillo.getPrice());
                item.setProductId(platilloId);
                item.setUnidades(cantidad);
                items.add(item);
            }
        }
        if (items.isEmpty()) {
            model.addAttribute("error", "Un pedido debe tener al menos un platillo.");
            cargarDatosModelo(model, nuevoPedido);
            model.addAttribute("modoEdicion", false);
            return "pedido";
        }

        nuevoPedido.setItems(items);
        nuevoPedido.setTotal(calcularTotal(items));
        Pedido pedidoGuardado = pedidoRep.save(nuevoPedido);
        actualizarEstadoMesa(mesa, pedidoGuardado.getId(), String.valueOf(mesero.getId()));
        return "redirect:/pedidos?exito=Pedido+creado+correctamente";
    }

    private String cargarDatosModelo(Model model, Pedido pedido) {
        model.addAttribute("pedido", pedido);
        Long restaurantId = com.example.rskitchen5.Security.TenantContext.getCurrentRestaurantId();
        if (pedido.getId() == null || pedido.getId().isEmpty()) {
            model.addAttribute("mesas", (restaurantId != null) ? mesaRep.findByRestaurantIdAndOcupadoFalse(restaurantId)
                    : Collections.emptyList());
        } else {
            model.addAttribute("mesas",
                    (restaurantId != null) ? mesaRep.findByRestaurantId(restaurantId) : Collections.emptyList());
            if (pedido.getMesaId() != null) {
                mesaRep.findById(pedido.getMesaId()).ifPresent(mesa -> model.addAttribute("mesaActual", mesa));
            }
        }
        model.addAttribute("platillos",
                (restaurantId != null) ? platilloRep.findByRestaurantId(restaurantId) : Collections.emptyList());
        List<User> meseros = (restaurantId != null) ? userRep.findMeserosByRestaurantId(restaurantId)
                : Collections.emptyList();
        model.addAttribute("meseros", meseros);
        model.addAttribute("pedidosRecientes", getPedidosConDetalles());
        return "pedido";
    }

    @PostMapping("/editar/dto")
    public String procesarEdicion(
            @RequestParam("id") String pedidoId,
            @RequestParam("mesaId") String mesaId,
            @RequestParam(value = "itemsExistentes", required = false) List<String> platillosIds,
            @RequestParam(value = "cantidadesExistentes", required = false) List<Integer> cantidades,
            @RequestParam(value = "nuevosPlatillos", required = false) List<String> nuevosPlatillosIds,
            @RequestParam(value = "nuevasCantidades", required = false) List<Integer> nuevasCantidades,
            Model model) {
        try {
            Pedido pedido = pedidoRep.findById(pedidoId)
                    .orElseThrow(() -> new IllegalArgumentException("Pedido no encontrado"));
            Mesa mesa = mesaRep.findById(mesaId)
                    .orElseThrow(() -> new IllegalArgumentException("Mesa no encontrada"));
            pedido.setMesaId(mesa.getId());
            pedido.setMesaNum(mesa.getNum());
            pedido.setFecha(LocalDateTime.now());

            List<ItemPedido> itemsActualizados = new ArrayList<>();
            if (platillosIds != null && cantidades != null && platillosIds.size() == cantidades.size()) {
                for (int i = 0; i < platillosIds.size(); i++) {
                    String platilloId = platillosIds.get(i);
                    Integer cantidad = cantidades.get(i);
                    if (platilloId != null && !platilloId.isEmpty() && cantidad != null && cantidad > 0) {
                        Platillo platillo = platilloRep.findById(platilloId)
                                .orElseThrow(() -> new IllegalArgumentException("Platillo no encontrado"));
                        ItemPedido item = new ItemPedido();
                        item.setProductId(platillo.getId());
                        item.setName(platillo.getName());
                        item.setPrice(platillo.getPrice());
                        item.setUnidades(cantidad);
                        item.setCant(String.valueOf(cantidad));
                        itemsActualizados.add(item);
                    }
                }
            }

            if (nuevosPlatillosIds != null && nuevasCantidades != null
                    && nuevosPlatillosIds.size() == nuevasCantidades.size()) {
                for (int i = 0; i < nuevosPlatillosIds.size(); i++) {
                    String platilloId = nuevosPlatillosIds.get(i);
                    if (platilloId != null && !platilloId.isEmpty()) {
                        Integer cantidad = nuevasCantidades.get(i);
                        if (cantidad != null && cantidad > 0) {
                            Platillo platillo = platilloRep.findById(platilloId)
                                    .orElseThrow(() -> new IllegalArgumentException("Platillo no encontrado"));
                            Optional<ItemPedido> itemExistente = itemsActualizados.stream()
                                    .filter(item -> item.getProductId().equals(platilloId))
                                    .findFirst();
                            if (itemExistente.isPresent()) {
                                ItemPedido item = itemExistente.get();
                                item.setUnidades(item.getUnidades() + cantidad);
                                item.setCant(String.valueOf(item.getUnidades()));
                            } else {
                                ItemPedido item = new ItemPedido();
                                item.setProductId(platillo.getId());
                                item.setName(platillo.getName());
                                item.setPrice(platillo.getPrice());
                                item.setUnidades(cantidad);
                                item.setCant(String.valueOf(cantidad));
                                itemsActualizados.add(item);
                            }
                        }
                    }
                }
            }
            pedido.setItems(itemsActualizados);
            pedido.setTotal(calcularTotal(itemsActualizados));
            pedidoRep.save(pedido);
            actualizarEstadoMesa(mesa, pedidoId, pedido.getMeseroId());
            return "redirect:/pedidos?exito=Pedido+editado+correctamente";
        } catch (IllegalArgumentException e) {
            model.addAttribute("error", "Error al editar el pedido: " + e.getMessage());
            Pedido pedidoParaRecarga = pedidoRep.findById(pedidoId).orElse(new Pedido());
            recargarDatosModeloParaEdicion(model, pedidoParaRecarga);
            return "pedido-editar";
        } catch (Exception e) {
            model.addAttribute("error", "Error inesperado al editar el pedido: " + e.getMessage());
            Pedido pedidoParaRecarga = pedidoRep.findById(pedidoId).orElse(new Pedido());
            recargarDatosModeloParaEdicion(model, pedidoParaRecarga);
            return "pedido-editar";
        }
    }

    @PostMapping("/editar/guardar")
    public String guardarPedidoEditado(
            @RequestParam String id,
            @RequestParam String mesaId,
            @RequestParam(name = "itemsExistentes", required = false) List<String> itemsExistentes,
            @RequestParam(name = "cantidadesExistentes", required = false) List<Integer> cantidadesExistentes,
            @RequestParam(name = "nuevosPlatillos", required = false) List<String> nuevosPlatillos,
            @RequestParam(name = "nuevasCantidades", required = false) List<Integer> nuevasCantidades,
            Model model,
            RedirectAttributes redirectAttributes) {

        Pedido pedido = pedidoRep.findById(id).orElse(null);
        if (pedido == null) {
            redirectAttributes.addFlashAttribute("error", "Pedido no encontrado para editar.");
            return "redirect:/pedidos";
        }

        Mesa mesaDelPedido = mesaRep.findById(pedido.getMesaId()).orElse(null);
        Mesa mesaParaActualizar = mesaRep.findById(mesaId).orElse(mesaDelPedido);

        if (mesaParaActualizar == null) {
            redirectAttributes.addFlashAttribute("error", "Mesa asociada al pedido no encontrada.");
            return "redirect:/pedidos";
        }
        pedido.setMesaId(mesaParaActualizar.getId());
        pedido.setMesaNum(mesaParaActualizar.getNum());

        List<ItemPedido> itemsActualizados = new ArrayList<>();
        try {
            if (itemsExistentes != null && cantidadesExistentes != null
                    && itemsExistentes.size() == cantidadesExistentes.size()) {
                for (int i = 0; i < itemsExistentes.size(); i++) {
                    String platilloId = itemsExistentes.get(i);
                    Integer cantidad = cantidadesExistentes.get(i);
                    if (platilloId != null && !platilloId.isEmpty() && cantidad != null && cantidad > 0) {
                        Platillo platillo = platilloRep.findById(platilloId)
                                .orElseThrow(() -> new IllegalArgumentException(
                                        "Platillo existente no encontrado: " + platilloId));
                        ItemPedido item = new ItemPedido();
                        item.setProductId(platillo.getId());
                        item.setName(platillo.getName());
                        item.setPrice(platillo.getPrice());
                        item.setUnidades(cantidad);
                        itemsActualizados.add(item);
                    }
                }
            }

            if (nuevosPlatillos != null && nuevasCantidades != null
                    && nuevosPlatillos.size() == nuevasCantidades.size()) {
                for (int i = 0; i < nuevosPlatillos.size(); i++) {
                    String platilloId = nuevosPlatillos.get(i);
                    Integer cantidad = nuevasCantidades.get(i);
                    if (platilloId != null && !platilloId.isEmpty() && cantidad != null && cantidad > 0) {
                        Platillo platillo = platilloRep.findById(platilloId)
                                .orElseThrow(() -> new IllegalArgumentException(
                                        "Platillo nuevo no encontrado: " + platilloId));

                        Optional<ItemPedido> itemYaEnLista = itemsActualizados.stream()
                                .filter(it -> it.getProductId().equals(platilloId))
                                .findFirst();
                        if (itemYaEnLista.isPresent()) {
                            ItemPedido item = itemYaEnLista.get();
                            item.setUnidades(item.getUnidades() + cantidad);
                        } else {
                            ItemPedido item = new ItemPedido();
                            item.setProductId(platillo.getId());
                            item.setName(platillo.getName());
                            item.setPrice(platillo.getPrice());
                            item.setUnidades(cantidad);
                            itemsActualizados.add(item);
                        }
                    }
                }
            }
            pedido.setItems(itemsActualizados);
            pedido.setTotal(calcularTotal(itemsActualizados));
            pedido.setFecha(LocalDateTime.now());

            pedidoRep.save(pedido);
            actualizarEstadoMesa(mesaParaActualizar, pedido.getId(), pedido.getMeseroId());
            redirectAttributes.addFlashAttribute("exito", "Pedido editado y guardado correctamente.");
            return "redirect:/pedidos";

        } catch (IllegalArgumentException e) {
            model.addAttribute("error", "Error al guardar pedido editado: " + e.getMessage());
            recargarDatosModeloParaEdicion(model, pedido);
            return "pedido-editar";
        } catch (Exception e) {
            model.addAttribute("error", "Error inesperado al guardar pedido editado: " + e.getMessage());
            recargarDatosModeloParaEdicion(model, pedido);
            return "pedido-editar";
        }
    }

    @GetMapping("/eliminar/{id}")
    public String eliminarPedido(@PathVariable("id") String id, RedirectAttributes redirectAttributes) {
        try {
            Pedido pedido = pedidoRep.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Pedido no encontrado"));

            Mesa mesa = mesaRep.findById(pedido.getMesaId()).orElse(null);
            if (mesa != null && mesa.getPedidosId() != null) {
                mesa.getPedidosId().remove(pedido.getId());
                if (mesa.getPedidosId().isEmpty()) {
                    mesa.setOcupado(false);
                    mesa.setMeseroId(null);
                }
                mesaRep.save(mesa);
            }

            pedidoRep.delete(pedido);
            redirectAttributes.addFlashAttribute("exito", "Pedido eliminado correctamente");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("error", "Error al eliminar el pedido: " + e.getMessage());
        }
        return "redirect:/pedidos";
    }
}