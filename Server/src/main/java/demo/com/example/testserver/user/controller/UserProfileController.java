package demo.com.example.testserver.user.controller;

import demo.com.example.testserver.user.dto.UserDTO;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/users") // Reverted base path
@CrossOrigin(origins = "*")
public class UserProfileController {

    private static final Logger logger = LoggerFactory.getLogger(UserProfileController.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // Get current authenticated user's profile
    @GetMapping("/me") // Keep /me in method mapping
    public ResponseEntity<?> getCurrentUserProfile(@AuthenticationPrincipal UserDetails userDetails) {
        if (userDetails == null) {
            return new ResponseEntity<>("Authentication required.", HttpStatus.UNAUTHORIZED);
        }
        String userEmail = userDetails.getUsername();
        Optional<User> userData = userRepository.findActiveUserByEmail(userEmail);

        if (userData.isPresent()) {
            User user = userData.get();
            UserDTO userDTO = new UserDTO(user); // Create DTO
            return new ResponseEntity<>(userDTO, HttpStatus.OK);
        } else {
            logger.warn("Authenticated user data not found or user inactive for email: {}", userEmail);
            return new ResponseEntity<>("Authenticated user data not found or user inactive.", HttpStatus.NOT_FOUND);
        }
    }

    // Update current authenticated user's profile
    @PutMapping("/me/update") // Keep /me/update in method mapping
    public ResponseEntity<?> updateCurrentUserProfile(@AuthenticationPrincipal UserDetails userDetails, @RequestBody User userUpdates) {
        if (userDetails == null) {
            return new ResponseEntity<>("Authentication required.", HttpStatus.UNAUTHORIZED);
        }
        String userEmail = userDetails.getUsername();
        Optional<User> userData = userRepository.findActiveUserByEmail(userEmail);

        if (userData.isPresent()) {
            User existingUser = userData.get();

            // Update allowed fields for self-update
            // Ensure sensitive fields like password, role, status, points are NOT updated here
            if (userUpdates.getFullName() != null) {
                existingUser.setFullName(userUpdates.getFullName());
            }
            if (userUpdates.getAvatar() != null) {
                existingUser.setAvatar(userUpdates.getAvatar());
            }
            // Add other updatable fields like phone number if added to User model and allowed

            try {
                User updatedUser = userRepository.save(existingUser);
                UserDTO userDTO = new UserDTO(updatedUser); // Create DTO
                logger.info("User profile updated successfully for: {}", userEmail);
                return new ResponseEntity<>(userDTO, HttpStatus.OK);
            } catch (Exception e) {
                logger.error("Error updating profile for user {}: {}", userEmail, e.getMessage(), e);
                return new ResponseEntity<>("Failed to update profile.", HttpStatus.INTERNAL_SERVER_ERROR);
            }
        } else {
            logger.warn("Attempt to update profile for non-existent or inactive user: {}", userEmail);
            return new ResponseEntity<>("Authenticated user not found or inactive.", HttpStatus.NOT_FOUND);
        }
    }

    // Change current authenticated user's password
    @PostMapping("/me/change-password") // Keep /me/change-password in method mapping
    public ResponseEntity<String> changeCurrentUserPassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody Map<String, String> passwordRequest) {

        if (userDetails == null) {
            return new ResponseEntity<>("Authentication required.", HttpStatus.UNAUTHORIZED);
        }
        String userEmail = userDetails.getUsername();
        Optional<User> userData = userRepository.findActiveUserByEmail(userEmail);

        String oldPassword = passwordRequest.get("oldPassword");
        String newPassword = passwordRequest.get("newPassword");

        if (oldPassword == null || newPassword == null || newPassword.trim().isEmpty()) {
             return new ResponseEntity<>("Old and new passwords are required.", HttpStatus.BAD_REQUEST);
        }
        if (newPassword.length() < 6) {
            return new ResponseEntity<>("New password must be at least 6 characters long.", HttpStatus.BAD_REQUEST);
        }


        if (userData.isPresent()) {
            User existingUser = userData.get();

            // Verify old password
            if (passwordEncoder.matches(oldPassword, existingUser.getPassword())) {
                // Hash the new password
                existingUser.setPassword(passwordEncoder.encode(newPassword));
                try {
                    userRepository.save(existingUser);
                    logger.info("Password changed successfully for user: {}", userEmail);
                    return new ResponseEntity<>("Password changed successfully", HttpStatus.OK);
                } catch (Exception e) {
                     logger.error("Error saving changed password for user {}: {}", userEmail, e.getMessage(), e);
                     return new ResponseEntity<>("Failed to change password.", HttpStatus.INTERNAL_SERVER_ERROR);
                }
            } else {
                logger.warn("Incorrect old password provided for user: {}", userEmail);
                return new ResponseEntity<>("Incorrect old password", HttpStatus.UNAUTHORIZED);
            }
        } else {
             logger.warn("Attempt to change password for non-existent or inactive user: {}", userEmail);
            return new ResponseEntity<>("Authenticated user not found or inactive.", HttpStatus.NOT_FOUND);
        }
    }
}
