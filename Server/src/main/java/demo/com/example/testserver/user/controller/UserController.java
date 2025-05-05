package demo.com.example.testserver.user.controller; // Correct package

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users") // Keep the base path for any remaining general user endpoints like ping
@CrossOrigin(origins = "*")
public class UserController {

    // Add Logger instance
    private static final Logger logger = LoggerFactory.getLogger(UserController.class);

    // Ping endpoint for testing API connectivity
    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        logger.info("Received ping request"); // Use logger
        return new ResponseEntity<>("Server is up and running", HttpStatus.OK);
    }

}
