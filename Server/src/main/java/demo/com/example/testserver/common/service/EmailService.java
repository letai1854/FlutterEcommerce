package demo.com.example.testserver.common.service;

public interface EmailService {

    /**
     * Sends a password reset email.
     *
     * @param recipientEmail The email address of the recipient.
     * @param plainToken     The plain (non-hashed) password reset token to include in the link.
     * @param resetLinkBase  The base URL for the password reset link (e.g., "http://yourapp.com/reset-password?token=").
     */
    void sendPasswordResetEmail(String recipientEmail, String plainToken, String resetLinkBase);

    // Add other email sending methods as needed (e.g., registration confirmation)
    // void sendRegistrationConfirmationEmail(String recipientEmail, String confirmationLink);
}
