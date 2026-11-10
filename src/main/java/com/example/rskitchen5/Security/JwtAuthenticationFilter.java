package com.example.rskitchen5.Security;

import com.example.rskitchen5.Model.Restaurant;
import com.example.rskitchen5.Repository.RestaurantRep;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
import java.util.List;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private JwtService jwtService;

    @Autowired
    private RestaurantRep restaurantRep;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String jwt = null;

        // 1. Intentar leer JWT del header Authorization (API / HTMX)
        final String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            jwt = authHeader.substring(7);
        }

        // 2. Intentar leer JWT de la cookie rskitchen_jwt (navegación de página completa)
        if (jwt == null) {
            jakarta.servlet.http.Cookie[] cookies = request.getCookies();
            if (cookies != null) {
                for (jakarta.servlet.http.Cookie cookie : cookies) {
                    if ("rskitchen_jwt".equals(cookie.getName())) {
                        jwt = cookie.getValue();
                        break;
                    }
                }
            }
        }

        if (jwt == null) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            if (jwtService.isTokenValid(jwt) && SecurityContextHolder.getContext().getAuthentication() == null) {
                String email = jwtService.extractEmail(jwt);
                String role = jwtService.extractRole(jwt);
                Long restaurantId = jwtService.extractRestaurantId(jwt);
                String nombre = (String) jwtService.extractAllClaims(jwt).get("nombre");

                // Si está asociado a un restaurante y no es CREATOR, validar que el restaurante siga activo
                if (restaurantId != null && !"CREATOR".equalsIgnoreCase(role) && !"ROLE_CREATOR".equalsIgnoreCase(role) && restaurantRep != null) {
                    java.util.Optional<Restaurant> restOpt = restaurantRep.findById(restaurantId);
                    if (restOpt.isEmpty() || !restOpt.get().isActivo()) {
                        filterChain.doFilter(request, response);
                        return;
                    }
                }

                if (role == null) {
                    role = "USER";
                }
                String roleAuthority = role.toUpperCase().startsWith("ROLE_")
                        ? role.toUpperCase()
                        : "ROLE_" + role.toUpperCase();

                List<SimpleGrantedAuthority> authorities = Collections.singletonList(new SimpleGrantedAuthority(roleAuthority));

                UserPrincipal principal = new UserPrincipal(
                        email,
                        "",
                        role,
                        restaurantId,
                        nombre,
                        authorities
                );

                UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                        principal,
                        null,
                        authorities
                );
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        } catch (Exception e) {
            logger.error("Error al procesar token JWT: " + e.getMessage());
        }

        filterChain.doFilter(request, response);
    }
}
