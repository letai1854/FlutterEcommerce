package demo.com.example.testserver.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity; // Enable method security
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy; // Import SessionCreationPolicy
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter; // Import filter

import demo.com.example.testserver.user.security.JwtAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity // Enable @PreAuthorize, @PostAuthorize, etc.
public class SecurityConfig {
    @Autowired
    private JwtAuthenticationFilter jwtAuthenticationFilter; // Inject JWT filter

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration) throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable) // Disable CSRF for stateless APIs
            // Configure session management to be stateless
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(authz -> authz
                // Public endpoints
                .requestMatchers("/api/users/ping").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/users/login").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/users/register").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/users/forgot-password").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/users/reset-password").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/users/verify-otp").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/users/set-new-password").permitAll()
                // Allow product viewing without login
                .requestMatchers(HttpMethod.GET, "/api/products/**").permitAll()
                // Secure product management - only ADMIN role
                .requestMatchers(HttpMethod.POST, "/api/products/create").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/products/{id}").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/products/{id}").hasRole("ADMIN")
                // Allow public access to categories and brands
                .requestMatchers(HttpMethod.GET, "/api/categories/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/brands/**").permitAll()
                // Image Routes
                .requestMatchers(HttpMethod.GET, "/api/images/**").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/images/upload").authenticated()
                // Secure User Management for ADMIN
                .requestMatchers(HttpMethod.GET, "/api/users").hasRole("ADMIN") // Get all users
                .requestMatchers(HttpMethod.GET, "/api/users/search").hasRole("ADMIN") // New search endpoint
                .requestMatchers(HttpMethod.GET, "/api/users/{id}").hasRole("ADMIN") // Get user by ID (Admin only for now)
                .requestMatchers(HttpMethod.GET, "/api/users/email/{email}").hasRole("ADMIN") // Get user by email
                .requestMatchers(HttpMethod.PUT, "/api/users/{id}").hasRole("ADMIN") // Update user by ID
                .requestMatchers(HttpMethod.DELETE, "/api/users/{id}").hasRole("ADMIN") // Delete user by ID
                // Secure all other requests
                .anyRequest().authenticated()
            );

        // Add JWT filter before the standard UsernamePasswordAuthenticationFilter
        http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
