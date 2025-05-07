package demo.com.example.testserver.user.service.impl;

import java.security.SecureRandom; // For OTP generation
import java.util.Date; // Import Date
import java.util.List; // Import List for token iteration
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder; // Import PasswordEncoder
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import demo.com.example.testserver.user.repository.PasswordResetTokenRepository; // Correct import path
import demo.com.example.testserver.user.model.PasswordResetToken;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.service.PasswordResetTokenService;

@Service
@Transactional // Use transactions for operations involving multiple steps
public class PasswordResetTokenServiceImpl implements PasswordResetTokenService {

    private static final Logger logger = LoggerFactory.getLogger(PasswordResetTokenServiceImpl.class);
    private static final int OTP_LENGTH = 6; // Define OTP length

    @Autowired
    private PasswordResetTokenRepository tokenRepository;

    @Autowired
    private PasswordEncoder passwordEncoder; // Inject PasswordEncoder for hashing OTP

    // Helper to generate a random 6-digit OTP
    private String generateOtp() {
        SecureRandom random = new SecureRandom();
        StringBuilder otp = new StringBuilder(OTP_LENGTH);
        for (int i = 0; i < OTP_LENGTH; i++) {
            otp.append(random.nextInt(10)); // Append a random digit (0-9)
        }
        return otp.toString();
    }

    // Helper to hash the OTP
    private String hashOtp(String plainOtp) {
        return passwordEncoder.encode(plainOtp);
    }

    @Override
    public String createPasswordResetToken(User user) {
        // Invalidate existing token for the user, if any
        tokenRepository.findByUser(user).ifPresent(tokenRepository::delete);

        String plainOtp = generateOtp(); // Generate 6-digit OTP
        String otpHash = hashOtp(plainOtp); // Hash the OTP
        Date expiryDate = PasswordResetToken.calculateExpiryDate(PasswordResetToken.EXPIRATION); // Calculate expiry date

        PasswordResetToken resetToken = new PasswordResetToken(otpHash, user, expiryDate); // Save the HASHED OTP
        tokenRepository.save(resetToken);
        logger.info("Created password reset OTP for user: {}. OTP Hash: {}", user.getEmail(), otpHash); // Log hash, not plain OTP
        return plainOtp; // Return the plain OTP to be sent via email
    }

    @Override
    public Optional<PasswordResetToken> validatePasswordResetToken(String plainOtp) {
        List<PasswordResetToken> allTokens = tokenRepository.findAll(); // Inefficient!
        Optional<PasswordResetToken> foundTokenOpt = allTokens.stream()
            .filter(token -> passwordEncoder.matches(plainOtp, token.getTokenHash()))
            .findFirst();

        if (foundTokenOpt.isPresent()) {
            PasswordResetToken token = foundTokenOpt.get();
            if (token.isExpired()) {
                logger.warn("Password reset OTP found but expired for user {}", token.getUser().getEmail());
                tokenRepository.delete(token); // Clean up expired token
                return Optional.empty();
            }
            logger.debug("Password reset OTP validated successfully for user {}", token.getUser().getEmail());
            return foundTokenOpt;
        }

        logger.warn("Password reset OTP not found or invalid: {}", plainOtp);
        return Optional.empty();
    }

    @Override
    public Optional<User> getUserByPasswordResetToken(String plainOtp) {
        return validatePasswordResetToken(plainOtp)
                .map(PasswordResetToken::getUser);
    }

    @Override
    public void invalidateToken(String plainOtp) {
        List<PasswordResetToken> allTokens = tokenRepository.findAll(); // Inefficient!
        Optional<PasswordResetToken> foundTokenOpt = allTokens.stream()
            .filter(token -> passwordEncoder.matches(plainOtp, token.getTokenHash()))
            .findFirst();

        if (foundTokenOpt.isPresent()) {
            PasswordResetToken token = foundTokenOpt.get();
            tokenRepository.delete(token);
            logger.info("Invalidated password reset OTP for user: {}", token.getUser().getEmail());
        } else {
            logger.warn("Attempted to invalidate an OTP that was not found or did not match: {}", plainOtp);
        }
    }

    @Override
    // @Scheduled(cron = "0 0 * * * ?") // Example: Run hourly
    public void deleteExpiredTokens() {
        Date now = new Date();
        logger.info("Deleting expired password reset tokens older than {}", now);
        tokenRepository.deleteByExpiryDateLessThan(now);
    }
}
