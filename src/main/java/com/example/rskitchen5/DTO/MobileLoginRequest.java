package com.example.rskitchen5.DTO;

import com.fasterxml.jackson.annotation.JsonAlias;

public class MobileLoginRequest {

    @JsonAlias({"correo", "email"})
    private String mail;

    @JsonAlias({"contraseña", "clave"})
    private String password;

    public MobileLoginRequest() {
    }

    public MobileLoginRequest(String mail, String password) {
        this.mail = mail;
        this.password = password;
    }

    public String getMail() {
        return mail;
    }

    public void setMail(String mail) {
        this.mail = mail;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String resolveEmail() {
        return mail != null ? mail.trim() : "";
    }

    public String resolvePassword() {
        return password != null ? password : "";
    }
}

