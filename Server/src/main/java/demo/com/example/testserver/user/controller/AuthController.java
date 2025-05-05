package demo.com.example.testserver.user.controller;

import demo.com.example.testserver.user.dto.RegistrationRequest;
import demo.com.example.testserver.user.dto.UserDTO;
import demo.com.example.testserver.user.model.Address;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.UserRepository;
import demo.com.example.testserver.user.security.JwtTokenProvider;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth") // Changed base path
@CrossOrigin(origins = "*")
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtTokenProvider tokenProvider;

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@Valid @RequestBody RegistrationRequest request) {
        try {
            if (userRepository.findByEmail(request.getEmail()).isPresent()) {
                logger.warn("Registration attempt failed: Email [{}] already exists.", request.getEmail());
                return new ResponseEntity<>("Email already exists", HttpStatus.CONFLICT);
            }

            // Create new User entity
            User newUser = new User();
            newUser.setEmail(request.getEmail());
            newUser.setFullName(request.getFullName()); // Set full name
            newUser.setPassword(passwordEncoder.encode(request.getPassword())); // Hash password
            newUser.setStatus(User.UserStatus.kich_hoat);
            newUser.setCustomerPoints(BigDecimal.ZERO);
            newUser.setRole(User.UserRole.khach_hang); // Default role

            // Create new Address entity
            Address newAddress = new Address();
            newAddress.setRecipientName(request.getFullName()); // Use full name as recipient name
            newAddress.setPhoneNumber("0"); // Default phone number
            newAddress.setSpecificAddress(request.getAddress()); // Set specific address
            newAddress.setDefault(true); // Make this the default address

            // Add address to user's address list (this also sets user in address)
            newUser.addAddress(newAddress);

            // Save the user (Address will be saved due to CascadeType.ALL)
            User savedUser = userRepository.save(newUser);
            UserDTO userDTO = new UserDTO(savedUser); // Create DTO from saved entity

            logger.info("User registered successfully: ID [{}], Email [{}]", savedUser.getId(), savedUser.getEmail());
            return new ResponseEntity<>(userDTO, HttpStatus.CREATED); // Return DTO

        } catch (Exception e) {
            logger.error("Registration failed for email [{}]: {}", request.getEmail(), e.getMessage(), e); // Log error with stack trace
            return new ResponseEntity<>("Registration failed: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String email = credentials.get("email"); // Get email early for logging
        try {
            String password = credentials.get("password");

            // Authenticate user with Spring Security
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, password)
            );

            // If authentication successful, set it in the context
            SecurityContextHolder.getContext().setAuthentication(authentication);

            // Generate JWT token
            String jwt = tokenProvider.generateToken(authentication);

            // Get user details (principal)
            UserDetails userDetails = (UserDetails) authentication.getPrincipal();
            // Fetch the full User entity from repository to create DTO
            Optional<User> userOptional = userRepository.findActiveUserByEmail(userDetails.getUsername());

            if (userOptional.isPresent()) {
                User user = userOptional.get();
                UserDTO userDTO = new UserDTO(user); // Create DTO from entity

                // Return JWT and user DTO
                Map<String, Object> response = new HashMap<>();
                response.put("token", jwt);
                response.put("user", userDTO); // Use the DTO
                logger.info("User [{}] logged in successfully.", email); // Log success
                return ResponseEntity.ok(response);
            } else {
                // Should not happen if authentication succeeded, but handle defensively
                logger.error("User details not found for [{}] after successful authentication.", email); // Log error
                return new ResponseEntity<>("User details not found after authentication.", HttpStatus.INTERNAL_SERVER_ERROR);
            }

        } catch (AuthenticationException e) { // Catch specific authentication errors
            logger.warn("Login failed for email [{}]: {}", email, e.getMessage()); // Log warning
            return new ResponseEntity<>("Invalid credentials or user not active", HttpStatus.UNAUTHORIZED);
        } catch (Exception e) { // Catch other unexpected errors
            logger.error("An unexpected error occurred during login for email [{}]: {}", email, e.getMessage(), e); // Log as error
            return new ResponseEntity<>("An unexpected error occurred.", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // Logout endpoint (Stateless - Client handles token removal)
    @PostMapping("/logout")
    public ResponseEntity<String> logout() {
        // Optionally log logout attempt if needed, though it's stateless
        logger.info("Logout endpoint called (stateless).");
        // In a stateful session-based app, you would invalidate the session here.
        // For JWT, the client just needs to discard the token.
        return new ResponseEntity<>("Logged out successfully", HttpStatus.OK);
    }
}
