package com.example.rskitchen5.Service;

import com.example.rskitchen5.Model.Restaurant;
import com.example.rskitchen5.Model.User;
import com.example.rskitchen5.Repository.RestaurantRep;
import com.example.rskitchen5.Repository.UserRep;
import com.example.rskitchen5.Security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.Optional;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    @Autowired
    private UserRep userRep;

    @Autowired
    private RestaurantRep restaurantRep;

    @Override
    public UserDetails loadUserByUsername(String mail) throws UsernameNotFoundException {
        // 1. Verificar si es una cuenta de Restaurant (Admin del restaurante)
        if (restaurantRep != null) {
            Optional<Restaurant> restaurantOpt = restaurantRep.findByCorreo(mail);
            if (restaurantOpt.isPresent()) {
                Restaurant r = restaurantOpt.get();
                if (!r.isActivo()) {
                    throw new org.springframework.security.authentication.DisabledException("El restaurante se encuentra desactivado.");
                }
                return new UserPrincipal(
                        r.getCorreo(),
                        r.getContraseña(),
                        "ADMIN",
                        r.getId(),
                        r.getNombre(),
                        Collections.singleton(new SimpleGrantedAuthority("ROLE_ADMIN"))
                );
            }
        }

        // 2. Verificar si es un Usuario (CREATOR o empleado como MESERO)
        User user = userRep.findByMail(mail)
                .orElseThrow(() -> new UsernameNotFoundException("Usuario o restaurante no encontrado con mail: " + mail));

        if (!user.isActivo()) {
            throw new org.springframework.security.authentication.DisabledException("El usuario o empleado se encuentra desactivado.");
        }

        String roleStr = user.getRol() != null ? user.getRol().toUpperCase() : "MESERO";
        String authority = roleStr.startsWith("ROLE_") ? roleStr : "ROLE_" + roleStr;
        String rawRole = roleStr.startsWith("ROLE_") ? roleStr.substring(5) : roleStr;

        return new UserPrincipal(
                user.getMail(),
                user.getPassword(),
                rawRole,
                user.getRestaurantId(),
                user.getName(),
                Collections.singleton(new SimpleGrantedAuthority(authority))
        );
    }
}
