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
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

@Configuration
public class Security {

    @Autowired
    private UserDetailsServiceImpl userDetailsService;

    /**
     * Custom entry point that returns 401 for API requests (paths starting with /api/)
     * and falls back to redirect to form login for non-API requests (Thymeleaf web).
     */

    private AuthenticationEntryPoint apiAwareEntryPoint() {
        return new AuthenticationEntryPoint() {
            @Override
            public void commence(HttpServletRequest request, HttpServletResponse response,
                                 org.springframework.security.core.AuthenticationException authException) throws IOException {
                String path = request.getRequestURI();
                if (path != null && path.startsWith("/api/")) {
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
                } else {
                    // fallback to default behaviour (redirect to login page)
                    response.sendRedirect("/login");
                }
            }
        };
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // apply CORS config from corsConfigurationSource()
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                // disable CSRF for API endpoints (make sure form login still works)
                .csrf(csrf -> csrf.ignoringRequestMatchers("/api/**"))
                // Exception handling: return 401 JSON for API unauthenticated requests
                .exceptionHandling(ex -> ex.authenticationEntryPoint(apiAwareEntryPoint()))
                .authorizeHttpRequests(auth -> auth
                        // Allow preflight OPTIONS for everyone
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // Public/static and API endpoints (adjust as needed)
                        .requestMatchers(
                                "/",
                                "/landing",
                                "/login",
                                "/css/**",
                                "/js/**",
                                "/img/**",
                                "/images/**",
                                "/datos/**",
                                "/weka/**",
                                "/api/auth/**",
                                "/api/**"
                        ).permitAll()
                        // protected routes
                        .requestMatchers("/mesa/**", "/pedido/**", "/pedidos/**", "/factura/**", "/pagos/**")
                        .hasAnyAuthority("ROLE_ADMIN", "ROLE_MESERO")
                        .requestMatchers("/admin/**", "/mesero/**", "/platillos/**", "/producto/**")
                        .hasAuthority("ROLE_ADMIN")
                        .anyRequest().authenticated()
                )
                // keep form login for Thymeleaf web
                .formLogin(form -> form
                        .loginPage("/login")
                        .loginProcessingUrl("/login")
                        .defaultSuccessUrl("/home", true)
                        .failureUrl("/login?error=true")
                        .permitAll()
                )
                .logout(logout -> logout
                        .logoutUrl("/logout")
                        .logoutSuccessUrl("/login?logout=true")
                        .permitAll()
                );

        return http.build();
    }

    /**
     * CORS configuration tuned for development with Flutter Web.
     * - allowedOriginPatterns("*") allows dynamic origins (needed when using credentials + multiple localhost ports).
     * - allowCredentials may be true if you plan to rely on cookies; if not using cookies, you can set it to false.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        // Use allowedOriginPatterns to be flexible during dev (avoids issues with exact origin matching)
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        // If your API uses cookies/sessions from the browser, set to true. If not, false is safer.
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
