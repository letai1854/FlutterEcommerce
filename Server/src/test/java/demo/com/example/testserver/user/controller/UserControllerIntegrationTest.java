package demo.com.example.testserver.user.controller;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.hamcrest.Matchers.emptyString;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;

import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.model.Address;
import demo.com.example.testserver.user.repository.UserRepository;
import demo.com.example.testserver.user.service.PasswordResetTokenService;
import demo.com.example.testserver.user.dto.UserDTO;
import demo.com.example.testserver.user.dto.RegistrationRequest;

@SpringBootTest // Load full application context
@AutoConfigureMockMvc // Configure MockMvc
@Transactional // Rollback transactions after each test
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper; // For converting objects to JSON

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private PasswordResetTokenService passwordResetTokenService; // Needed for reset password test

    private final String testEmail = "test@example.com";
    private final String testPassword = "password123";
    private final String testFullName = "Test User";
    private final String testAddress = "123 Test Street, Test City";

    @BeforeEach
    void setUp() {
        // Clean up potential leftovers from previous failed tests if @Transactional wasn't effective
        userRepository.deleteAll(); // Cascading delete should handle associated addresses
        // Note: PasswordResetToken cleanup might be needed if not handled by @Transactional or service logic
    }

    // Helper method to create a user directly in DB for testing login, updates etc.
    private User createUserInDb(String email, String password, String fullName, User.UserRole role, User.UserStatus status) {
        User user = new User();
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password)); // Encode password
        user.setFullName(fullName);
        user.setRole(role);
        user.setStatus(status);
        user.setCustomerPoints(BigDecimal.ZERO);
        return userRepository.save(user);
    }

    // Helper method to register and login a user, returning the auth token
    private String registerAndLoginUser(String email, String password, String fullName) throws Exception {
        // Register
        RegistrationRequest registrationRequest = new RegistrationRequest();
        registrationRequest.setEmail(email);
        registrationRequest.setPassword(password);
        registrationRequest.setFullName(fullName);
        registrationRequest.setAddress(testAddress);

        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationRequest)))
                .andExpect(status().isCreated());

        // Login
        Map<String, String> loginCredentials = new HashMap<>();
        loginCredentials.put("email", email);
        loginCredentials.put("password", password);

        MvcResult loginResult = mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginCredentials)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andReturn();

        String responseBody = loginResult.getResponse().getContentAsString();
        Map<String, Object> responseMap = objectMapper.readValue(responseBody, HashMap.class);
        return (String) responseMap.get("token");
    }

    @Test
    void ping_shouldReturnSuccessMessage() throws Exception {
        mockMvc.perform(get("/api/users/ping"))
                .andExpect(status().isOk())
                .andExpect(content().string("Server is up and running"));
    }

    @Test
    void registerUser_whenValid_shouldCreateUserAndAddress() throws Exception {
        RegistrationRequest newUserRequest = new RegistrationRequest();
        newUserRequest.setEmail(testEmail);
        newUserRequest.setPassword(testPassword);
        newUserRequest.setFullName(testFullName);
        newUserRequest.setAddress(testAddress);

        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newUserRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email", is(testEmail)))
                .andExpect(jsonPath("$.fullName", is(testFullName)))
                .andExpect(jsonPath("$.password").doesNotExist())
                .andExpect(jsonPath("$.role", is(User.UserRole.khach_hang.toString())))
                .andExpect(jsonPath("$.status", is(User.UserStatus.kich_hoat.toString())));

        // Verify user exists in DB
        Optional<User> savedUserOpt = userRepository.findByEmail(testEmail);
        assertTrue(savedUserOpt.isPresent(), "User should be saved in DB");
        User savedUser = savedUserOpt.get();
        assertEquals(testEmail, savedUser.getEmail());
        assertEquals(testFullName, savedUser.getFullName());
        assertTrue(passwordEncoder.matches(testPassword, savedUser.getPassword()));

        // Verify address exists in DB and is linked to the user by accessing the user's addresses
        List<Address> addresses = savedUser.getAddresses(); // Get addresses from the user entity
        assertNotNull(addresses, "Addresses list should not be null");
        assertEquals(1, addresses.size(), "User should have one address");
        Address savedAddress = addresses.get(0);
        assertEquals(testFullName, savedAddress.getRecipientName());
        assertEquals("0", savedAddress.getPhoneNumber());
        assertEquals(testAddress, savedAddress.getSpecificAddress());
        assertTrue(savedAddress.getDefault(), "Address should be default");
        assertEquals(savedUser.getId(), savedAddress.getUser().getId());
    }

    @Test
    void registerUser_whenEmailExists_shouldReturnConflict() throws Exception {
        // Arrange: Create an existing user
        createUserInDb(testEmail, "somepassword", "Existing User", User.UserRole.khach_hang, User.UserStatus.kich_hoat);

        // Act & Assert
        RegistrationRequest newUserRequest = new RegistrationRequest();
        newUserRequest.setEmail(testEmail);
        newUserRequest.setPassword(testPassword);
        newUserRequest.setFullName(testFullName);
        newUserRequest.setAddress(testAddress);

        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newUserRequest)))
                .andExpect(status().isConflict())
                .andExpect(content().string("Email already exists"));
    }

    @Test
    void registerUser_whenPasswordMissing_shouldReturnBadRequest() throws Exception {
        RegistrationRequest newUserRequest = new RegistrationRequest();
        newUserRequest.setEmail(testEmail);
        newUserRequest.setFullName(testFullName);
        newUserRequest.setAddress(testAddress);

        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newUserRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void registerUser_whenFullNameMissing_shouldReturnBadRequest() throws Exception {
        RegistrationRequest newUserRequest = new RegistrationRequest();
        newUserRequest.setEmail(testEmail);
        newUserRequest.setPassword(testPassword);
        newUserRequest.setAddress(testAddress);

        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newUserRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void registerUser_whenAddressMissing_shouldReturnBadRequest() throws Exception {
        RegistrationRequest newUserRequest = new RegistrationRequest();
        newUserRequest.setEmail(testEmail);
        newUserRequest.setPassword(testPassword);
        newUserRequest.setFullName(testFullName);

        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newUserRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void registerUser_whenPasswordTooShort_shouldReturnBadRequest() throws Exception {
        RegistrationRequest newUserRequest = new RegistrationRequest();
        newUserRequest.setEmail(testEmail);
        newUserRequest.setPassword("12345");
        newUserRequest.setFullName(testFullName);
        newUserRequest.setAddress(testAddress);

        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newUserRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void registerUser_whenInvalidEmail_shouldReturnBadRequest() throws Exception {
        RegistrationRequest newUserRequest = new RegistrationRequest();
        newUserRequest.setEmail("invalid-email");
        newUserRequest.setPassword(testPassword);
        newUserRequest.setFullName(testFullName);
        newUserRequest.setAddress(testAddress);

        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newUserRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void loginUser_whenValidCredentials_shouldReturnTokenAndUser() throws Exception {
        // Arrange: Create an active user
        createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.kich_hoat);

        Map<String, String> credentials = new HashMap<>();
        credentials.put("email", testEmail);
        credentials.put("password", testPassword);

        // Act & Assert
        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(credentials)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.token", is(not(emptyString()))))
                .andExpect(jsonPath("$.user.email", is(testEmail)))
                .andExpect(jsonPath("$.user.fullName", is(testFullName)))
                .andExpect(jsonPath("$.user.password").doesNotExist());
    }

    @Test
    void loginUser_whenInvalidPassword_shouldReturnUnauthorized() throws Exception {
        // Arrange: Create an active user
        createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.kich_hoat);

        Map<String, String> credentials = new HashMap<>();
        credentials.put("email", testEmail);
        credentials.put("password", "wrongpassword");

        // Act & Assert
        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(credentials)))
                .andExpect(status().isUnauthorized())
                .andExpect(content().string("Invalid credentials or user not active"));
    }

    @Test
    void loginUser_whenUserInactive_shouldReturnUnauthorized() throws Exception {
        // Arrange: Create an inactive user
        createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.khoa);

        Map<String, String> credentials = new HashMap<>();
        credentials.put("email", testEmail);
        credentials.put("password", testPassword);

        // Act & Assert
        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(credentials)))
                .andExpect(status().isUnauthorized())
                .andExpect(content().string("Invalid credentials or user not active"));
    }

    @Test
    void loginUser_whenUserNotFound_shouldReturnUnauthorized() throws Exception {
        // Arrange: No user created

        Map<String, String> credentials = new HashMap<>();
        credentials.put("email", "nonexistent@example.com");
        credentials.put("password", "anypassword");

        // Act & Assert
        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(credentials)))
                .andExpect(status().isUnauthorized())
                .andExpect(content().string("Invalid credentials or user not active"));
    }

    @Test
    void getCurrentUserProfile_whenAuthenticated_shouldReturnUser() throws Exception {
        // Arrange: Register and login to get a token
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);

        // Act & Assert
        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email", is(testEmail)))
                .andExpect(jsonPath("$.fullName", is(testFullName)))
                .andExpect(jsonPath("$.password").doesNotExist());
    }

    @Test
    void getCurrentUserProfile_whenNotAuthenticated_shouldReturnUnauthorized() throws Exception {
        // Act & Assert without token
        mockMvc.perform(get("/api/users/me"))
                .andExpect(status().isForbidden());
    }

    @Test
    void updateCurrentUserProfile_whenAuthenticated_shouldUpdateUser() throws Exception {
        // Arrange: Register and login to get a token
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);
        String newFullName = "Updated Test User";
        String newAvatar = "http://example.com/new_avatar.png";

        Map<String, String> updates = new HashMap<>();
        updates.put("fullName", newFullName);
        updates.put("avatar", newAvatar);

        // Act & Assert
        mockMvc.perform(put("/api/users/me/update")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updates)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email", is(testEmail)))
                .andExpect(jsonPath("$.fullName", is(newFullName)))
                .andExpect(jsonPath("$.avatar", is(newAvatar)))
                .andExpect(jsonPath("$.password").doesNotExist());

        // Verify update in DB
        Optional<User> updatedUser = userRepository.findByEmail(testEmail);
        assertTrue(updatedUser.isPresent());
        assertEquals(newFullName, updatedUser.get().getFullName());
        assertEquals(newAvatar, updatedUser.get().getAvatar());
    }

    @Test
    void changeCurrentUserPassword_whenValid_shouldChangePassword() throws Exception {
        // Arrange: Register and login to get a token
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);
        String newPassword = "newStrongPassword123";

        Map<String, String> passwordChangeRequest = new HashMap<>();
        passwordChangeRequest.put("oldPassword", testPassword);
        passwordChangeRequest.put("newPassword", newPassword);

        // Act & Assert
        mockMvc.perform(post("/api/users/me/change-password")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(passwordChangeRequest)))
                .andExpect(status().isOk())
                .andExpect(content().string("Password changed successfully"));

        // Verify password changed in DB by trying to login with the new password
        Map<String, String> loginCredentials = new HashMap<>();
        loginCredentials.put("email", testEmail);
        loginCredentials.put("password", newPassword);

        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginCredentials)))
                .andExpect(status().isOk());
    }

    @Test
    void changeCurrentUserPassword_whenIncorrectOldPassword_shouldReturnUnauthorized() throws Exception {
        // Arrange: Register and login to get a token
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);
        String newPassword = "newStrongPassword123";

        Map<String, String> passwordChangeRequest = new HashMap<>();
        passwordChangeRequest.put("oldPassword", "wrongOldPassword");
        passwordChangeRequest.put("newPassword", newPassword);

        // Act & Assert
        mockMvc.perform(post("/api/users/me/change-password")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(passwordChangeRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(content().string("Incorrect old password"));
    }

    @Test
    void forgotPassword_whenUserExists_shouldReturnOk() throws Exception {
        // Arrange: Create an active user
        createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.kich_hoat);

        Map<String, String> emailRequest = new HashMap<>();
        emailRequest.put("email", testEmail);

        // Act & Assert
        mockMvc.perform(post("/api/users/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(emailRequest)))
                .andExpect(status().isOk())
                .andExpect(content().string("If an account with that email exists, a password reset link has been sent."));
    }

    @Test
    void forgotPassword_whenUserDoesNotExist_shouldStillReturnOk() throws Exception {
        // Arrange: No user created

        Map<String, String> emailRequest = new HashMap<>();
        emailRequest.put("email", "nonexistent@example.com");

        // Act & Assert
        mockMvc.perform(post("/api/users/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(emailRequest)))
                .andExpect(status().isOk())
                .andExpect(content().string("If an account with that email exists, a password reset link has been sent."));
    }

    @Test
    void resetPassword_whenValidToken_shouldResetPassword() throws Exception {
        // Arrange: Create user and generate a reset token
        User user = createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.kich_hoat);
        String plainToken = passwordResetTokenService.createPasswordResetToken(user);
        String newPassword = "resetPassword123";

        assertNotNull(plainToken, "Failed to generate password reset token");

        Map<String, String> resetRequest = new HashMap<>();
        resetRequest.put("token", plainToken);
        resetRequest.put("newPassword", newPassword);

        // Act & Assert
        mockMvc.perform(post("/api/users/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(resetRequest)))
                .andExpect(status().isOk())
                .andExpect(content().string("Password has been reset successfully."));

        // Verify password changed in DB
        Optional<User> updatedUser = userRepository.findByEmail(testEmail);
        assertTrue(updatedUser.isPresent());
        assertTrue(passwordEncoder.matches(newPassword, updatedUser.get().getPassword()));

        // Verify token is invalidated
        assertFalse(passwordResetTokenService.getUserByPasswordResetToken(plainToken).isPresent(), "Token should be invalidated after use");
    }

    @Test
    void resetPassword_whenInvalidToken_shouldReturnBadRequest() throws Exception {
        // Arrange
        String invalidToken = "invalid-token-123";
        String newPassword = "resetPassword123";

        Map<String, String> resetRequest = new HashMap<>();
        resetRequest.put("token", invalidToken);
        resetRequest.put("newPassword", newPassword);

        // Act & Assert
        mockMvc.perform(post("/api/users/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(resetRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("Invalid or expired password reset token."));
    }

    @Test
    void resetPassword_whenTokenExpired_shouldReturnBadRequest() throws Exception {
        String invalidToken = "expired-or-invalid-token";
        String newPassword = "resetPassword123";

        Map<String, String> resetRequest = new HashMap<>();
        resetRequest.put("token", invalidToken);
        resetRequest.put("newPassword", newPassword);

        mockMvc.perform(post("/api/users/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(resetRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("Invalid or expired password reset token."));
    }
}
