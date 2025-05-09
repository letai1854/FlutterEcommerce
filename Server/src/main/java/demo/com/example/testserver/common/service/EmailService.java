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

    /**
     * Sends an email containing the 6-digit password reset OTP code.
     * @param to Recipient email address.
     * @param otpCode The plain 6-digit OTP code.
     */
    void sendPasswordResetOtp(String to, String otpCode);

    /**
     * Sends a registration confirmation email with login credentials.
     * @param recipientEmail The email address of the new user.
     * @param fullName The full name of the new user.
     * @param password The plain text password for the new user (advise to change).
     */
    void sendRegistrationEmail(String recipientEmail, String fullName, String password);

    /**
     * Sends an order confirmation email to the user.
     * @param recipientEmail The email address of the user.
     * @param fullName The full name of the user.
     * @param orderId The ID of the confirmed order.
     * @param totalAmount The total amount of the order.
     */
    void sendOrderConfirmationEmail(String recipientEmail, String fullName, Integer orderId, java.math.BigDecimal totalAmount);

    // Add other email sending methods as needed (e.g., registration confirmation)
    // void sendRegistrationConfirmationEmail(String recipientEmail, String confirmationLink);
}
