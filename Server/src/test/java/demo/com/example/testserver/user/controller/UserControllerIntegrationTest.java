package demo.com.example.testserver.user.controller;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.hamcrest.Matchers.emptyString;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;

import demo.com.example.testserver.user.dto.AddressRequestDTO;
import demo.com.example.testserver.user.dto.RegistrationRequest;
import demo.com.example.testserver.user.model.Address;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.AddressRepository;
import demo.com.example.testserver.user.repository.UserRepository;
import demo.com.example.testserver.user.service.PasswordResetTokenService;
import jakarta.persistence.EntityManager;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AddressRepository addressRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private PasswordResetTokenService passwordResetTokenService;

    @Autowired
    private EntityManager entityManager; // Inject EntityManager

    private final String testEmail = "test@example.com";
    private final String testPassword = "password123";
    private final String testFullName = "Test User";
    private final String testAddress = "123 Test Street, Test City";
    private final String adminEmail = "admin@example.com";
    private final String adminPassword = "adminPassword123";
    private final String adminFullName = "Admin User";

    @BeforeEach
    void setUp() {
        addressRepository.deleteAll();
        userRepository.deleteAll();
    }

    private User createUserInDb(String email, String password, String fullName, User.UserRole role, User.UserStatus status) {
        User user = new User();
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password));
        user.setFullName(fullName);
        user.setRole(role);
        user.setStatus(status);
        user.setCustomerPoints(BigDecimal.ZERO);
        return userRepository.save(user);
    }

    private User createAdminInDb(String email, String password, String fullName) {
        return createUserInDb(email, password, fullName, User.UserRole.quan_tri, User.UserStatus.kich_hoat);
    }

    private String registerAndLoginUser(String email, String password, String fullName) throws Exception {
        RegistrationRequest registrationRequest = new RegistrationRequest();
        registrationRequest.setEmail(email);
        registrationRequest.setPassword(password);
        registrationRequest.setFullName(fullName);
        registrationRequest.setAddress(testAddress);

        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationRequest)))
                .andExpect(status().isCreated());

        return loginUser(email, password);
    }

    private String loginUser(String email, String password) throws Exception {
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

    private String registerAndLoginAdmin() throws Exception {
        createAdminInDb(adminEmail, adminPassword, adminFullName);
        return loginUser(adminEmail, adminPassword);
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

        Optional<User> savedUserOpt = userRepository.findByEmail(testEmail);
        assertTrue(savedUserOpt.isPresent(), "User should be saved in DB");
        User savedUser = savedUserOpt.get();
        assertEquals(testEmail, savedUser.getEmail());
        assertEquals(testFullName, savedUser.getFullName());
        assertTrue(passwordEncoder.matches(testPassword, savedUser.getPassword()));

        User refreshedUser = userRepository.findById(savedUser.getId()).orElseThrow();
        List<Address> addresses = refreshedUser.getAddresses();
        assertNotNull(addresses, "Addresses list should not be null");
        assertEquals(1, addresses.size(), "User should have one address");
        Address savedAddress = addresses.get(0);
        assertEquals(testFullName, savedAddress.getRecipientName());
        assertEquals(testAddress, savedAddress.getSpecificAddress());
        assertTrue(savedAddress.getDefault(), "Address should be default");
        assertEquals(savedUser.getId(), savedAddress.getUser().getId());
    }

    @Test
    void loginUser_whenValidCredentials_shouldReturnTokenAndUser() throws Exception {
        createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.kich_hoat);

        Map<String, String> credentials = new HashMap<>();
        credentials.put("email", testEmail);
        credentials.put("password", testPassword);

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
    void getCurrentUserProfile_whenAuthenticated_shouldReturnUser() throws Exception {
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);

        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email", is(testEmail)))
                .andExpect(jsonPath("$.fullName", is(testFullName)))
                .andExpect(jsonPath("$.password").doesNotExist());
    }

    @Test
    void updateCurrentUserProfile_whenAuthenticated_shouldUpdateUser() throws Exception {
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);
        String newFullName = "Updated Test User";
        String newAvatar = "http://example.com/new_avatar.png";

        Map<String, String> updates = new HashMap<>();
        updates.put("fullName", newFullName);
        updates.put("avatar", newAvatar);

        mockMvc.perform(put("/api/users/me/update")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updates)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email", is(testEmail)))
                .andExpect(jsonPath("$.fullName", is(newFullName)))
                .andExpect(jsonPath("$.avatar", is(newAvatar)))
                .andExpect(jsonPath("$.password").doesNotExist());

        Optional<User> updatedUser = userRepository.findByEmail(testEmail);
        assertTrue(updatedUser.isPresent());
        assertEquals(newFullName, updatedUser.get().getFullName());
        assertEquals(newAvatar, updatedUser.get().getAvatar());
    }

    @Test
    void changeCurrentUserPassword_whenValid_shouldChangePassword() throws Exception {
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);
        String newPassword = "newStrongPassword123";

        Map<String, String> passwordChangeRequest = new HashMap<>();
        passwordChangeRequest.put("oldPassword", testPassword);
        passwordChangeRequest.put("newPassword", newPassword);

        mockMvc.perform(post("/api/users/me/change-password")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(passwordChangeRequest)))
                .andExpect(status().isOk())
                .andExpect(content().string("Password changed successfully"));

        Map<String, String> loginCredentials = new HashMap<>();
        loginCredentials.put("email", testEmail);
        loginCredentials.put("password", newPassword);

        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginCredentials)))
                .andExpect(status().isOk());
    }

    @Test
    void forgotPassword_whenUserExists_shouldReturnOk() throws Exception {
        createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.kich_hoat);

        Map<String, String> emailRequest = new HashMap<>();
        emailRequest.put("email", testEmail);

        mockMvc.perform(post("/api/users/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(emailRequest)))
                .andExpect(status().isOk())
                .andExpect(content().string("If an account with that email exists and is active, a password reset OTP has been sent."));
    }

    @Test
    void resetPassword_whenValidToken_shouldResetPassword() throws Exception {
        User user = createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.kich_hoat);
        String plainOtp = passwordResetTokenService.createPasswordResetToken(user);
        String newPassword = "resetPassword123";

        assertNotNull(plainOtp, "Failed to generate password reset OTP");

        Map<String, String> resetRequest = new HashMap<>();
        resetRequest.put("email", testEmail);
        resetRequest.put("otp", plainOtp);
        resetRequest.put("newPassword", newPassword);

        mockMvc.perform(post("/api/users/set-new-password")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(resetRequest)))
                .andExpect(status().isOk())
                .andExpect(content().string("Password has been reset successfully."));

        Optional<User> updatedUser = userRepository.findByEmail(testEmail);
        assertTrue(updatedUser.isPresent());
        assertTrue(passwordEncoder.matches(newPassword, updatedUser.get().getPassword()));

        assertFalse(passwordResetTokenService.getUserByPasswordResetToken(plainOtp).isPresent(), "OTP should be invalidated after use");
    }

    @Test
    void getCurrentUserAddresses_whenAuthenticated_shouldReturnAddresses() throws Exception {
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);

        mockMvc.perform(get("/api/addresses/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].specificAddress", is(testAddress)))
                .andExpect(jsonPath("$[0].recipientName", is(testFullName)))
                .andExpect(jsonPath("$[0].isDefault", is(true))); // Changed from default to isDefault
    }

    @Test
    void addAddressForCurrentUser_whenAuthenticated_shouldCreateAddress() throws Exception {
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);
        AddressRequestDTO newAddressRequest = new AddressRequestDTO();
        newAddressRequest.setRecipientName("New Recipient");
        newAddressRequest.setPhoneNumber("987654321");
        newAddressRequest.setSpecificAddress("456 New Avenue");
        newAddressRequest.setIsDefault(false);

        mockMvc.perform(post("/api/addresses/me")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newAddressRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.recipientName", is("New Recipient")))
                .andExpect(jsonPath("$.phoneNumber", is("987654321")))
                .andExpect(jsonPath("$.specificAddress", is("456 New Avenue")))
                .andExpect(jsonPath("$.isDefault", is(false))); // Changed from default to isDefault

        User user = userRepository.findByEmail(testEmail).orElseThrow(); // Get user ID needed for fetching

        // Force clear persistence context and re-fetch
        entityManager.flush(); // Ensure pending changes are written to the database
        entityManager.clear(); // Detach all managed entities to force reload from DB

        User refreshedUser = userRepository.findById(user.getId()).orElseThrow(); // Fetch fresh from DB
        assertNotNull(refreshedUser.getAddresses(), "Addresses list should not be null after refresh"); // Optional: Add extra check
        assertEquals(2, refreshedUser.getAddresses().size(), "User should now have two addresses");
    }

    @Test
    void updateAddressForCurrentUser_whenAuthenticated_shouldUpdateAddress() throws Exception {
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);
        User user = userRepository.findByEmail(testEmail).orElseThrow();
        User refreshedUser = userRepository.findById(user.getId()).orElseThrow();
        Integer addressId = refreshedUser.getAddresses().stream().filter(Address::getDefault).findFirst().orElseThrow().getId();

        AddressRequestDTO updateRequest = new AddressRequestDTO();
        updateRequest.setRecipientName("Updated Recipient");
        updateRequest.setPhoneNumber("111222333");
        updateRequest.setSpecificAddress("789 Updated Lane");
        updateRequest.setIsDefault(true);

        mockMvc.perform(put("/api/addresses/me/{addressId}", addressId)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(addressId)))
                .andExpect(jsonPath("$.recipientName", is("Updated Recipient")))
                .andExpect(jsonPath("$.phoneNumber", is("111222333")))
                .andExpect(jsonPath("$.specificAddress", is("789 Updated Lane")))
                .andExpect(jsonPath("$.isDefault", is(true))); // Changed from default to isDefault

        Address updatedAddress = addressRepository.findById(addressId).orElseThrow();
        assertEquals("Updated Recipient", updatedAddress.getRecipientName());
    }

    @Test
    void deleteAddressForCurrentUser_whenAuthenticated_shouldDeleteAddress() throws Exception {
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);
        User user = userRepository.findByEmail(testEmail).orElseThrow();

        Address secondAddress = new Address();
        secondAddress.setUser(user);
        secondAddress.setRecipientName("ToDelete");
        secondAddress.setPhoneNumber("0000000000");
        secondAddress.setSpecificAddress("Delete Me St");
        secondAddress.setDefault(false);
        Address savedSecondAddress = addressRepository.save(secondAddress);
        Integer addressIdToDelete = savedSecondAddress.getId();

        // Force clear persistence context and re-fetch before checking count
        entityManager.flush();
        entityManager.clear();

        User userBeforeDelete = userRepository.findById(user.getId()).orElseThrow();
        assertEquals(2, userBeforeDelete.getAddresses().size(), "User should have two addresses before delete");

        mockMvc.perform(delete("/api/addresses/me/{addressId}", addressIdToDelete)
                        .header("Authorization", "Bearer " + token)
                        .with(csrf()))
                .andExpect(status().isNoContent());

        // Force flush after the delete request to ensure orphanRemoval triggers SQL DELETE
        entityManager.flush();

        assertFalse(addressRepository.findById(addressIdToDelete).isPresent(), "Address should be deleted from repository");

        // Force clear persistence context before final check
        entityManager.clear();

        // Fetch the user again to pass to the repository query
        User userAfterDeleteCheck = userRepository.findById(user.getId()).orElseThrow();
        // Directly query the repository for the current state of addresses for the user
        List<Address> remainingAddresses = addressRepository.findByUser(userAfterDeleteCheck);

        assertEquals(1, remainingAddresses.size(), "User should have only one address left in repository");
    }

    @Test
    void setDefaultAddressForCurrentUser_whenAuthenticated_shouldSetDefault() throws Exception {
        String token = registerAndLoginUser(testEmail, testPassword, testFullName);
        User user = userRepository.findByEmail(testEmail).orElseThrow();

        Address secondAddress = new Address();
        secondAddress.setUser(user);
        secondAddress.setRecipientName("MakeDefault");
        secondAddress.setPhoneNumber("1110002224");
        secondAddress.setSpecificAddress("Default Me St");
        secondAddress.setDefault(false);
        Address savedSecondAddress = addressRepository.save(secondAddress);
        Integer addressIdToSetDefault = savedSecondAddress.getId();

        // Force clear persistence context and re-fetch before getting original default
        entityManager.flush();
        entityManager.clear();

        User refreshedUserBeforePatch = userRepository.findById(user.getId()).orElseThrow();
        assertEquals(2, refreshedUserBeforePatch.getAddresses().size(), "User should have two addresses before setting default");
        Integer originalDefaultId = refreshedUserBeforePatch.getAddresses().stream()
                                        .filter(Address::getDefault)
                                        .findFirst()
                                        .orElseThrow(() -> new IllegalStateException("No default address found before patch"))
                                        .getId();
        assertNotEquals(originalDefaultId, addressIdToSetDefault);

        mockMvc.perform(patch("/api/addresses/me/{addressId}/default", addressIdToSetDefault)
                        .header("Authorization", "Bearer " + token)
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(content().string("Address set as default successfully."));

        // Clear context and re-fetch addresses to ensure we get the updated state from DB
        entityManager.flush();
        entityManager.clear();

        Address newlyDefaultAddress = addressRepository.findById(addressIdToSetDefault).orElseThrow();
        assertTrue(newlyDefaultAddress.getDefault(), "Second address should now be default");

        Address originalDefaultAddress = addressRepository.findById(originalDefaultId).orElseThrow();
        assertFalse(originalDefaultAddress.getDefault(), "Original default address should no longer be default");
    }

    @Test
    void adminGetAllUsers_whenAdmin_shouldReturnUserList() throws Exception {
        createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.kich_hoat);
        String adminToken = registerAndLoginAdmin();

        mockMvc.perform(get("/api/users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(2))))
                .andExpect(jsonPath("$[?(@.email == '%s')]", testEmail).exists())
                .andExpect(jsonPath("$[?(@.email == '%s')]", adminEmail).exists());
    }

    @Test
    void adminSearchUsers_whenAdmin_shouldReturnFilteredUsers() throws Exception {
        createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.kich_hoat);
        createUserInDb("another@example.com", "pass", "Another User", User.UserRole.khach_hang, User.UserStatus.kich_hoat);
        String adminToken = registerAndLoginAdmin();

        mockMvc.perform(get("/api/users/search")
                        .param("email", "another")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)))
                .andExpect(jsonPath("$.content[0].email", is("another@example.com")));

        mockMvc.perform(get("/api/users/search")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(greaterThanOrEqualTo(2))));
    }

    @Test
    void adminGetUserById_whenAdmin_shouldReturnUser() throws Exception {
        User user = createUserInDb(testEmail, testPassword, testFullName, User.UserRole.khach_hang, User.UserStatus.kich_hoat);
        Integer userId = user.getId();
        String adminToken = registerAndLoginAdmin();

        mockMvc.perform(get("/api/users/{id}", userId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(userId)))
                .andExpect(jsonPath("$.email", is(testEmail)))
                .andExpect(jsonPath("$.fullName", is(testFullName)));
    }
}
