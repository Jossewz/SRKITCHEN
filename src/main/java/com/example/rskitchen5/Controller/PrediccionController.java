package com.example.rskitchen5.Controller;

import com.example.rskitchen5.DTO.DemandaDiariaDTO;
import com.example.rskitchen5.DTO.PrediccionResponseDTO;
import com.example.rskitchen5.DTO.RankingHistoricoDTO;
import com.example.rskitchen5.Model.Restaurant;
import com.example.rskitchen5.Repository.RestaurantRep;
import com.example.rskitchen5.Security.TenantContext;
import com.example.rskitchen5.Security.UserPrincipal;
import com.example.rskitchen5.Service.PrediccionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@Controller
@RequestMapping("/prediccion")
@PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'ROLE_CREATOR')")
public class PrediccionController {

    @Autowired
    private PrediccionService prediccionService;

    @Autowired
    private RestaurantRep restaurantRep;

    @GetMapping
    public String verPrediccion(
            @RequestParam(name = "fecha", required = false) String fecha,
            @RequestParam(name = "dias", required = false, defaultValue = "7") int dias,
            @RequestParam(name = "restaurantId", required = false) Long restaurantIdParam,
            Model model) {

        if (fecha == null || fecha.trim().isEmpty()) {
            fecha = "2026-11-01";
        }

        if (dias != 7 && dias != 14) {
            dias = 7;
        }

        UserPrincipal principal = TenantContext.getCurrentUser();
        Long effectiveRestaurantId = null;
        boolean esSuperAdmin = false;

        if (principal != null) {
            if ("CREATOR".equalsIgnoreCase(principal.getRole()) || "ROLE_CREATOR".equalsIgnoreCase(principal.getRole())) {
                esSuperAdmin = true;
                effectiveRestaurantId = (restaurantIdParam != null && restaurantIdParam > 0) ? restaurantIdParam : 1L;
            } else {
                effectiveRestaurantId = principal.getRestaurantId();
                if (effectiveRestaurantId == null) {
                    effectiveRestaurantId = 1L;
                }
            }
        } else {
            effectiveRestaurantId = (restaurantIdParam != null) ? restaurantIdParam : 1L;
        }

        Restaurant rest = null;
        if (effectiveRestaurantId != null) {
            rest = restaurantRep.findById(effectiveRestaurantId).orElse(null);
        }

        List<Restaurant> todosLosRestaurantes = restaurantRep.findAll();

        PrediccionResponseDTO proyeccion = prediccionService.obtenerPrediccion(fecha, dias, effectiveRestaurantId);
        DemandaDiariaDTO demandaDiaria = prediccionService.obtenerDemandaDiaria(dias, effectiveRestaurantId);
        RankingHistoricoDTO historico = prediccionService.obtenerRankingHistorico();

        model.addAttribute("activePage", "prediccion");
        model.addAttribute("proyeccion", proyeccion);
        model.addAttribute("demandaDiaria", demandaDiaria);
        model.addAttribute("historico", historico);
        model.addAttribute("fechaSeleccionada", fecha);
        model.addAttribute("diasSeleccionados", dias);
        model.addAttribute("apiDisponible", proyeccion.isApiDisponible());
        model.addAttribute("mlApiUrl", prediccionService.getMlApiUrl());

        model.addAttribute("esSuperAdmin", esSuperAdmin);
        model.addAttribute("restauranteActual", rest);
        model.addAttribute("nombreRestaurante", rest != null ? rest.getNombre() : "Restaurante #" + effectiveRestaurantId);
        model.addAttribute("restaurantIdActual", effectiveRestaurantId);
        model.addAttribute("listaRestaurantes", todosLosRestaurantes);

        return "prediccion";
    }
}
