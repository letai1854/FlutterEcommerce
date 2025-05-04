package demo.com.example.testserver.user.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import demo.com.example.testserver.common.service.EmailService;
import demo.com.example.testserver.user.model.PasswordResetToken;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.PasswordResetTokenRepository;
import demo.com.example.testserver.user.repository.UserRepository;
import demo.com.example.testserver.user.service.PasswordResetTokenService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class UserControllerPasswordResetTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private UserRepository userRepository;

    @MockBean
    private PasswordResetTokenRepository tokenRepository;

    @MockBean
    private PasswordResetTokenService passwordResetTokenService;

    @MockBean
    private EmailService emailService;

    @MockBean
    private PasswordEncoder passwordEncoder;

    private User testUser;
    private PasswordResetToken testToken;
    private final String testEmail = "test@example.com";
    private final String testOtp = "123456";
    private final String hashedOtp = "hashedOtp123"; // Placeholder for mocked hash

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1);
        testUser.setEmail(testEmail);
        when(passwordEncoder.encode("oldPassword")).thenReturn("hashedOldPassword");
        testUser.setPassword(passwordEncoder.encode("oldPassword"));
        testUser.setStatus(User.UserStatus.kich_hoat);

        // Create a non-expired date
        long nowMillis = System.currentTimeMillis();
        Date expiryDate = new Date(nowMillis + 15 * 60 * 1000); // 15 minutes from now

        testToken = new PasswordResetToken(hashedOtp, testUser, expiryDate);
        testToken.setId(1L);
    }

    // --- Tests for /forgot-password ---

    @Test
    void forgotPassword_UserExists_ShouldSendOtpAndReturnOk() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", testEmail);

        when(userRepository.findActiveUserByEmail(testEmail)).thenReturn(Optional.of(testUser));
        when(passwordResetTokenService.createPasswordResetToken(testUser)).thenReturn(testOtp);
        // Mock email service to do nothing successfully
        doNothing().when(emailService).sendPasswordResetOtp(testEmail, testOtp);

        mockMvc.perform(post("/api/users/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(content().string("If an account with that email exists and is active, a password reset OTP has been sent."));

        verify(passwordResetTokenService).createPasswordResetToken(testUser);
        verify(emailService).sendPasswordResetOtp(testEmail, testOtp);
    }

    @Test
    void forgotPassword_UserNotFound_ShouldReturnOk() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", "notfound@example.com");

        when(userRepository.findActiveUserByEmail("notfound@example.com")).thenReturn(Optional.empty());

        mockMvc.perform(post("/api/users/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(content().string("If an account with that email exists and is active, a password reset OTP has been sent."));

        // Verify service methods were NOT called
        verify(passwordResetTokenService, never()).createPasswordResetToken(any());
        verify(emailService, never()).sendPasswordResetOtp(anyString(), anyString());
    }

    @Test
    void forgotPassword_MissingEmail_ShouldReturnBadRequest() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        // requestBody.put("email", testEmail); // Email is missing

        mockMvc.perform(post("/api/users/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("Email is required"));
    }

    // --- Tests for /verify-otp ---

    @Test
    void verifyOtp_ValidOtp_ShouldReturnOk() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", testEmail);
        requestBody.put("otp", testOtp);

        when(userRepository.findActiveUserByEmail(testEmail)).thenReturn(Optional.of(testUser));
        when(tokenRepository.findByUser(testUser)).thenReturn(Optional.of(testToken));
        // Mock passwordEncoder.matches to return true for the correct OTP and hash
        when(passwordEncoder.matches(testOtp, hashedOtp)).thenReturn(true);
        // Ensure token is not expired (already set in setUp)

        mockMvc.perform(post("/api/users/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(content().string("OTP verified successfully."));

        verify(userRepository).findActiveUserByEmail(testEmail);
        verify(tokenRepository).findByUser(testUser);
        verify(passwordEncoder).matches(testOtp, hashedOtp);
        verify(tokenRepository, never()).delete(any()); // Should not delete on successful verification
    }

    @Test
    void verifyOtp_InvalidOtp_ShouldReturnBadRequest() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", testEmail);
        requestBody.put("otp", "wrongotp");

        when(userRepository.findActiveUserByEmail(testEmail)).thenReturn(Optional.of(testUser));
        when(tokenRepository.findByUser(testUser)).thenReturn(Optional.of(testToken));
        // Mock passwordEncoder.matches to return false for the wrong OTP
        when(passwordEncoder.matches("wrongotp", hashedOtp)).thenReturn(false);

        mockMvc.perform(post("/api/users/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("Invalid OTP or email."));

         verify(passwordEncoder).matches("wrongotp", hashedOtp);
         verify(tokenRepository, never()).delete(any());
    }

     @Test
    void verifyOtp_ExpiredOtp_ShouldReturnBadRequestAndDeleteToken() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", testEmail);
        requestBody.put("otp", testOtp);

        // Make token expired
        testToken.setExpiryDate(new Date(System.currentTimeMillis() - 1000)); // 1 second in the past

        when(userRepository.findActiveUserByEmail(testEmail)).thenReturn(Optional.of(testUser));
        when(tokenRepository.findByUser(testUser)).thenReturn(Optional.of(testToken));
        when(passwordEncoder.matches(testOtp, hashedOtp)).thenReturn(true); // Assume OTP matches hash

        mockMvc.perform(post("/api/users/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("OTP has expired."));

        verify(passwordEncoder).matches(testOtp, hashedOtp); // Still checks match before expiry
        verify(tokenRepository).delete(testToken); // Verify expired token is deleted
    }

    @Test
    void verifyOtp_TokenNotFound_ShouldReturnBadRequest() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", testEmail);
        requestBody.put("otp", testOtp);

        when(userRepository.findActiveUserByEmail(testEmail)).thenReturn(Optional.of(testUser));
        // Mock token repository to return empty optional
        when(tokenRepository.findByUser(testUser)).thenReturn(Optional.empty());

        mockMvc.perform(post("/api/users/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("Invalid OTP or email."));

        verify(tokenRepository).findByUser(testUser);
        verify(passwordEncoder, never()).matches(anyString(), anyString());
        verify(tokenRepository, never()).delete(any());
    }

     @Test
    void verifyOtp_UserNotFound_ShouldReturnBadRequest() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", "notfound@example.com");
        requestBody.put("otp", testOtp);

        when(userRepository.findActiveUserByEmail("notfound@example.com")).thenReturn(Optional.empty());

        mockMvc.perform(post("/api/users/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("Invalid OTP or email."));

        verify(tokenRepository, never()).findByUser(any());
        verify(passwordEncoder, never()).matches(anyString(), anyString());
        verify(tokenRepository, never()).delete(any());
    }

    // --- Tests for /set-new-password ---

    @Test
    void setNewPassword_ValidRequest_ShouldResetPasswordAndDeleteToken() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", testEmail);
        requestBody.put("otp", testOtp);
        requestBody.put("newPassword", "newSecurePassword");

        when(userRepository.findActiveUserByEmail(testEmail)).thenReturn(Optional.of(testUser));
        when(tokenRepository.findByUser(testUser)).thenReturn(Optional.of(testToken));
        when(passwordEncoder.matches(testOtp, hashedOtp)).thenReturn(true);
        // Mock the encoding of the new password
        when(passwordEncoder.encode("newSecurePassword")).thenReturn("hashedNewPassword");

        mockMvc.perform(post("/api/users/set-new-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(content().string("Password has been reset successfully."));

        verify(userRepository).findActiveUserByEmail(testEmail);
        verify(tokenRepository).findByUser(testUser);
        verify(passwordEncoder).matches(testOtp, hashedOtp);
        verify(passwordEncoder).encode("newSecurePassword");
        // Verify user's password was updated and saved
        verify(userRepository).save(argThat(user -> user.getPassword().equals("hashedNewPassword")));
        // Verify token was deleted
        verify(tokenRepository).delete(testToken);
    }

    @Test
    void setNewPassword_InvalidOtp_ShouldReturnBadRequest() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", testEmail);
        requestBody.put("otp", "wrongotp");
        requestBody.put("newPassword", "newSecurePassword");

        when(userRepository.findActiveUserByEmail(testEmail)).thenReturn(Optional.of(testUser));
        when(tokenRepository.findByUser(testUser)).thenReturn(Optional.of(testToken));
        when(passwordEncoder.matches("wrongotp", hashedOtp)).thenReturn(false); // OTP doesn't match

        mockMvc.perform(post("/api/users/set-new-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("Invalid OTP or email."));

        verify(passwordEncoder).matches("wrongotp", hashedOtp);
        verify(userRepository, never()).save(any());
        verify(tokenRepository, never()).delete(any());
    }

    @Test
    void setNewPassword_ExpiredOtp_ShouldReturnBadRequestAndDeleteToken() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", testEmail);
        requestBody.put("otp", testOtp);
        requestBody.put("newPassword", "newSecurePassword");

        // Make token expired
        testToken.setExpiryDate(new Date(System.currentTimeMillis() - 1000));

        when(userRepository.findActiveUserByEmail(testEmail)).thenReturn(Optional.of(testUser));
        when(tokenRepository.findByUser(testUser)).thenReturn(Optional.of(testToken));
        when(passwordEncoder.matches(testOtp, hashedOtp)).thenReturn(true); // Assume OTP matches hash

        mockMvc.perform(post("/api/users/set-new-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("OTP has expired. Please request a new one."));

        verify(passwordEncoder).matches(testOtp, hashedOtp);
        verify(tokenRepository).delete(testToken); // Verify expired token is deleted
        verify(userRepository, never()).save(any());
    }

     @Test
    void setNewPassword_PasswordTooShort_ShouldReturnBadRequest() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", testEmail);
        requestBody.put("otp", testOtp);
        requestBody.put("newPassword", "123"); // Too short

        // No need for mocks here as validation happens early

        mockMvc.perform(post("/api/users/set-new-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("New password must be at least 6 characters long."));

        verify(userRepository, never()).save(any());
        verify(tokenRepository, never()).delete(any());
    }

     @Test
    void setNewPassword_MissingData_ShouldReturnBadRequest() throws Exception {
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("email", testEmail);
        // requestBody.put("otp", testOtp); // OTP missing
        requestBody.put("newPassword", "newSecurePassword");

        mockMvc.perform(post("/api/users/set-new-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("Email, OTP, and new password are required."));
    }
}
