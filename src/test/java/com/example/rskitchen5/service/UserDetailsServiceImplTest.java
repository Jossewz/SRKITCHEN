package com.example.rskitchen5.service;

import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.UserRep;
import com.example.rskitchen5.Service.UserDetailsServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserDetailsServiceImplTest {

    @Mock
    private UserRep userRep;

    @Mock
    private com.example.rskitchen5.Repository.RestaurantRep restaurantRep;

    @InjectMocks
    private UserDetailsServiceImpl userDetailsService;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        sampleUser = new User();
        sampleUser.setId(1L);
        sampleUser.setName("Juan Pérez");
        sampleUser.setMail("juan@rskitchen.com");
        sampleUser.setPassword("$2a$10$hashedpassword");
        sampleUser.setRol("ROLE_ADMIN");
    }

    @Test
    @DisplayName("Debe cargar UserDetails correctamente para usuario existente con ROLE_ADMIN")
    void testLoadUserByUsername_Success_Admin() {
        when(userRep.findByMail("juan@rskitchen.com")).thenReturn(Optional.of(sampleUser));

        UserDetails userDetails = userDetailsService.loadUserByUsername("juan@rskitchen.com");

        assertNotNull(userDetails);
        assertEquals("juan@rskitchen.com", userDetails.getUsername());
        assertEquals("$2a$10$hashedpassword", userDetails.getPassword());
        assertTrue(userDetails.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN")));
        verify(userRep, times(1)).findByMail("juan@rskitchen.com");
    }

    @Test
    @DisplayName("Debe agregar prefijo ROLE_ si el rol almacenado no lo tiene")
    void testLoadUserByUsername_Success_PrefixRole() {
        sampleUser.setRol("MESERO");
        when(userRep.findByMail("juan@rskitchen.com")).thenReturn(Optional.of(sampleUser));

        UserDetails userDetails = userDetailsService.loadUserByUsername("juan@rskitchen.com");

        assertNotNull(userDetails);
        assertTrue(userDetails.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_MESERO")));
    }

    @Test
    @DisplayName("Debe asignar ROLE_USER si el rol es null")
    void testLoadUserByUsername_Success_NullRoleDefaultsToRoleUser() {
        sampleUser.setRol(null);
        when(userRep.findByMail("juan@rskitchen.com")).thenReturn(Optional.of(sampleUser));

        UserDetails userDetails = userDetailsService.loadUserByUsername("juan@rskitchen.com");

        assertNotNull(userDetails);
        assertTrue(userDetails.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_USER")));
    }

    @Test
    @DisplayName("Debe lanzar UsernameNotFoundException si el usuario no existe")
    void testLoadUserByUsername_NotFound() {
        when(userRep.findByMail("noexiste@rskitchen.com")).thenReturn(Optional.empty());

        assertThrows(UsernameNotFoundException.class, () -> {
            userDetailsService.loadUserByUsername("noexiste@rskitchen.com");
        });
        verify(userRep, times(1)).findByMail("noexiste@rskitchen.com");
    }

    @Test
    @DisplayName("Debe lanzar UsernameNotFoundException si las credenciales están vacías")
    void testLoadUserByUsername_EmptyCredentials() {
        sampleUser.setPassword("");
        when(userRep.findByMail("juan@rskitchen.com")).thenReturn(Optional.of(sampleUser));

        assertThrows(UsernameNotFoundException.class, () -> {
            userDetailsService.loadUserByUsername("juan@rskitchen.com");
        });
    }
}
