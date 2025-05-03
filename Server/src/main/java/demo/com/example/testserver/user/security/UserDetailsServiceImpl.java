package demo.com.example.testserver.user.security;

import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.UserRepository; // Correct import path
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.Collections;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    @Autowired
    UserRepository userRepository;

    @Override
    @Transactional // Important for lazy loading roles/authorities if needed later
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(email) // Find by email, which is our username
                .orElseThrow(() -> new UsernameNotFoundException("User Not Found with email: " + email));

        // Check if user is active
        if (user.getStatus() != User.UserStatus.kich_hoat) {
             throw new UsernameNotFoundException("User is not active: " + email);
        }

        // Create authorities (roles)
        // Prefix roles with "ROLE_" as per Spring Security convention
        Collection<? extends GrantedAuthority> authorities =
                Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + user.getRole().name().toUpperCase()));


        // Return Spring Security's User object
        return new org.springframework.security.core.userdetails.User(
                user.getEmail(),
                user.getPassword(), // Provide the hashed password
                authorities);
    }
}
