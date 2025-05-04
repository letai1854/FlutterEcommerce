package demo.com.example.testserver.user.service.impl;

import java.util.Date; // Import Date
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
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

    @Autowired
    private PasswordResetTokenRepository tokenRepository;

    @Override
    public String createPasswordResetToken(User user) {
        // Invalidate existing token for the user, if any
        tokenRepository.findByUser(user).ifPresent(tokenRepository::delete);

        String plainToken = UUID.randomUUID().toString();
        Date expiryDate = PasswordResetToken.calculateExpiryDate(PasswordResetToken.EXPIRATION); // Calculate expiry date

        PasswordResetToken resetToken = new PasswordResetToken(plainToken, user, expiryDate); // Use correct constructor
        tokenRepository.save(resetToken);
        logger.info("Created password reset token for user: {}", user.getEmail());
        return plainToken; // Return the plain token to be sent via email
    }

    @Override
    public Optional<PasswordResetToken> validatePasswordResetToken(String plainToken) {
        Optional<PasswordResetToken> tokenOpt = tokenRepository.findByTokenHash(plainToken);
        if (tokenOpt.isPresent()) {
            PasswordResetToken token = tokenOpt.get();
            if (token.isExpired()) { // Use the new isExpired method
                logger.warn("Password reset token found but expired: {}", plainToken);
                tokenRepository.delete(token); // Clean up expired token
                return Optional.empty();
            }
            logger.debug("Password reset token validated successfully: {}", plainToken);
            return tokenOpt;
        }

        logger.warn("Password reset token not found or invalid: {}", plainToken);
        return Optional.empty();
    }

    @Override
    public Optional<User> getUserByPasswordResetToken(String plainToken) {
        return validatePasswordResetToken(plainToken)
                .map(PasswordResetToken::getUser);
    }

    @Override
    public void invalidateToken(String plainToken) {
        Optional<PasswordResetToken> tokenOpt = tokenRepository.findByTokenHash(plainToken);
        if (tokenOpt.isPresent()) {
            PasswordResetToken token = tokenOpt.get();
            tokenRepository.delete(token);
            logger.info("Invalidated password reset token for user: {}", token.getUser().getEmail());
        } else {
            logger.warn("Attempted to invalidate a token that was not found: {}", plainToken);
        }
    }

    @Override
    // @Scheduled(cron = "0 0 1 * * ?") // Example: Run daily at 1 AM
    public void deleteExpiredTokens() {
        Date now = new Date();
        logger.info("Deleting expired password reset tokens older than {}", now);
        tokenRepository.deleteByExpiryDateLessThan(now); // Adjust method name if needed based on repository definition
    }
}
