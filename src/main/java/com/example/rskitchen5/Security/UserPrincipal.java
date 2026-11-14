package com.example.rskitchen5.Security;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;

public class UserPrincipal implements UserDetails {

    private final String email;
    private final String password;
    private final String role;
    private final Long restaurantId;
    private final String nombre;
    private final Collection<? extends GrantedAuthority> authorities;

    public UserPrincipal(String email, String password, String role, Long restaurantId, String nombre, Collection<? extends GrantedAuthority> authorities) {
        this.email = email;
        this.password = password;
        this.role = role;
        this.restaurantId = restaurantId;
        this.nombre = nombre;
        this.authorities = authorities;
    }

    public Long getRestaurantId() {
        return restaurantId;
    }

    public String getRole() {
        return role;
    }

    public String getNombre() {
        return nombre;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}
