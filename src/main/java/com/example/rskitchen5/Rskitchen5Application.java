package com.example.rskitchen5;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;

@SpringBootApplication
@EnableMethodSecurity
public class Rskitchen5Application {

	public static void main(String[] args) {
		SpringApplication.run(Rskitchen5Application.class, args);
	}

}
