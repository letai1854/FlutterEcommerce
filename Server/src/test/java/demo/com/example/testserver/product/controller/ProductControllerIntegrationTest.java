package demo.com.example.testserver.product.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import demo.com.example.testserver.product.dto.CreateProductRequestDTO;
import demo.com.example.testserver.product.dto.CreateProductVariantDTO;
import demo.com.example.testserver.product.model.Brand;
import demo.com.example.testserver.product.model.Category;
import demo.com.example.testserver.product.model.Product;
import demo.com.example.testserver.product.model.ProductImage;
import demo.com.example.testserver.product.model.ProductVariant;
import demo.com.example.testserver.product.repository.BrandRepository;
import demo.com.example.testserver.product.repository.CategoryRepository;
import demo.com.example.testserver.product.repository.ProductRepository;
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
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class ProductControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private BrandRepository brandRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private Category testCategory;
    private Brand testBrand;
    private User adminUser;
    private User regularUser;

    @BeforeEach
    void setUp() {
        // Clean up existing data
        productRepository.deleteAll();
        userRepository.deleteAll();
        categoryRepository.deleteAll();
        brandRepository.deleteAll();

        // Create necessary entities for tests
        testCategory = new Category();
        testCategory.setName("Test Category");
        testCategory.setImageUrl("cat.jpg");
        testCategory = categoryRepository.save(testCategory);

        testBrand = new Brand();
        testBrand.setName("Test Brand");
        testBrand = brandRepository.save(testBrand);

        // Create test users
        adminUser = new User();
        adminUser.setEmail("admin@test.com");
        adminUser.setPassword(passwordEncoder.encode("password"));
        adminUser.setFullName("Admin User");
        adminUser.setRole(User.UserRole.quan_tri);
        adminUser.setStatus(User.UserStatus.kich_hoat);
        adminUser = userRepository.save(adminUser);

        regularUser = new User();
        regularUser.setEmail("user@test.com");
        regularUser.setPassword(passwordEncoder.encode("password"));
        regularUser.setFullName("Regular User");
        regularUser.setRole(User.UserRole.khach_hang);
        regularUser.setStatus(User.UserStatus.kich_hoat);
        regularUser = userRepository.save(regularUser);
    }

    private CreateProductRequestDTO createValidRequestDTO() {
        CreateProductVariantDTO variant1 = new CreateProductVariantDTO();
        variant1.setName("Red - Small");
        variant1.setPrice(new BigDecimal("19.99"));
        variant1.setStockQuantity(100);
        variant1.setVariantImageUrl("red_small.jpg");

        CreateProductVariantDTO variant2 = new CreateProductVariantDTO();
        variant2.setName("Blue - Large");
        variant2.setPrice(new BigDecimal("21.99"));
        variant2.setStockQuantity(50);

        CreateProductRequestDTO requestDTO = new CreateProductRequestDTO();
        requestDTO.setName("Test Product");
        requestDTO.setDescription("A great test product");
        requestDTO.setCategoryId(testCategory.getId().longValue());
        requestDTO.setBrandId(testBrand.getId().longValue());
        requestDTO.setMainImageUrl("main.jpg");
        requestDTO.setImageUrls(Arrays.asList("img1.jpg", "img2.jpg"));
        requestDTO.setDiscountPercentage(new BigDecimal("10.00"));
        requestDTO.setVariants(Arrays.asList(variant1, variant2));
        return requestDTO;
    }

    @Test
    void createProduct_whenAdminUserAndValidRequest_shouldCreateProduct() throws Exception {
        CreateProductRequestDTO requestDTO = createValidRequestDTO();

        mockMvc.perform(post("/api/products/create")
                        .with(SecurityMockMvcRequestPostProcessors.user(adminUser.getEmail()).roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isCreated())
                .andExpect(header().exists("Location"))
                .andExpect(jsonPath("$.id").exists())
                .andExpect(jsonPath("$.name", is("Test Product")));

        List<Product> products = productRepository.findAll();
        assertEquals(1, products.size());
    }

    @Test
    void createProduct_whenRegularUser_shouldReturnForbidden() throws Exception {
        CreateProductRequestDTO requestDTO = createValidRequestDTO();

        mockMvc.perform(post("/api/products/create")
                        .with(SecurityMockMvcRequestPostProcessors.user(regularUser.getEmail()).roles("KHACH_HANG"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isForbidden());
    }

    @Test
    void createProduct_whenUnauthenticated_shouldReturnUnauthorized() throws Exception {
        CreateProductRequestDTO requestDTO = createValidRequestDTO();

        mockMvc.perform(post("/api/products/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void createProduct_whenNameMissing_shouldReturnBadRequest() throws Exception {
        CreateProductVariantDTO variant1 = new CreateProductVariantDTO();
        variant1.setName("Default");
        variant1.setPrice(new BigDecimal("9.99"));
        variant1.setStockQuantity(10);

        CreateProductRequestDTO requestDTO = new CreateProductRequestDTO();
        requestDTO.setDescription("A great test product");
        requestDTO.setCategoryId(testCategory.getId().longValue());
        requestDTO.setBrandId(testBrand.getId().longValue());
        requestDTO.setVariants(Collections.singletonList(variant1));

        mockMvc.perform(post("/api/products/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void createProduct_whenVariantsMissing_shouldReturnBadRequest() throws Exception {
        CreateProductRequestDTO requestDTO = new CreateProductRequestDTO();
        requestDTO.setName("Test Product");
        requestDTO.setDescription("A great test product");
        requestDTO.setCategoryId(testCategory.getId().longValue());
        requestDTO.setBrandId(testBrand.getId().longValue());

        mockMvc.perform(post("/api/products/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void createProduct_whenInvalidCategoryId_shouldReturnBadRequest() throws Exception {
        CreateProductVariantDTO variant1 = new CreateProductVariantDTO();
        variant1.setName("Default");
        variant1.setPrice(new BigDecimal("9.99"));
        variant1.setStockQuantity(10);

        CreateProductRequestDTO requestDTO = new CreateProductRequestDTO();
        requestDTO.setName("Test Product");
        requestDTO.setDescription("A great test product");
        requestDTO.setCategoryId(9999L);
        requestDTO.setBrandId(testBrand.getId().longValue());
        requestDTO.setVariants(Collections.singletonList(variant1));

        mockMvc.perform(post("/api/products/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string(containsString("Category not found")));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void createProduct_whenInvalidVariantData_shouldReturnBadRequest() throws Exception {
        CreateProductVariantDTO invalidVariant = new CreateProductVariantDTO();
        invalidVariant.setName("Invalid Price Variant");
        invalidVariant.setPrice(new BigDecimal("-5.00"));
        invalidVariant.setStockQuantity(10);

        CreateProductRequestDTO requestDTO = new CreateProductRequestDTO();
        requestDTO.setName("Test Product");
        requestDTO.setDescription("A great test product");
        requestDTO.setCategoryId(testCategory.getId().longValue());
        requestDTO.setBrandId(testBrand.getId().longValue());
        requestDTO.setVariants(Collections.singletonList(invalidVariant));

        mockMvc.perform(post("/api/products/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO)))
                .andExpect(status().isBadRequest());
    }
}
