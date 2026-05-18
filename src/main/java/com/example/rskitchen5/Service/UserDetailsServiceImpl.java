package com.example.rskitchen5.Service;

import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.UserRep;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Collections;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    @Autowired
    private UserRep userRep;

    @Override
    public UserDetails loadUserByUsername(String mail) throws UsernameNotFoundException {
        User user = userRep.findByMail(mail)
                .orElseThrow(() -> new UsernameNotFoundException("Usuario no encontrado con mail: " + mail));

        if (user.getMail() == null || user.getMail().trim().isEmpty() || user.getPassword() == null || user.getPassword().trim().isEmpty()) {
            throw new UsernameNotFoundException("Usuario con datos incompletos en la base de datos");
        }

        String roleStr = user.getRol() != null ? user.getRol().toUpperCase() : "USER";
        String authority = roleStr.startsWith("ROLE_")
                ? roleStr
                : "ROLE_" + roleStr;

        return new org.springframework.security.core.userdetails.User(
                user.getMail(),
                user.getPassword(),
                Collections.singleton(new SimpleGrantedAuthority(authority))
        );
    }
}
