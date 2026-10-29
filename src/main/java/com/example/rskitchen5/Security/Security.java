package com.example.rskitchen5.Security;

import com.example.rskitchen5.Service.UserDetailsServiceImpl;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

@Configuration
@EnableMethodSecurity(prePostEnabled = true)
public class Security {

    @Autowired
    private UserDetailsServiceImpl userDetailsService;

    @Autowired
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    private AuthenticationEntryPoint apiAwareEntryPoint() {
        return new AuthenticationEntryPoint() {
            @Override
            public void commence(HttpServletRequest request, HttpServletResponse response,
                                 org.springframework.security.core.AuthenticationException authException) throws IOException {
                String path = request.getRequestURI();
                if (path != null && path.startsWith("/api/")) {
                    response.setContentType("application/json");
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.getWriter().write("{\"error\": \"No autorizado\", \"message\": \"" + authException.getMessage() + "\"}");
                } else {
                    response.sendRedirect("/login");
                }
            }
        };
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(ex -> ex.authenticationEntryPoint(apiAwareEntryPoint()))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // Public / Static endpoints y página de error
                        .requestMatchers(
                                "/",
                                "/landing",
                                "/login",
                                "/error",
                                "/css/**",
                                "/js/**",
                                "/img/**",
                                "/images/**",
                                "/weka/**",
                                "/api/auth/**"
                        ).permitAll()
                        // Exclusivo para CREATOR (Super Admin maestro)
                        .requestMatchers("/api/restaurantes", "/api/restaurantes/**", "/admin/restaurantes", "/admin/restaurantes/**").hasAuthority("ROLE_CREATOR")
                        // Protegidos para ADMIN del restaurante y CREATOR
                        .requestMatchers(
                                "/admin/**",
                                "/usuarios",
                                "/usuarios/**",
                                "/mesero",
                                "/mesero/**",
                                "/platillos",
                                "/platillos/**",
                                "/platillo",
                                "/platillo/**",
                                "/producto",
                                "/producto/**",
                                "/productos",
                                "/productos/**"
                        ).hasAnyAuthority("ROLE_ADMIN", "ROLE_CREATOR")
                        // Protegidos para ADMIN, MESEROS y CREATOR
                        .requestMatchers(
                                "/home",
                                "/start",
                                "/mesa",
                                "/mesa/**",
                                "/pedido",
                                "/pedido/**",
                                "/pedidos",
                                "/pedidos/**",
                                "/factura",
                                "/factura/**",
                                "/pagos",
                                "/pagos/**",
                                "/datos",
                                "/datos/**",
                                "/foro",
                                "/foro/**"
                        ).hasAnyAuthority("ROLE_ADMIN", "ROLE_MESERO", "ROLE_CREATOR")
                        .requestMatchers("/api/**").authenticated()
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public AuthenticationManager authenticationManager(HttpSecurity http,
                                                       BCryptPasswordEncoder bCryptPasswordEncoder) throws Exception {
        AuthenticationManagerBuilder authenticationManagerBuilder =
                http.getSharedObject(AuthenticationManagerBuilder.class);
        authenticationManagerBuilder.userDetailsService(userDetailsService)
                .passwordEncoder(bCryptPasswordEncoder);
        return authenticationManagerBuilder.build();
    }

    @Bean
    public BCryptPasswordEncoder bCryptPasswordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
