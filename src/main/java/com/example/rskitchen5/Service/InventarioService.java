package com.example.rskitchen5.Service;

import com.example.rskitchen5.Model.*;
import com.example.rskitchen5.Repository.PlatilloIngredienteRep;
import com.example.rskitchen5.Repository.PlatilloRep;
import com.example.rskitchen5.Repository.ProductoRep;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
@Transactional
public class InventarioService {

    private static final Logger log = LoggerFactory.getLogger(InventarioService.class);

    @Autowired
    private ProductoRep productoRep;

    @Autowired
    private PlatilloRep platilloRep;

    @Autowired
    private PlatilloIngredienteRep platilloIngredienteRep;

    /**
     * Descuenta del inventario los ingredientes requeridos por todos los platillos
     * incluidos en la factura.
     */
    public void descontarStockPorFactura(Factura factura) {
        if (factura == null)
            return;
        List<ItemPedido> items = factura.getItems();
        if (items != null && !items.isEmpty()) {
            descontarStockPorItems(items);
        }
    }

    /**
     * Descuenta del inventario los ingredientes requeridos por todos los platillos
     * de un pedido.
     */
    public void descontarStockPorPedido(Pedido pedido) {
        if (pedido == null)
            return;
        List<ItemPedido> items = pedido.getItems();
        if (items != null && !items.isEmpty()) {
            descontarStockPorItems(items);
        }
    }

    /**
     * Procesa una lista de items de pedido, busca la receta de cada platillo y
     * descuenta el stock de sus productos.
     */
    public void descontarStockPorItems(List<ItemPedido> items) {
        if (items == null || items.isEmpty()) {
            return;
        }

        // Mapeo acumulado: Producto ID -> Cantidad total a restar
        Map<Long, Double> deduccionesPorProducto = new HashMap<>();

        for (ItemPedido item : items) {
            if (item == null)
                continue;

            int unidades = (item.getUnidades() != null && item.getUnidades() > 0)
                    ? item.getUnidades()
                    : parseCantidad(item.getCant());
            if (unidades <= 0) {
                unidades = 1;
            }

            Platillo platillo = buscarPlatillo(item);

            if (platillo != null) {
                List<PlatilloIngrediente> ingredientes = platillo.getIngredientes();
                if ((ingredientes == null || ingredientes.isEmpty()) && platillo.getIdLong() != null) {
                    ingredientes = platilloIngredienteRep.findByPlatilloId(platillo.getIdLong());
                }

                if (ingredientes != null && !ingredientes.isEmpty()) {
                    for (PlatilloIngrediente ing : ingredientes) {
                        if (ing.getProducto() != null && ing.getProducto().getIdLong() != null) {
                            Long prodId = ing.getProducto().getIdLong();
                            double cantPorPlato = ing.getCantidad() > 0 ? ing.getCantidad() : 1.0;
                            double cantTotal = cantPorPlato * unidades;
                            deduccionesPorProducto.merge(prodId, cantTotal, Double::sum);
                        }
                    }
                }
            } else if (item.getProductId() != null && !item.getProductId().isBlank()) {
                // Si el item correspondía directamente a un Producto de inventario
                try {
                    Long prodId = Long.parseLong(item.getProductId().trim());
                    if (productoRep.existsById(prodId)) {
                        deduccionesPorProducto.merge(prodId, (double) unidades, Double::sum);
                    }
                } catch (NumberFormatException ignored) {
                }
            }
        }

        // Aplicar los descuentos calculados al stock de cada producto
        for (Map.Entry<Long, Double> entry : deduccionesPorProducto.entrySet()) {
            Long productoId = entry.getKey();
            double totalADescontar = entry.getValue();

            int unidadesADescontar = (int) Math.round(totalADescontar);
            if (unidadesADescontar < 1 && totalADescontar > 0) {
                unidadesADescontar = 1;
            }
            final int descuentoFinal = unidadesADescontar;

            productoRep.findById(productoId).ifPresent(prod -> {
                int stockAnterior = prod.getStock();
                int nuevoStock = Math.max(0, stockAnterior - descuentoFinal);
                prod.setStock(nuevoStock);
                productoRep.save(prod);
                log.info("Stock descontado para producto '{}' (ID {}): anterior={}, descontado={}, nuevo={}",
                        prod.getName(), productoId, stockAnterior, descuentoFinal, nuevoStock);
            });
        }
    }

    private Platillo buscarPlatillo(ItemPedido item) {
        String platilloId = item.getProductId();
        if (platilloId != null && !platilloId.isBlank()) {
            Optional<Platillo> opt = platilloRep.findById(platilloId);
            if (opt.isPresent())
                return opt.get();
        }

        if (item.getName() != null && !item.getName().isBlank()) {
            String nombre = item.getName().trim();
            return platilloRep.findAll().stream()
                    .filter(p -> p.getName() != null && p.getName().equalsIgnoreCase(nombre))
                    .findFirst()
                    .orElse(null);
        }

        return null;
    }

    private int parseCantidad(String cant) {
        if (cant == null || cant.isBlank())
            return 1;
        try {
            return Integer.parseInt(cant.trim());
        } catch (NumberFormatException e) {
            return 1;
        }
    }
}
