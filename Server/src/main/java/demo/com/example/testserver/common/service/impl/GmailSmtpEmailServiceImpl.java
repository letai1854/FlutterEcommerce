package demo.com.example.testserver.common.service.impl;

import demo.com.example.testserver.common.service.EmailService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class GmailSmtpEmailServiceImpl implements EmailService {

    private static final Logger logger = LoggerFactory.getLogger(GmailSmtpEmailServiceImpl.class);

    @Autowired
    private JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    @Override
    public void sendPasswordResetEmail(String recipientEmail, String plainToken, String resetLinkBase) {
        // This method can be implemented if a link-based reset is also needed.
        // For now, focusing on OTP.
        logger.info("sendPasswordResetEmail called, but OTP method is primary for this implementation.");
        String resetLink = resetLinkBase + plainToken;
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(recipientEmail);
        message.setSubject("Password Reset Request");
        message.setText("To reset your password, click the link below:\n" + resetLink +
                        "\nIf you did not request a password reset, please ignore this email.");
        try {
            mailSender.send(message);
            logger.info("Password reset link email sent successfully to {}", recipientEmail);
        } catch (MailException e) {
            logger.error("Error sending password reset link email to {}: {}", recipientEmail, e.getMessage(), e);
            // Consider re-throwing a custom exception or handling accordingly
        }
    }

    @Override
    public void sendPasswordResetOtp(String to, String otpCode) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(to);
        message.setSubject("Your Password Reset OTP");
        message.setText("Your OTP code for password reset is: " + otpCode +
                        "\nThis OTP is valid for a limited time." +
                        "\nIf you did not request this, please ignore this email.");
        try {
            mailSender.send(message);
            logger.info("Password reset OTP sent successfully to {}", to);
        } catch (MailException e) {
            logger.error("Error sending password reset OTP to {}: {}", to, e.getMessage(), e);
            // Consider re-throwing a custom exception or handling accordingly
        }
    }

    @Override
    public void sendRegistrationEmail(String recipientEmail, String fullName, String password) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(recipientEmail);
        message.setSubject("Welcome to Our Service! Your Account Details");
        message.setText("Hello " + fullName + ",\n\n" +
                        "Welcome! Your account has been successfully created.\n\n" +
                        "Here are your login details:\n" +
                        "Email: " + recipientEmail + "\n" +
                        "Password: " + password + "\n\n" +
                        "We strongly recommend that you change your password after your first login for security reasons.\n\n" +
                        "Thank you for joining us!");
        try {
            mailSender.send(message);
            logger.info("Registration email sent successfully to {}", recipientEmail);
        } catch (MailException e) {
            logger.error("Error sending registration email to {}: {}", recipientEmail, e.getMessage(), e);
            // Consider re-throwing a custom exception or handling accordingly
        }
    }

    @Override
    public void sendOrderConfirmationEmail(String recipientEmail, String fullName, Integer orderId, java.math.BigDecimal totalAmount) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(recipientEmail);
        message.setSubject("Your Order #" + orderId + " has been Confirmed!");
        message.setText("Hello " + fullName + ",\n\n" +
                        "Thank you for your order!\n\n" +
                        "Your Order ID: " + orderId + "\n" +
                        "Total Amount: " + totalAmount.toString() + "\n\n" +
                        "We will notify you once your order has been shipped.\n\n" +
                        "Thank you for shopping with us!");
        try {
            mailSender.send(message);
            logger.info("Order confirmation email sent successfully to {} for order ID {}", recipientEmail, orderId);
        } catch (MailException e) {
            logger.error("Error sending order confirmation email to {} for order ID {}: {}", recipientEmail, orderId, e.getMessage(), e);
            // Consider re-throwing a custom exception or handling accordingly
        }
    }
}
