package demo.com.example.testserver.service.impl;

import demo.com.example.testserver.model.PasswordResetToken;
import demo.com.example.testserver.model.User;
import demo.com.example.testserver.repository.PasswordResetTokenRepository;
import demo.com.example.testserver.service.PasswordResetTokenService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
@Transactional // Use transactions for operations involving multiple steps
public class PasswordResetTokenServiceImpl implements PasswordResetTokenService {

    private static final Logger logger = LoggerFactory.getLogger(PasswordResetTokenServiceImpl.class);


    @Autowired
    private PasswordResetTokenRepository tokenRepository;

    @Autowired
    private PasswordEncoder passwordEncoder; // Use the same encoder as for passwords

    @Override
    public String createPasswordResetToken(User user) {
        // Invalidate existing token for the user, if any
        tokenRepository.findByUser(user).ifPresent(tokenRepository::delete);

        String plainToken = UUID.randomUUID().toString();
        String tokenHash = passwordEncoder.encode(plainToken); // Hash the token for storage

        PasswordResetToken resetToken = new PasswordResetToken(tokenHash, user);
        tokenRepository.save(resetToken);
        logger.info("Created password reset token for user: {}", user.getEmail());
        return plainToken; // Return the plain token to be sent via email
    }

    @Override
    public Optional<PasswordResetToken> validatePasswordResetToken(String plainToken) {
        // Note: This requires iterating or finding potential matches if not indexed by plain token.
        // A more performant approach might involve a cache or a different lookup strategy.
        // For simplicity here, we iterate, but this is NOT ideal for large numbers of tokens.
        // Consider adding an index on the user_id in PasswordResetToken table.

        // A better approach: Find *all* tokens, hash the input, and compare hashes.
        // This avoids storing plain tokens or needing complex lookups.
        Iterable<PasswordResetToken> allTokens = tokenRepository.findAll(); // Inefficient for large datasets!
        for (PasswordResetToken token : allTokens) {
            if (passwordEncoder.matches(plainToken, token.getTokenHash())) {
                if (token.isExpired()) {
                    logger.warn("Password reset token found but expired: {}", plainToken);
                    tokenRepository.delete(token); // Clean up expired token
                    return Optional.empty();
                }
                logger.debug("Password reset token validated successfully: {}", plainToken);
                return Optional.of(token);
            }
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
         // Find the token by hashing the plain token and comparing hashes
         Iterable<PasswordResetToken> allTokens = tokenRepository.findAll(); // Inefficient
         for (PasswordResetToken token : allTokens) {
             if (passwordEncoder.matches(plainToken, token.getTokenHash())) {
                 tokenRepository.delete(token);
                 logger.info("Invalidated password reset token for user: {}", token.getUser().getEmail());
                 return; // Exit once found and deleted
             }
         }
         logger.warn("Attempted to invalidate a token that was not found: {}", plainToken);
    }

    @Override
    // @Scheduled(cron = "0 0 1 * * ?") // Example: Run daily at 1 AM
    public void deleteExpiredTokens() {
        LocalDateTime now = LocalDateTime.now();
        logger.info("Deleting expired password reset tokens older than {}", now);
        tokenRepository.deleteAllByExpiryDateLessThan(now);
    }
}
