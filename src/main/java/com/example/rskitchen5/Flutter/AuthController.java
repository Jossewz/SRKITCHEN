package com.example.rskitchen5.Flutter;

import com.example.rskitchen5.DTO.AuthResponse;
import com.example.rskitchen5.Security.JwtService;
import com.example.rskitchen5.Security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtService jwtService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getMail(), request.getPassword())
            );

            UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();

            String token = jwtService.generateToken(
                    principal.getUsername(),
                    principal.getRole(),
                    principal.getRestaurantId(),
                    principal.getNombre()
            );

            AuthResponse response = new AuthResponse(
                    token,
                    principal.getUsername(),
                    principal.getRole(),
                    principal.getRestaurantId(),
                    principal.getNombre()
            );

            return ResponseEntity.ok(response);
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Credenciales inválidas"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage() != null ? e.getMessage() : "Error en autenticación"));
        }
    }
}
