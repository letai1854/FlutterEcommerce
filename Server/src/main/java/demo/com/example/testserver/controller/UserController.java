package demo.com.example.testserver.controller;

import demo.com.example.testserver.model.User;
import demo.com.example.testserver.repository.UserRepository;
import demo.com.example.testserver.security.JwtTokenProvider;
import demo.com.example.testserver.service.EmailService; // Import EmailService
import demo.com.example.testserver.service.PasswordResetTokenService; // Import PasswordResetTokenService
import jakarta.servlet.http.HttpServletRequest; // Import HttpServletRequest
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder; // For building URLs
// Import SLF4j loggers
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.util.*;

@RestController
@RequestMapping("/users")
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

    // *** SECURITY *** Inject PasswordResetTokenService and EmailService
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
    public ResponseEntity<List<User>> getAllUsers() {
        try {
            List<User> users = userRepository.findAllActiveUsers();
            users.forEach(user -> user.setPassword(null));
            if (users.isEmpty()) {
                logger.info("No active users found.");
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            logger.info("Retrieved {} active users.", users.size());
            return new ResponseEntity<>(users, HttpStatus.OK);
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

            // Get user details (excluding password) to return
            UserDetails userDetails = (UserDetails) authentication.getPrincipal();
            Optional<User> userOptional = userRepository.findActiveUserByEmail(userDetails.getUsername());

            if (userOptional.isPresent()) {
                User loggedInUser = userOptional.get();
                loggedInUser.setPassword(null); // Ensure password is not sent

                // Return JWT and user info
                Map<String, Object> response = new HashMap<>();
                response.put("token", jwt);
                response.put("user", loggedInUser);
                logger.info("User [{}] logged in successfully.", email); // Log success
                return ResponseEntity.ok(response);
            } else {
                // Should not happen if authentication succeeded, but handle defensively
                logger.error("User details not found for [{}] after successful authentication.", email); // Log error
                return new ResponseEntity<>("User details not found after authentication.", HttpStatus.INTERNAL_SERVER_ERROR);
            }

        } catch (Exception e) { // Catches BadCredentialsException, etc.
            logger.warn("Login failed for email [{}]: {}", email, e.getMessage()); // Log warning
            return new ResponseEntity<>("Invalid credentials or user not active", HttpStatus.UNAUTHORIZED);
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
    public ResponseEntity<User> getUserById(@PathVariable int id) {
        Optional<User> userData = userRepository.findById(id);
        if (userData.isPresent()) {
            User user = userData.get();
            user.setPassword(null);
            return new ResponseEntity<>(user, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    // Get current authenticated user's profile (Needs Authentication - handled by filter)
    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUserProfile(@AuthenticationPrincipal UserDetails userDetails) {
        // UserDetails contains the username (email in our case)
        String userEmail = userDetails.getUsername();
        Optional<User> userData = userRepository.findActiveUserByEmail(userEmail);

        if (userData.isPresent()) {
            User user = userData.get();
            user.setPassword(null); // Don't send password hash
            return new ResponseEntity<>(user, HttpStatus.OK);
        } else {
            // This case means the user authenticated via token exists in UserDetails but not in DB (or is inactive)
            // This might indicate a data consistency issue or a revoked user.
            return new ResponseEntity<>("Authenticated user data not found or user inactive.", HttpStatus.NOT_FOUND);
        }
    }

    // Create new user (Register)
    @PostMapping("/register")
    public ResponseEntity<?> createUser(@RequestBody User user) {
        try {
            if (userRepository.findByEmail(user.getEmail()).isPresent()) {
                logger.warn("Registration attempt failed: Email [{}] already exists.", user.getEmail());
                return new ResponseEntity<>("Email already exists", HttpStatus.CONFLICT);
            }
            if (user.getPassword() == null || user.getPassword().isEmpty()) {
                logger.warn("Registration attempt failed: Password was empty for email [{}].", user.getEmail());
                return new ResponseEntity<>("Password is required", HttpStatus.BAD_REQUEST);
            }

            // *** SECURITY *** Hash the password before saving
            user.setPassword(passwordEncoder.encode(user.getPassword()));

            user.setStatus(User.UserStatus.kich_hoat);
            user.setCustomerPoints(BigDecimal.ZERO);
            if (user.getRole() == null) {
                user.setRole(User.UserRole.khach_hang);
            }

            User savedUser = userRepository.save(user);

            User responseUser = new User();
            responseUser.setId(savedUser.getId());
            responseUser.setEmail(savedUser.getEmail());
            responseUser.setFullName(savedUser.getFullName());
            responseUser.setRole(savedUser.getRole());
            responseUser.setCreatedDate(savedUser.getCreatedDate());
            responseUser.setStatus(savedUser.getStatus());
            responseUser.setCustomerPoints(savedUser.getCustomerPoints());
            responseUser.setAvatar(savedUser.getAvatar());

            logger.info("User registered successfully: ID [{}], Email [{}]", savedUser.getId(), savedUser.getEmail());
            return new ResponseEntity<>(responseUser, HttpStatus.CREATED);

        } catch (Exception e) {
            logger.error("Registration failed for email [{}]: {}", user.getEmail(), e.getMessage(), e); // Log error with stack trace
            return new ResponseEntity<>("Registration failed: " + e.getMessage(),
                HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // Update user by ID (Needs @PreAuthorize("hasRole('ADMIN')"))
    @PutMapping("/{id}")
    // @PreAuthorize("hasRole('ADMIN')") // Example authorization
    public ResponseEntity<User> updateUser(@PathVariable int id, @RequestBody User userUpdates) {
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
            updatedUser.setPassword(null);
            return new ResponseEntity<>(updatedUser, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    // Update current authenticated user's profile (Needs Authentication - handled by filter)
    @PutMapping("/me/update")
    public ResponseEntity<?> updateCurrentUserProfile(@AuthenticationPrincipal UserDetails userDetails, @RequestBody User userUpdates) {
        String userEmail = userDetails.getUsername();
        Optional<User> userData = userRepository.findActiveUserByEmail(userEmail);

        if (userData.isPresent()) {
            User existingUser = userData.get();

            // Update allowed fields for self-update
            if (userUpdates.getFullName() != null) existingUser.setFullName(userUpdates.getFullName());
            if (userUpdates.getAvatar() != null) existingUser.setAvatar(userUpdates.getAvatar());
            // Add other updatable fields like phone number if added to User model

            User updatedUser = userRepository.save(existingUser);
            updatedUser.setPassword(null); // Don't send password hash
            return new ResponseEntity<>(updatedUser, HttpStatus.OK);
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
    public ResponseEntity<User> getUserByEmail(@PathVariable String email) {
        Optional<User> user = userRepository.findByEmail(email);
        if (user.isPresent()) {
            User foundUser = user.get();
            foundUser.setPassword(null);
            return new ResponseEntity<>(foundUser, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}
