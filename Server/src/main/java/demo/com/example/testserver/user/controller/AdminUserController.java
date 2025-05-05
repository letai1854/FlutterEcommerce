package demo.com.example.testserver.user.controller;

import demo.com.example.testserver.user.dto.UserDTO;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/users") // Changed base path to reflect admin scope
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('ADMIN')") // Secure all endpoints in this controller
public class AdminUserController {

    private static final Logger logger = LoggerFactory.getLogger(AdminUserController.class);

    @Autowired
    private UserRepository userRepository;

    // Get all active users
    @GetMapping
    public ResponseEntity<List<UserDTO>> getAllUsers() {
        try {
            List<User> users = userRepository.findAllActiveUsers();
            if (users.isEmpty()) {
                logger.info("No active users found.");
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            List<UserDTO> userDTOs = users.stream().map(UserDTO::new).collect(Collectors.toList());
            logger.info("Retrieved {} active users.", userDTOs.size());
            return new ResponseEntity<>(userDTOs, HttpStatus.OK);
        } catch (Exception e) {
            logger.error("Error retrieving all users", e);
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // Search users with pagination and filtering
    @GetMapping("/search")
    public ResponseEntity<Page<UserDTO>> searchUsers(
            @RequestParam(required = false) String email,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Date startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Date endDate,
            Pageable pageable) {
        try {
            logger.info("Admin searching users with filters - Email: {}, StartDate: {}, EndDate: {}, Pageable: {}", email, startDate, endDate, pageable);
            Page<User> userPage = userRepository.findAllWithFilters(email, startDate, endDate, pageable);
            Page<UserDTO> userDtoPage = userPage.map(UserDTO::new);
            return new ResponseEntity<>(userDtoPage, HttpStatus.OK);
        } catch (Exception e) {
            logger.error("Error searching users with filters", e);
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // Get user by ID
    // Note: @PreAuthorize("hasRole('ADMIN') or @securityService.isOwner(authentication, #id)") is removed as the whole controller requires ADMIN
    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getUserById(@PathVariable int id) {
        Optional<User> userData = userRepository.findById(id);
        if (userData.isPresent()) {
            User user = userData.get();
            UserDTO userDTO = new UserDTO(user);
            return new ResponseEntity<>(userDTO, HttpStatus.OK);
        } else {
            logger.warn("Admin requested non-existent user with ID: {}", id);
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    // Find user by email
    @GetMapping("/email/{email}")
    public ResponseEntity<UserDTO> getUserByEmail(@PathVariable String email) {
        Optional<User> user = userRepository.findByEmail(email);
        if (user.isPresent()) {
            User foundUser = user.get();
            UserDTO userDTO = new UserDTO(foundUser);
            return new ResponseEntity<>(userDTO, HttpStatus.OK);
        } else {
             logger.warn("Admin requested non-existent user with email: {}", email);
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    // Update user by ID
    @PutMapping("/{id}")
    public ResponseEntity<UserDTO> updateUser(@PathVariable int id, @RequestBody User userUpdates) {
        Optional<User> userData = userRepository.findById(id);

        if (userData.isPresent()) {
            User existingUser = userData.get();

            // Admin can update more fields
            if (userUpdates.getEmail() != null) existingUser.setEmail(userUpdates.getEmail());
            if (userUpdates.getFullName() != null) existingUser.setFullName(userUpdates.getFullName());
            if (userUpdates.getAvatar() != null) existingUser.setAvatar(userUpdates.getAvatar());
            if (userUpdates.getCustomerPoints() != null) existingUser.setCustomerPoints(userUpdates.getCustomerPoints());
            if (userUpdates.getStatus() != null) existingUser.setStatus(userUpdates.getStatus());
            if (userUpdates.getRole() != null) existingUser.setRole(userUpdates.getRole());
            // Note: Password should not be updated via this endpoint. Use a dedicated password reset mechanism.

            try {
                User updatedUser = userRepository.save(existingUser);
                UserDTO userDTO = new UserDTO(updatedUser);
                logger.info("Admin updated user successfully: ID {}", id);
                return new ResponseEntity<>(userDTO, HttpStatus.OK);
            } catch (Exception e) {
                 logger.error("Error updating user with ID {}: {}", id, e.getMessage(), e);
                 return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
            }
        } else {
            logger.warn("Admin attempted to update non-existent user with ID: {}", id);
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    // Delete user
    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteUser(@PathVariable int id) {
        try {
            if (userRepository.existsById(id)) {
                userRepository.deleteById(id);
                logger.info("Admin deleted user with ID [{}] successfully.", id);
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            } else {
                logger.warn("Admin attempted to delete non-existent user with ID [{}].", id);
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            logger.error("Error deleting user with ID [{}]: {}", id, e.getMessage(), e);
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
