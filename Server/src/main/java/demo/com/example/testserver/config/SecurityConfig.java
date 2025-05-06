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
                // --- Authentication Endpoints (under /api/users) ---
                .requestMatchers(HttpMethod.POST, "/api/users/login").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/users/register").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/users/logout").authenticated() // Require auth for logout
                // --- Password Reset Endpoints (under /api/users) ---
                .requestMatchers(HttpMethod.POST, "/api/users/forgot-password").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/users/verify-otp").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/users/set-new-password").permitAll()
                // --- Product/Category/Brand Public Access ---
                .requestMatchers(HttpMethod.GET, "/api/products/top-selling").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/products/top-discounted").permitAll()
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
                // --- Admin User Management (under /api/users) ---
                .requestMatchers(HttpMethod.GET, "/api/users").hasRole("ADMIN") // Get all users
                .requestMatchers(HttpMethod.GET, "/api/users/search").hasRole("ADMIN") // Search users
                .requestMatchers(HttpMethod.GET, "/api/users/email/{email}").hasRole("ADMIN") // Get user by email
                // Need to be careful with GET /api/users/{id} if non-admins should access their own
                // .requestMatchers(HttpMethod.GET, "/api/users/{id}").hasRole("ADMIN") // Temporarily restrict all GET by ID to ADMIN
                // Or use method security in AdminUserController for GET /api/users/{id} if needed later
                .requestMatchers(HttpMethod.PUT, "/api/users/{id}").hasRole("ADMIN") // Update user by ID
                .requestMatchers(HttpMethod.DELETE, "/api/users/{id}").hasRole("ADMIN") // Delete user by ID
                // --- Current User Profile Management (under /api/users/me) ---
                .requestMatchers("/api/users/me/**").authenticated() // Secure all /me routes (profile, update, change password)
                // --- Address Management ---
                .requestMatchers("/api/addresses/me/**").authenticated() // Secure all /me address routes
                // --- Order Management ---
                .requestMatchers("/api/orders/**").authenticated() // Secure all order routes
                .requestMatchers(HttpMethod.PATCH, "/api/orders/{orderId}/status").hasRole("ADMIN") // Admin update order status
                // Secure all other requests
                .anyRequest().authenticated()
            );

        // Add JWT filter before the standard UsernamePasswordAuthenticationFilter
        http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
