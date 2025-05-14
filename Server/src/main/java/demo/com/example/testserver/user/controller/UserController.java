package demo.com.example.testserver.user.controller; // Correct package

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired; // Added
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable; // Added
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import demo.com.example.testserver.user.model.User; // Added
import demo.com.example.testserver.user.repository.UserRepository; // Added

import java.util.Optional; // Added

@RestController
@RequestMapping("/api/users") // Keep the base path for any remaining general user endpoints like ping
@CrossOrigin(origins = "*")
public class UserController {

    // Add Logger instance
    private static final Logger logger = LoggerFactory.getLogger(UserController.class);

    @Autowired // Added
    private UserRepository userRepository; // Added

    // Ping endpoint for testing API connectivity
    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        logger.info("Received ping request"); // Use logger
        return new ResponseEntity<>("Server is up and running", HttpStatus.OK);
    }

    @GetMapping("/{id}/avatar") // Added
    public ResponseEntity<String> getUserAvatar(@PathVariable Integer id) { // Changed return type to ResponseEntity<String>
        Optional<User> userOptional = userRepository.findById(id); // Added
        if (!userOptional.isPresent()) { // Added
            logger.warn("User not found for avatar request: {}", id); // Added
            return ResponseEntity.notFound().build(); // Added
        } // Added

        User user = userOptional.get(); // Added
        String avatarFilename = user.getAvatar(); // Added

        if (avatarFilename == null || avatarFilename.isEmpty()) { // Added
            logger.warn("User {} does not have an avatar.", id); // Added
            return ResponseEntity.notFound().build(); // Added
        } // Added

        // Return the avatar filename (which is the relative URL path)
        logger.info("Returning avatar filename {} for user {}", avatarFilename, id); // Added
        return ResponseEntity.ok(avatarFilename); // Added
    } // Added

}
