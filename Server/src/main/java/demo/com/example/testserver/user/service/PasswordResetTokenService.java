package demo.com.example.testserver.user.service;

import java.util.Optional;

import demo.com.example.testserver.user.model.PasswordResetToken;
import demo.com.example.testserver.user.model.User;

public interface PasswordResetTokenService {

    /**
     * Creates a new password reset token for the given user.
     * Handles hashing and saving the token.
     *
     * @param user The user requesting the reset.
     * @return The plain (non-hashed) token generated.
     */
    String createPasswordResetToken(User user);

    /**
     * Validates a plain password reset token.
     * Checks if a token with the corresponding hash exists and is not expired.
     *
     * @param plainToken The plain token received from the user.
     * @return An Optional containing the valid PasswordResetToken entity if found and valid, otherwise empty.
     */
    Optional<PasswordResetToken> validatePasswordResetToken(String plainToken);

    /**
     * Invalidates/deletes a token based on its plain value.
     *
     * @param plainToken The plain token to invalidate.
     */
    void invalidateToken(String plainToken);

    /**
     * Deletes expired tokens. Intended for scheduled cleanup tasks.
     */
    void deleteExpiredTokens();

    /**
     * Retrieves the User associated with a valid token.
     *
     * @param plainToken The plain token.
     * @return An Optional containing the User if the token is valid, otherwise empty.
     */
    Optional<User> getUserByPasswordResetToken(String plainToken);
}
