package demo.com.example.testserver.product.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import demo.com.example.testserver.product.dto.CreateBrandRequestDTO;
import demo.com.example.testserver.product.dto.UpdateBrandRequestDTO;
import demo.com.example.testserver.product.model.Brand;
import demo.com.example.testserver.product.repository.BrandRepository;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class BrandControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private BrandRepository brandRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private User adminUser;
    private User regularUser;

    @BeforeEach
    void setUp() {
        // Clean up
        brandRepository.deleteAll();
        userRepository.deleteAll();

        // Create users
        adminUser = new User();
        adminUser.setEmail("brand.admin@test.com");
        adminUser.setPassword(passwordEncoder.encode("password"));
        adminUser.setFullName("Brand Admin");
        adminUser.setRole(User.UserRole.quan_tri);
        adminUser.setStatus(User.UserStatus.kich_hoat);
        adminUser = userRepository.save(adminUser);

        regularUser = new User();
        regularUser.setEmail("brand.user@test.com");
        regularUser.setPassword(passwordEncoder.encode("password"));
        regularUser.setFullName("Brand User");
        regularUser.setRole(User.UserRole.khach_hang);
        regularUser.setStatus(User.UserStatus.kich_hoat);
        regularUser = userRepository.save(regularUser);
    }

    private Brand createAndSaveBrand(String name) {
        Brand brand = new Brand();
        brand.setName(name);
        return brandRepository.save(brand);
    }

    // --- GET All Brands ---

    @Test
    void getAllBrands_shouldReturnListOfBrands() throws Exception {
        Brand brand1 = createAndSaveBrand("Brand A");
        Brand brand2 = createAndSaveBrand("Brand B");

        mockMvc.perform(get("/api/brands")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].name", is(brand1.getName())))
                .andExpect(jsonPath("$[1].name", is(brand2.getName())));
    }

    @Test
    void getAllBrands_whenNoBrands_shouldReturnNoContent() throws Exception {
        mockMvc.perform(get("/api/brands")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());
    }

    // --- GET Brand By ID ---

    @Test
    void getBrandById_whenExists_shouldReturnBrand() throws Exception {
        Brand brand = createAndSaveBrand("Brand X");

        mockMvc.perform(get("/api/brands/{id}", brand.getId())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(brand.getId().intValue()))) // JSON path expects int for Integer ID
                .andExpect(jsonPath("$.name", is(brand.getName())));
    }

    @Test
    void getBrandById_whenNotFound_shouldReturnNotFound() throws Exception {
        mockMvc.perform(get("/api/brands/{id}", 9999)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }

    // --- CREATE Brand ---

    @Test
    @WithMockUser(username = "brand.admin@test.com", roles = "ADMIN")
    void createBrand_whenAdminUserAndValidRequest_shouldCreateBrand() throws Exception {
        CreateBrandRequestDTO requestDTO = new CreateBrandRequestDTO();
        requestDTO.setName("New Brand");

        mockMvc.perform(post("/api/brands")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name", is("New Brand")))
                .andExpect(jsonPath("$.id").exists());

        List<Brand> brands = brandRepository.findAll();
        assertEquals(1, brands.size());
        assertEquals("New Brand", brands.get(0).getName());
    }

    @Test
    @WithMockUser(username = "brand.admin@test.com", roles = "ADMIN")
    void createBrand_whenAdminUserAndNameBlank_shouldReturnBadRequest() throws Exception {
        CreateBrandRequestDTO requestDTO = new CreateBrandRequestDTO();
        requestDTO.setName(""); // Blank name

        mockMvc.perform(post("/api/brands")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "brand.user@test.com", roles = "KHACH_HANG")
    void createBrand_whenRegularUser_shouldReturnForbidden() throws Exception {
        CreateBrandRequestDTO requestDTO = new CreateBrandRequestDTO();
        requestDTO.setName("Forbidden Brand");

        mockMvc.perform(post("/api/brands")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isForbidden());
    }

    @Test
    void createBrand_whenUnauthenticated_shouldReturnUnauthorized() throws Exception {
        CreateBrandRequestDTO requestDTO = new CreateBrandRequestDTO();
        requestDTO.setName("Unauthorized Brand");

        mockMvc.perform(post("/api/brands")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isUnauthorized()); // Or Forbidden depending on security config
    }

    // --- UPDATE Brand ---

    @Test
    @WithMockUser(username = "brand.admin@test.com", roles = "ADMIN")
    void updateBrand_whenAdminUserAndValidRequest_shouldUpdateBrand() throws Exception {
        Brand existingBrand = createAndSaveBrand("Old Brand Name");
        UpdateBrandRequestDTO requestDTO = new UpdateBrandRequestDTO();
        requestDTO.setName("Updated Brand Name");

        mockMvc.perform(put("/api/brands/{id}", existingBrand.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(existingBrand.getId().intValue())))
                .andExpect(jsonPath("$.name", is("Updated Brand Name")));

        Brand updatedBrand = brandRepository.findById(existingBrand.getId()).orElseThrow();
        assertEquals("Updated Brand Name", updatedBrand.getName());
    }

    @Test
    @WithMockUser(username = "brand.admin@test.com", roles = "ADMIN")
    void updateBrand_whenAdminUserAndNotFound_shouldReturnNotFound() throws Exception {
        UpdateBrandRequestDTO requestDTO = new UpdateBrandRequestDTO();
        requestDTO.setName("Updated Brand Name");

        mockMvc.perform(put("/api/brands/{id}", 9999)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(username = "brand.admin@test.com", roles = "ADMIN")
    void updateBrand_whenAdminUserAndNameBlank_shouldReturnBadRequest() throws Exception {
        Brand existingBrand = createAndSaveBrand("Valid Brand");
        UpdateBrandRequestDTO requestDTO = new UpdateBrandRequestDTO();
        requestDTO.setName(" "); // Blank name

        mockMvc.perform(put("/api/brands/{id}", existingBrand.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "brand.user@test.com", roles = "KHACH_HANG")
    void updateBrand_whenRegularUser_shouldReturnForbidden() throws Exception {
        Brand existingBrand = createAndSaveBrand("Another Brand");
        UpdateBrandRequestDTO requestDTO = new UpdateBrandRequestDTO();
        requestDTO.setName("Forbidden Update");

        mockMvc.perform(put("/api/brands/{id}", existingBrand.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isForbidden());
    }

    @Test
    void updateBrand_whenUnauthenticated_shouldReturnUnauthorized() throws Exception {
        Brand existingBrand = createAndSaveBrand("Yet Another Brand");
        UpdateBrandRequestDTO requestDTO = new UpdateBrandRequestDTO();
        requestDTO.setName("Unauthorized Update");

        mockMvc.perform(put("/api/brands/{id}", existingBrand.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isUnauthorized()); // Or Forbidden
    }

    // --- DELETE Brand ---

    @Test
    @WithMockUser(username = "brand.admin@test.com", roles = "ADMIN")
    void deleteBrand_whenAdminUserAndExists_shouldDeleteBrand() throws Exception {
        Brand brandToDelete = createAndSaveBrand("To Be Deleted");

        mockMvc.perform(delete("/api/brands/{id}", brandToDelete.getId())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());

        assertFalse(brandRepository.findById(brandToDelete.getId()).isPresent());
    }

    @Test
    @WithMockUser(username = "brand.admin@test.com", roles = "ADMIN")
    void deleteBrand_whenAdminUserAndNotFound_shouldReturnNotFound() throws Exception {
        mockMvc.perform(delete("/api/brands/{id}", 9999)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(username = "brand.user@test.com", roles = "KHACH_HANG")
    void deleteBrand_whenRegularUser_shouldReturnForbidden() throws Exception {
        Brand brand = createAndSaveBrand("Protected Brand");

        mockMvc.perform(delete("/api/brands/{id}", brand.getId())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }

    @Test
    void deleteBrand_whenUnauthenticated_shouldReturnUnauthorized() throws Exception {
        Brand brand = createAndSaveBrand("Secure Brand");

        mockMvc.perform(delete("/api/brands/{id}", brand.getId())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized()); // Or Forbidden
    }
}