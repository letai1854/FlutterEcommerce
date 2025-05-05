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
                .requestMatchers("/api/users/ping").permitAll() // Keep ping public
                // --- Authentication Endpoints ---
                .requestMatchers(HttpMethod.POST, "/api/auth/login").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/auth/register").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/auth/logout").authenticated() // Require auth for logout
                // --- Password Reset Endpoints ---
                .requestMatchers(HttpMethod.POST, "/api/password-reset/forgot-password").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/password-reset/verify-otp").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/password-reset/set-new-password").permitAll()
                // --- Product/Category/Brand Public Access ---
                .requestMatchers(HttpMethod.GET, "/api/products/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/categories/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/brands/**").permitAll()
                // --- Product/Category/Brand Admin Management ---
                .requestMatchers(HttpMethod.POST, "/api/products").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/products/{id}").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/products/{id}").hasRole("ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/categories").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/categories/{id}").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/categories/{id}").hasRole("ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/brands").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/brands/{id}").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/brands/{id}").hasRole("ADMIN")
                // --- Coupon Management ---
                .requestMatchers(HttpMethod.POST, "/api/coupons").hasRole("ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/coupons").hasRole("ADMIN") // Admin search
                .requestMatchers(HttpMethod.GET, "/api/coupons/available").authenticated() // User available
                // --- Image Routes ---
                .requestMatchers(HttpMethod.GET, "/api/images/**").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/images/upload").authenticated()
                // --- Admin User Management ---
                .requestMatchers("/api/admin/users/**").hasRole("ADMIN") // Secure all admin user routes
                // --- Current User Profile Management ---
                .requestMatchers("/api/users/me/**").authenticated() // Secure all /me routes (profile, update, change password)
                // --- Address Management ---
                .requestMatchers("/api/addresses/me/**").authenticated() // Secure all /me address routes
                // Secure all other requests
                .anyRequest().authenticated()
            );

        // Add JWT filter before the standard UsernamePasswordAuthenticationFilter
        http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
