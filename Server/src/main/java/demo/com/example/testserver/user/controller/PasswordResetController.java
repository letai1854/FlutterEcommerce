package demo.com.example.testserver.user.controller;

import demo.com.example.testserver.common.service.EmailService;
import demo.com.example.testserver.user.model.PasswordResetToken;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.PasswordResetTokenRepository;
import demo.com.example.testserver.user.repository.UserRepository;
import demo.com.example.testserver.user.service.PasswordResetTokenService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/password-reset") // Changed base path
@CrossOrigin(origins = "*")
public class PasswordResetController {

    private static final Logger logger = LoggerFactory.getLogger(PasswordResetController.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordResetTokenService passwordResetTokenService;

    @Autowired(required = false)
    private EmailService emailService;

    @Autowired
    private PasswordResetTokenRepository tokenRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // Request password reset OTP (Forgot Password)
    @PostMapping("/forgot-password")
    public ResponseEntity<String> forgotPassword(@RequestBody Map<String, String> emailRequest) {
        String email = emailRequest.get("email");
        if (email == null || email.trim().isEmpty()) {
            logger.warn("Forgot password request failed: Email is required.");
            return new ResponseEntity<>("Email is required", HttpStatus.BAD_REQUEST);
        }
        email = email.trim(); // Trim email

        Optional<User> userOptional = userRepository.findActiveUserByEmail(email);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            // Generate plain OTP, store hash, get plain OTP back
            String plainOtp = passwordResetTokenService.createPasswordResetToken(user);

            // Send email with OTP (if service is available)
            if (emailService != null) {
                try {
                    // Use the EmailService interface - needs a new method sendPasswordResetOtp
                    emailService.sendPasswordResetOtp(user.getEmail(), plainOtp);
                    logger.info("Password reset OTP sent to: {}", email); // Log info
                } catch (Exception e) {
                    logger.error("Failed to send password reset OTP email to {}: {}", email, e.getMessage());
                    // Still return OK to not reveal if email exists, but log the error
                }
            } else {
                // Log that email service is not configured, but still log the OTP for testing/manual use
                logger.warn("EmailService not configured. Password reset requested for: {}. Plain OTP (for testing): {}", email, plainOtp); // Log warning
            }
        } else {
            logger.warn("Password reset requested for non-existent or inactive email: {}", email); // Log warning
        }

        // Always return a generic success message to prevent email enumeration attacks
        return new ResponseEntity<>("If an account with that email exists and is active, a password reset OTP has been sent.", HttpStatus.OK);
    }

    // Verify the OTP code
    @PostMapping("/verify-otp")
    public ResponseEntity<String> verifyOtp(@RequestBody Map<String, String> verificationRequest) {
        String email = verificationRequest.get("email");
        String otp = verificationRequest.get("otp");

        if (email == null || email.trim().isEmpty() || otp == null || otp.trim().isEmpty()) {
            return new ResponseEntity<>("Email and OTP are required.", HttpStatus.BAD_REQUEST);
        }
        email = email.trim();
        otp = otp.trim();

        // 1. Find user by email
        Optional<User> userOptional = userRepository.findActiveUserByEmail(email);
        if (!userOptional.isPresent()) {
            logger.warn("OTP verification attempt for non-existent or inactive email: {}", email);
            return new ResponseEntity<>("Invalid OTP or email.", HttpStatus.BAD_REQUEST); // Generic error
        }
        User user = userOptional.get();

        // 2. Find the token associated with the user
        Optional<PasswordResetToken> tokenOptional = tokenRepository.findByUser(user);
        if (!tokenOptional.isPresent()) {
            logger.warn("No OTP found for user: {}", email);
            return new ResponseEntity<>("Invalid OTP or email.", HttpStatus.BAD_REQUEST);
        }
        PasswordResetToken token = tokenOptional.get();

        // 3. Verify the provided OTP against the stored hash
        if (!passwordEncoder.matches(otp, token.getTokenHash())) {
            logger.warn("Incorrect OTP provided for user: {}", email);
            return new ResponseEntity<>("Invalid OTP or email.", HttpStatus.BAD_REQUEST);
        }

        // 4. Check expiry
        if (token.isExpired()) {
            logger.warn("Expired OTP provided for user: {}", email);
            tokenRepository.delete(token); // Clean up expired token
            return new ResponseEntity<>("OTP has expired.", HttpStatus.BAD_REQUEST);
        }

        // If all checks pass
        logger.info("OTP verified successfully for user: {}", email);
        return new ResponseEntity<>("OTP verified successfully.", HttpStatus.OK);
    }

    // Set new password after OTP verification
    @PostMapping("/set-new-password")
    public ResponseEntity<String> setNewPassword(@RequestBody Map<String, String> resetRequest) {
        String email = resetRequest.get("email");
        String otp = resetRequest.get("otp");
        String newPassword = resetRequest.get("newPassword");

        if (email == null || email.trim().isEmpty() || otp == null || otp.trim().isEmpty() || newPassword == null || newPassword.isEmpty()) {
            return new ResponseEntity<>("Email, OTP, and new password are required.", HttpStatus.BAD_REQUEST);
        }
        if (newPassword.length() < 6) {
            return new ResponseEntity<>("New password must be at least 6 characters long.", HttpStatus.BAD_REQUEST);
        }

        email = email.trim();
        otp = otp.trim();

        // 1. Find user by email
        Optional<User> userOptional = userRepository.findActiveUserByEmail(email);
        if (!userOptional.isPresent()) {
            logger.warn("Set new password attempt for non-existent or inactive email: {}", email);
            return new ResponseEntity<>("Invalid OTP or email.", HttpStatus.BAD_REQUEST); // Generic error
        }
        User user = userOptional.get();

        // 2. Find the token associated with the user
        Optional<PasswordResetToken> tokenOptional = tokenRepository.findByUser(user);
        if (!tokenOptional.isPresent()) {
            logger.warn("No OTP found for user during password set: {}", email);
            return new ResponseEntity<>("Invalid OTP or email.", HttpStatus.BAD_REQUEST);
        }
        PasswordResetToken token = tokenOptional.get();

        // 3. Verify the provided OTP against the stored hash
        if (!passwordEncoder.matches(otp, token.getTokenHash())) {
            logger.warn("Incorrect OTP provided during password set for user: {}", email);
            return new ResponseEntity<>("Invalid OTP or email.", HttpStatus.BAD_REQUEST);
        }

        // 4. Check expiry
        if (token.isExpired()) {
            logger.warn("Expired OTP provided during password set for user: {}", email);
            tokenRepository.delete(token); // Clean up expired token
            return new ResponseEntity<>("OTP has expired. Please request a new one.", HttpStatus.BAD_REQUEST);
        }

        // If OTP is valid and belongs to the user:
        // 5. Hash the new password
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // 6. Invalidate the OTP token after successful use
        tokenRepository.delete(token); // Delete the used token

        logger.info("Password has been reset successfully for user: {}", user.getEmail());
        return new ResponseEntity<>("Password has been reset successfully.", HttpStatus.OK);
    }
}
