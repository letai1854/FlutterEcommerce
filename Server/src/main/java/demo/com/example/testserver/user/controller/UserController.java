package demo.com.example.testserver.user.controller; // Correct package

import java.math.BigDecimal; // Correct import path
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors; // Import Collectors

import org.slf4j.Logger; // Import HttpServletRequest
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder; // For building URLs
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import demo.com.example.testserver.common.service.EmailService;
import demo.com.example.testserver.user.dto.UserDTO; // Import UserDTO
import demo.com.example.testserver.user.dto.RegistrationRequest; // Import RegistrationRequest
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.model.Address; // Import Address
import demo.com.example.testserver.user.repository.UserRepository;
import demo.com.example.testserver.user.security.JwtTokenProvider;
import demo.com.example.testserver.user.service.PasswordResetTokenService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    // Add Logger instance
    private static final Logger logger = LoggerFactory.getLogger(UserController.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtTokenProvider tokenProvider;

    @Autowired
    private PasswordResetTokenService passwordResetTokenService;

    @Autowired(required = false) // Make EmailService optional for now if not implemented yet
    private EmailService emailService;

    // Ping endpoint for testing API connectivity
    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        logger.info("Received ping request"); // Use logger
        return new ResponseEntity<>("Server is up and running", HttpStatus.OK);
    }

    // Get all active users (Needs @PreAuthorize("hasRole('ADMIN')"))
    @GetMapping
    // @PreAuthorize("hasRole('ADMIN')") // Example authorization
    public ResponseEntity<List<UserDTO>> getAllUsers() { // Return List<UserDTO>
        try {
            List<User> users = userRepository.findAllActiveUsers();
            if (users.isEmpty()) {
                logger.info("No active users found.");
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            // Convert List<User> to List<UserDTO>
            List<UserDTO> userDTOs = users.stream().map(UserDTO::new).collect(Collectors.toList());
            logger.info("Retrieved {} active users.", userDTOs.size());
            return new ResponseEntity<>(userDTOs, HttpStatus.OK);
        } catch (Exception e) {
            logger.error("Error retrieving all users", e); // Log error
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
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
        return new ResponseEntity<>("Logged out successfully", HttpStatus.OK);
    }

    // Get user by ID (Needs @PreAuthorize("hasRole('ADMIN') or #id == authentication.principal.id"))
    @GetMapping("/{id}")
    // @PreAuthorize("hasRole('ADMIN') or #id == principal.id") // Example authorization (assuming principal has 'id')
    public ResponseEntity<UserDTO> getUserById(@PathVariable int id) { // Return UserDTO
        Optional<User> userData = userRepository.findById(id);
        if (userData.isPresent()) {
            User user = userData.get();
            UserDTO userDTO = new UserDTO(user); // Create DTO
            return new ResponseEntity<>(userDTO, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    // Get current authenticated user's profile (Needs Authentication - handled by filter)
    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUserProfile(@AuthenticationPrincipal UserDetails userDetails) { // Return UserDTO
        // UserDetails contains the username (email in our case)
        String userEmail = userDetails.getUsername();
        Optional<User> userData = userRepository.findActiveUserByEmail(userEmail);

        if (userData.isPresent()) {
            User user = userData.get();
            UserDTO userDTO = new UserDTO(user); // Create DTO
            return new ResponseEntity<>(userDTO, HttpStatus.OK);
        } else {
            // This case means the user authenticated via token exists in UserDetails but not in DB (or is inactive)
            // This might indicate a data consistency issue or a revoked user.
            return new ResponseEntity<>("Authenticated user data not found or user inactive.", HttpStatus.NOT_FOUND);
        }
    }

    // Create new user (Register)
    @PostMapping("/register")
    public ResponseEntity<?> createUser(@Valid @RequestBody RegistrationRequest request) { // Use RegistrationRequest and @Valid
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
            // newAddress.setUser(newUser); // Set the user relationship (done via convenience method)

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

    // Update user by ID (Needs @PreAuthorize("hasRole('ADMIN')"))
    @PutMapping("/{id}")
    // @PreAuthorize("hasRole('ADMIN')") // Example authorization
    public ResponseEntity<UserDTO> updateUser(@PathVariable int id, @RequestBody User userUpdates) { // Return UserDTO
        Optional<User> userData = userRepository.findById(id);

        if (userData.isPresent()) {
            User existingUser = userData.get();

            if (userUpdates.getEmail() != null) existingUser.setEmail(userUpdates.getEmail());
            if (userUpdates.getFullName() != null) existingUser.setFullName(userUpdates.getFullName());
            if (userUpdates.getAvatar() != null) existingUser.setAvatar(userUpdates.getAvatar());
            if (userUpdates.getCustomerPoints() != null) existingUser.setCustomerPoints(userUpdates.getCustomerPoints());
            if (userUpdates.getStatus() != null) existingUser.setStatus(userUpdates.getStatus());
            if (userUpdates.getRole() != null) existingUser.setRole(userUpdates.getRole());

            User updatedUser = userRepository.save(existingUser);
            UserDTO userDTO = new UserDTO(updatedUser); // Create DTO
            return new ResponseEntity<>(userDTO, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    // Update current authenticated user's profile (Needs Authentication - handled by filter)
    @PutMapping("/me/update")
    public ResponseEntity<?> updateCurrentUserProfile(@AuthenticationPrincipal UserDetails userDetails, @RequestBody User userUpdates) { // Return UserDTO
        String userEmail = userDetails.getUsername();
        Optional<User> userData = userRepository.findActiveUserByEmail(userEmail);

        if (userData.isPresent()) {
            User existingUser = userData.get();

            // Update allowed fields for self-update
            if (userUpdates.getFullName() != null) existingUser.setFullName(userUpdates.getFullName());
            if (userUpdates.getAvatar() != null) existingUser.setAvatar(userUpdates.getAvatar());
            // Add other updatable fields like phone number if added to User model

            User updatedUser = userRepository.save(existingUser);
            UserDTO userDTO = new UserDTO(updatedUser); // Create DTO
            return new ResponseEntity<>(userDTO, HttpStatus.OK);
        } else {
            return new ResponseEntity<>("Authenticated user not found", HttpStatus.NOT_FOUND);
        }
    }

    // Change current authenticated user's password (Needs Authentication - handled by filter)
    @PostMapping("/me/change-password")
    public ResponseEntity<String> changeCurrentUserPassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody Map<String, String> passwordRequest) {

        String userEmail = userDetails.getUsername();
        Optional<User> userData = userRepository.findActiveUserByEmail(userEmail);

        String oldPassword = passwordRequest.get("oldPassword");
        String newPassword = passwordRequest.get("newPassword");

        if (oldPassword == null || newPassword == null || newPassword.length() < 6) {
            return new ResponseEntity<>("Old and new passwords are required (new password min 6 chars).", HttpStatus.BAD_REQUEST);
        }

        if (userData.isPresent()) {
            User existingUser = userData.get();

            // *** SECURITY *** Verify old password using password encoder
            if (passwordEncoder.matches(oldPassword, existingUser.getPassword())) {

                // *** SECURITY *** Hash the new password
                existingUser.setPassword(passwordEncoder.encode(newPassword));
                userRepository.save(existingUser);
                return new ResponseEntity<>("Password changed successfully", HttpStatus.OK);

            } else {
                return new ResponseEntity<>("Incorrect old password", HttpStatus.UNAUTHORIZED);
            }

        } else {
            return new ResponseEntity<>("Authenticated user not found", HttpStatus.NOT_FOUND);
        }
    }

    // Request password reset (Forgot Password)
    @PostMapping("/forgot-password")
    public ResponseEntity<String> forgotPassword(@RequestBody Map<String, String> emailRequest, HttpServletRequest request) {
        String email = emailRequest.get("email");
        if (email == null) {
            logger.warn("Forgot password request failed: Email is required.");
            return new ResponseEntity<>("Email is required", HttpStatus.BAD_REQUEST);
        }
        email = email.trim(); // Trim email

        Optional<User> userOptional = userRepository.findActiveUserByEmail(email);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            // *** SECURITY *** Generate plain token, store hash, send plain token via email
            String plainToken = passwordResetTokenService.createPasswordResetToken(user);

            // Send email (if service is available)
            if (emailService != null) {
                 // Construct the reset URL (adjust path as needed)
                 String resetUrlBase = ServletUriComponentsBuilder.fromRequestUri(request)
                                        .replacePath("/reset-password") // Or your frontend reset path
                                        .replaceQuery(null) // Clear existing query params
                                        .toUriString();
                 String resetLink = resetUrlBase + "?token=" + plainToken; // Append token query param

                 // Use the EmailService interface
                 emailService.sendPasswordResetEmail(user.getEmail(), plainToken, resetLink); // Pass link or just token
                 logger.info("Password reset email initiated for: {}. Reset Link Base: {}", email, resetUrlBase); // Log info
            } else {
                 // Log that email service is not configured, but still log the token for testing/manual use
                 logger.warn("EmailService not configured. Password reset requested for: {}. Plain Token (for testing): {}", email, plainToken); // Log warning
            }
        } else {
            logger.warn("Password reset requested for non-existent or inactive email: {}", email); // Log warning
        }

        // Always return a generic success message
        return new ResponseEntity<>("If an account with that email exists, a password reset link has been sent.", HttpStatus.OK);
    }

    // Reset password using token
    @PostMapping("/reset-password")
    public ResponseEntity<String> resetPassword(@RequestBody Map<String, String> resetRequest) {
        String token = resetRequest.get("token"); // Plain token from email link/request body
        String newPassword = resetRequest.get("newPassword");

        if (token == null || newPassword == null || newPassword.length() < 6) {
            logger.warn("Password reset attempt failed: Token or new password missing/invalid length.");
            return new ResponseEntity<>("Token and new password (min 6 chars) are required.", HttpStatus.BAD_REQUEST);
        }

        // *** SECURITY *** Validate token using the service
        Optional<User> userOptional = passwordResetTokenService.getUserByPasswordResetToken(token);

        if (userOptional.isPresent()) {
           User user = userOptional.get();
           // *** SECURITY *** Hash the new password
           user.setPassword(passwordEncoder.encode(newPassword));
           userRepository.save(user);

           // *** SECURITY *** Invalidate the token after successful use
           passwordResetTokenService.invalidateToken(token);

           logger.info("Password reset successful for user: {}", user.getEmail()); // Log info
           return new ResponseEntity<>("Password has been reset successfully.", HttpStatus.OK);
        } else {
            logger.warn("Attempting password reset with invalid or expired token: {}", token); // Log warning
            return new ResponseEntity<>("Invalid or expired password reset token.", HttpStatus.BAD_REQUEST);
        }
    }

    // Delete user (Needs @PreAuthorize("hasRole('ADMIN')"))
    @DeleteMapping("/{id}")
    // @PreAuthorize("hasRole('ADMIN')") // Example authorization
    public ResponseEntity<HttpStatus> deleteUser(@PathVariable int id) {
        try {
            if (userRepository.existsById(id)) {
                userRepository.deleteById(id);
                logger.info("User with ID [{}] deleted successfully.", id);
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            } else {
                logger.warn("Attempted to delete non-existent user with ID [{}].", id);
                return new ResponseEntity<>(HttpStatus.NOT_FOUND); // More specific than internal server error
            }
        } catch (Exception e) {
            logger.error("Error deleting user with ID [{}]: {}", id, e.getMessage(), e); // Log error
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // Find user by email (Needs @PreAuthorize("hasRole('ADMIN')"))
    @GetMapping("/email/{email}")
    // @PreAuthorize("hasRole('ADMIN')") // Example authorization
    public ResponseEntity<UserDTO> getUserByEmail(@PathVariable String email) { // Return UserDTO
        Optional<User> user = userRepository.findByEmail(email);
        if (user.isPresent()) {
            User foundUser = user.get();
            UserDTO userDTO = new UserDTO(foundUser); // Create DTO
            return new ResponseEntity<>(userDTO, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}
