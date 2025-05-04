package demo.com.example.testserver.user.service;

import java.util.Optional;

import demo.com.example.testserver.user.model.PasswordResetToken;
import demo.com.example.testserver.user.model.User;

public interface PasswordResetTokenService {

    /**
     * Creates a new password reset OTP (One-Time Password) for the given user.
     * Handles generating the OTP, hashing it, and saving the token entity.
     *
     * @param user The user requesting the reset.
     * @return The plain 6-digit OTP code generated (to be sent via email).
     */
    String createPasswordResetToken(User user);

    /**
     * Validates a plain password reset OTP code.
     * Checks if a token with the corresponding hash exists and is not expired.
     *
     * @param plainOtp The plain 6-digit OTP code received from the user.
     * @return An Optional containing the valid PasswordResetToken entity if found and valid, otherwise empty.
     */
    Optional<PasswordResetToken> validatePasswordResetToken(String plainOtp);

    /**
     * Invalidates/deletes a token based on its plain OTP value.
     *
     * @param plainOtp The plain 6-digit OTP code to invalidate.
     */
    void invalidateToken(String plainOtp);

    /**
     * Deletes expired tokens. Intended for scheduled cleanup tasks.
     */
    void deleteExpiredTokens();

    /**
     * Retrieves the User associated with a valid OTP code.
     *
     * @param plainOtp The plain 6-digit OTP code.
     * @return An Optional containing the User if the OTP is valid, otherwise empty.
     */
    Optional<User> getUserByPasswordResetToken(String plainOtp);
}
