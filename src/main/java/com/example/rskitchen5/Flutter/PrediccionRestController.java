package com.example.rskitchen5.Flutter;

import com.example.rskitchen5.DTO.DemandaDiariaDTO;
import com.example.rskitchen5.DTO.PrediccionResponseDTO;
import com.example.rskitchen5.DTO.RankingHistoricoDTO;
import com.example.rskitchen5.Security.TenantContext;
import com.example.rskitchen5.Security.UserPrincipal;
import com.example.rskitchen5.Service.PrediccionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*")
public class PrediccionRestController {

    @Autowired
    private PrediccionService prediccionService;

    @GetMapping({"/api/prediccion", "/api/mobile/prediccion"})
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'ROLE_CREATOR')")
    public ResponseEntity<PrediccionResponseDTO> obtenerPrediccion(
            @RequestParam(name = "fecha", required = false, defaultValue = "2026-11-01") String fecha,
            @RequestParam(name = "dias", required = false, defaultValue = "7") int dias,
            @RequestParam(name = "restaurantId", required = false) Long restaurantIdParam) {

        UserPrincipal principal = TenantContext.getCurrentUser();
        Long effectiveRestaurantId = null;

        if (principal != null && !"CREATOR".equalsIgnoreCase(principal.getRole()) && !"ROLE_CREATOR".equalsIgnoreCase(principal.getRole())) {
            effectiveRestaurantId = principal.getRestaurantId();
        } else {
            effectiveRestaurantId = restaurantIdParam != null ? restaurantIdParam : 1L;
        }

        PrediccionResponseDTO dto = prediccionService.obtenerPrediccion(fecha, dias, effectiveRestaurantId);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/api/prediccion/demanda-diaria")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'ROLE_CREATOR')")
    public ResponseEntity<DemandaDiariaDTO> obtenerDemandaDiaria(
            @RequestParam(name = "dias", required = false, defaultValue = "14") int dias,
            @RequestParam(name = "restaurantId", required = false) Long restaurantIdParam) {

        UserPrincipal principal = TenantContext.getCurrentUser();
        Long effectiveRestaurantId = (principal != null && principal.getRestaurantId() != null)
                ? principal.getRestaurantId()
                : (restaurantIdParam != null ? restaurantIdParam : 1L);

        DemandaDiariaDTO dto = prediccionService.obtenerDemandaDiaria(dias, effectiveRestaurantId);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/api/prediccion/ranking-historico")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN', 'ROLE_CREATOR')")
    public ResponseEntity<RankingHistoricoDTO> obtenerRankingHistorico() {
        RankingHistoricoDTO dto = prediccionService.obtenerRankingHistorico();
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/api/prediccion/health")
    public ResponseEntity<?> verificarSalud() {
        boolean ok = prediccionService.verificarSaludApi();
        return ResponseEntity.ok().body(java.util.Map.of(
                "mlMicroservice", ok ? "UP" : "DOWN",
                "mlApiUrl", prediccionService.getMlApiUrl()
        ));
    }
}
