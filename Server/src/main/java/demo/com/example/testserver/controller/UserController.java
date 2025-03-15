package demo.com.example.testserver.controller;

import demo.com.example.testserver.model.User;
import demo.com.example.testserver.repository.UserRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    // Ping endpoint for testing API connectivity
    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        System.out.println("ping -0----");
        return new ResponseEntity<>("Server is up and running", HttpStatus.OK);
    }

    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        try {
            List<User> users = userRepository.findAllActiveUsers();
            if (users.isEmpty()) {
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            return new ResponseEntity<>(users, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        try {
            String email = credentials.get("email");
            String password = credentials.get("password");
            
            Optional<User> user = userRepository.findActiveUserByEmailAndPassword(
                email.trim(), password);
            
            if (user.isPresent()) {
                User loggedInUser = user.get();
                loggedInUser.setPassword(null); // Don't send password
                return new ResponseEntity<>(loggedInUser, HttpStatus.OK);
            }
            return new ResponseEntity<>("Invalid credentials", HttpStatus.UNAUTHORIZED);
        } catch (Exception e) {
            System.out.println("Login failed: " + e.getMessage());
            return new ResponseEntity<>("Login failed: " + e.getMessage(), 
                HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }


    // Get user by ID
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable int id) {
        Optional<User> userData = userRepository.findById(id);
        if (userData.isPresent()) {
            return new ResponseEntity<>(userData.get(), HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    // Create new user
    @PostMapping("/register")
    public ResponseEntity<?> createUser(@RequestBody User user) {
        try {
            // Check if email exists
            if (userRepository.findByEmail(user.getEmail()).isPresent()) {
                return new ResponseEntity<>("Email already exists", HttpStatus.CONFLICT);
            }
    
            // Set default values
            user.setCreatedDate(new Date());
            user.setStatus(true);
            user.setCustomerPoints(0);
            if (user.getRole() == null) {
                user.setRole(User.UserRole.customer);
            }
    
            // Save user
            User savedUser = userRepository.save(user);
            
            // Create response object without password
            User responseUser = new User();
            responseUser.setId(savedUser.getId());
            responseUser.setEmail(savedUser.getEmail());
            responseUser.setFullName(savedUser.getFullName());
            responseUser.setAddress(savedUser.getAddress());
            responseUser.setRole(savedUser.getRole());
            responseUser.setCreatedDate(savedUser.getCreatedDate());
            responseUser.setStatus(savedUser.getStatus());
            responseUser.setCustomerPoints(savedUser.getCustomerPoints());
            responseUser.setAvatar(savedUser.getAvatar());
            responseUser.setChatId(savedUser.getChatId());
    
            return new ResponseEntity<>(responseUser, HttpStatus.CREATED);
    
        } catch (Exception e) {
            e.printStackTrace();
            return new ResponseEntity<>("Registration failed: " + e.getMessage(), 
                HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // Update user
    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(@PathVariable int id, @RequestBody User user) {
        Optional<User> userData = userRepository.findById(id);

        if (userData.isPresent()) {
            User existingUser = userData.get();
            existingUser.setEmail(user.getEmail());
            existingUser.setFullName(user.getFullName());
            existingUser.setAddress(user.getAddress());
            existingUser.setAvatar(user.getAvatar());
            existingUser.setCustomerPoints(user.getCustomerPoints());
            existingUser.setStatus(user.getStatus());
            
            // Only update password if it's provided
            if (user.getPassword() != null && !user.getPassword().isEmpty()) {
                existingUser.setPassword(user.getPassword());
            }
            
            return new ResponseEntity<>(userRepository.save(existingUser), HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    // Delete user
    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteUser(@PathVariable int id) {
        try {
            userRepository.deleteById(id);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // Find user by email
    @GetMapping("/email/{email}")
    public ResponseEntity<User> getUserByEmail(@PathVariable String email) {
        Optional<User> user = userRepository.findByEmail(email);
        return user.map(value -> new ResponseEntity<>(value, HttpStatus.OK))
                  .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }
}
