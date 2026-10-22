package com.example.rskitchen5.DTO;

public class AuthResponse {

    private String token;
    private String type = "Bearer";
    private String email;
    private String role;
    private Long restaurant_id;
    private String nombre;

    public AuthResponse() {
    }

    public AuthResponse(String token, String email, String role, Long restaurant_id, String nombre) {
        this.token = token;
        this.type = "Bearer";
        this.email = email;
        this.role = role;
        this.restaurant_id = restaurant_id;
        this.nombre = nombre;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public Long getRestaurant_id() {
        return restaurant_id;
    }

    public void setRestaurant_id(Long restaurant_id) {
        this.restaurant_id = restaurant_id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }
}
