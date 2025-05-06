package demo.com.example.testserver.product.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import demo.com.example.testserver.product.dto.CreateProductRequestDTO;
import demo.com.example.testserver.product.dto.CreateProductVariantDTO;
import demo.com.example.testserver.product.dto.UpdateProductRequestDTO;
import demo.com.example.testserver.product.dto.UpdateProductVariantDTO;
import demo.com.example.testserver.product.model.Brand;
import demo.com.example.testserver.product.model.Category;
import demo.com.example.testserver.product.model.Product;
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
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Date;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
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

    private Product createAndSaveProduct(String name, Category category, Brand brand, int variantCount) {
        Product product = new Product();
        product.setName(name);
        product.setDescription("Initial Description");
        product.setCategory(category);
        product.setBrand(brand);
        product.setMainImageUrl("main.jpg");
        product.setAverageRating(0.0);
        product.setDiscountPercentage(null); // Changed from BigDecimal.ZERO to null
        product.setCreatedDate(new Date());

        List<ProductVariant> variants = new ArrayList<>();
        for (int i = 1; i <= variantCount; i++) {
            ProductVariant variant = new ProductVariant();
            variant.setName(name + " Variant " + i);
            variant.setSku(name.toUpperCase() + "-V" + i);
            variant.setPrice(new BigDecimal("10.00").add(BigDecimal.valueOf(i)));
            variant.setStockQuantity(10 + i);
            variant.setProduct(product);
            variants.add(variant);
        }
        product.setVariants(variants);

        return productRepository.save(product);
    }

    private Product createAndSaveProductWithDetails(String name, Category category, Brand brand, double averageRating, BigDecimal discountPercentage, Date createdDate) {
        Product product = new Product();
        product.setName(name);
        product.setDescription("Desc for " + name);
        product.setCategory(category);
        product.setBrand(brand);
        product.setMainImageUrl(name.toLowerCase() + ".jpg");
        product.setAverageRating(averageRating);
        // Ensure BigDecimal.ZERO is treated as null for discountPercentage to align with DB constraint
        // Also handle if discountPercentage is already null
        if (discountPercentage == null || discountPercentage.compareTo(BigDecimal.ZERO) == 0) {
            product.setDiscountPercentage(null);
        } else {
            product.setDiscountPercentage(discountPercentage);
        }
        product.setCreatedDate(createdDate);

        ProductVariant variant = new ProductVariant();
        variant.setName(name + " Variant");
        variant.setPrice(new BigDecimal("20.00"));
        variant.setStockQuantity(50);
        variant.setProduct(product);
        product.setVariants(Collections.singletonList(variant));

        return productRepository.save(product);
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

    @Test
    void updateProduct_Success() throws Exception {
        Product existingProduct = createAndSaveProduct("UpdateMe", testCategory, testBrand, 2);
        Long productId = existingProduct.getId();
        Integer variant1Id = existingProduct.getVariants().get(0).getId();

        UpdateProductRequestDTO updateDTO = new UpdateProductRequestDTO();
        updateDTO.setName("Updated Product Name");
        updateDTO.setDescription("Updated Description");
        updateDTO.setCategoryId(testCategory.getId());
        updateDTO.setBrandId(testBrand.getId());
        updateDTO.setMainImageUrl("updated_main.jpg");
        updateDTO.setDiscountPercentage(new BigDecimal("15.00"));
        updateDTO.setImageUrls(Arrays.asList("updated_img1.jpg", "updated_img2.jpg"));

        UpdateProductVariantDTO variantUpdate1 = new UpdateProductVariantDTO();
        variantUpdate1.setId(variant1Id);
        variantUpdate1.setName("Updated Variant 1");
        variantUpdate1.setPrice(new BigDecimal("99.99"));
        variantUpdate1.setStockQuantity(5);
        variantUpdate1.setSku("UPD-V1");

        UpdateProductVariantDTO variantNew3 = new UpdateProductVariantDTO();
        variantNew3.setName("New Variant 3");
        variantNew3.setPrice(new BigDecimal("149.50"));
        variantNew3.setStockQuantity(20);
        variantNew3.setSku("NEW-V3");

        updateDTO.setVariants(Arrays.asList(variantUpdate1, variantNew3));

        mockMvc.perform(put("/api/products/{id}", productId)
                        .with(SecurityMockMvcRequestPostProcessors.user(adminUser.getEmail()).roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(productId.intValue())))
                .andExpect(jsonPath("$.name", is("Updated Product Name")))
                .andExpect(jsonPath("$.description", is("Updated Description")))
                .andExpect(jsonPath("$.mainImageUrl", is("updated_main.jpg")))
                .andExpect(jsonPath("$.discountPercentage", comparesEqualTo(15.00)))
                .andExpect(jsonPath("$.variants", hasSize(2)))
                .andExpect(jsonPath("$.variants[0].id", is(variant1Id)))
                .andExpect(jsonPath("$.variants[0].name", is("Updated Variant 1")))
                .andExpect(jsonPath("$.variants[0].price", comparesEqualTo(99.99)))
                .andExpect(jsonPath("$.variants[1].name", is("New Variant 3")))
                .andExpect(jsonPath("$.variants[1].id", notNullValue()));

        Product updatedProduct = productRepository.findById(productId).orElseThrow();
        assertEquals("Updated Product Name", updatedProduct.getName());
        assertEquals(2, updatedProduct.getVariants().size());
        assertTrue(updatedProduct.getVariants().stream().anyMatch(v -> "Updated Variant 1".equals(v.getName())));
        assertTrue(updatedProduct.getVariants().stream().anyMatch(v -> "New Variant 3".equals(v.getName())));
    }

    @Test
    void updateProduct_NotFound() throws Exception {
        UpdateProductRequestDTO updateDTO = new UpdateProductRequestDTO();
        updateDTO.setName("Doesn't Matter");
        updateDTO.setDescription("Desc");
        updateDTO.setCategoryId(testCategory.getId());
        updateDTO.setBrandId(testBrand.getId());
        UpdateProductVariantDTO variant = new UpdateProductVariantDTO();
        variant.setName("V1");
        variant.setPrice(BigDecimal.ONE);
        variant.setStockQuantity(1);
        updateDTO.setVariants(List.of(variant));

        mockMvc.perform(put("/api/products/{id}", 9999L)
                        .with(SecurityMockMvcRequestPostProcessors.user(adminUser.getEmail()).roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateDTO)))
                .andExpect(status().isNotFound());
    }

    @Test
    void updateProduct_Unauthorized() throws Exception {
        Product existingProduct = createAndSaveProduct("AuthTest", testCategory, testBrand, 1);
        UpdateProductRequestDTO updateDTO = new UpdateProductRequestDTO();
        updateDTO.setName("Updated AuthTest");
        updateDTO.setDescription("Desc");
        updateDTO.setCategoryId(testCategory.getId());
        updateDTO.setBrandId(testBrand.getId());
        UpdateProductVariantDTO variant = new UpdateProductVariantDTO();
        variant.setId(existingProduct.getVariants().get(0).getId());
        variant.setName("V1 Updated");
        variant.setPrice(BigDecimal.TEN);
        variant.setStockQuantity(1);
        updateDTO.setVariants(List.of(variant));

        mockMvc.perform(put("/api/products/{id}", existingProduct.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateDTO)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void deleteProduct_Success() throws Exception {
        Product productToDelete = createAndSaveProduct("DeleteMe", testCategory, testBrand, 1);
        Long productId = productToDelete.getId();
        assertTrue(productRepository.existsById(productId));

        mockMvc.perform(delete("/api/products/{id}", productId)
                        .with(SecurityMockMvcRequestPostProcessors.user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isNoContent());

        assertFalse(productRepository.existsById(productId));
    }

    @Test
    void deleteProduct_NotFound() throws Exception {
        mockMvc.perform(delete("/api/products/{id}", 9999L)
                        .with(SecurityMockMvcRequestPostProcessors.user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteProduct_Unauthorized() throws Exception {
        Product productToDelete = createAndSaveProduct("DeleteAuthTest", testCategory, testBrand, 1);
        Long productId = productToDelete.getId();

        mockMvc.perform(delete("/api/products/{id}", productId))
                .andExpect(status().isUnauthorized());

        assertTrue(productRepository.existsById(productId));
    }

    @Test
    void getTopSellingProducts_shouldReturnSortedProducts() throws Exception {
        Product p1 = createAndSaveProductWithDetails("Product A (High Rating, New)", testCategory, testBrand, 4.8, null, Date.from(Instant.now())); // Was BigDecimal.ZERO
        Product p2 = createAndSaveProductWithDetails("Product B (Mid Rating, Old)", testCategory, testBrand, 4.5, BigDecimal.TEN, Date.from(Instant.now().minus(1, ChronoUnit.DAYS)));
        Product p3 = createAndSaveProductWithDetails("Product C (High Rating, Older)", testCategory, testBrand, 4.8, BigDecimal.valueOf(5), Date.from(Instant.now().minus(2, ChronoUnit.DAYS)));
        Product p4 = createAndSaveProductWithDetails("Product D (Low Rating, Newest)", testCategory, testBrand, 3.0, null, Date.from(Instant.now().plus(1, ChronoUnit.HOURS))); // Was BigDecimal.ZERO

        mockMvc.perform(get("/api/products/top-selling")
                        .param("page", "0")
                        .param("size", "10")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(4)))
                .andExpect(jsonPath("$.content[0].name", is(p1.getName())))
                .andExpect(jsonPath("$.content[1].name", is(p3.getName())))
                .andExpect(jsonPath("$.content[2].name", is(p2.getName())))
                .andExpect(jsonPath("$.content[3].name", is(p4.getName())));
    }

    @Test
    void getTopDiscountedProducts_shouldReturnSortedDiscountedProducts() throws Exception {
        Product p1_no_discount = createAndSaveProductWithDetails("Product X (No Discount)", testCategory, testBrand, 4.0, null, new Date()); // Was BigDecimal.ZERO, renamed for clarity
        Product p2 = createAndSaveProductWithDetails("Product Y (High Discount)", testCategory, testBrand, 4.2, new BigDecimal("25.00"), new Date());
        Product p3 = createAndSaveProductWithDetails("Product Z (Mid Discount)", testCategory, testBrand, 3.5, new BigDecimal("15.00"), new Date());
        Product p4 = createAndSaveProductWithDetails("Product W (Low Discount)", testCategory, testBrand, 4.5, new BigDecimal("5.00"), new Date());
        Product p5 = createAndSaveProductWithDetails("Product V (Null Discount)", testCategory, testBrand, 4.1, null, new Date());

        mockMvc.perform(get("/api/products/top-discounted")
                        .param("page", "0")
                        .param("size", "10")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(3)))
                .andExpect(jsonPath("$.content[0].name", is(p2.getName())))
                .andExpect(jsonPath("$.content[1].name", is(p3.getName())))
                .andExpect(jsonPath("$.content[2].name", is(p4.getName())));
    }

    @Test
    void getTopDiscountedProducts_whenNoDiscountedProducts_shouldReturnNoContent() throws Exception {
        createAndSaveProductWithDetails("Product NoDiscount1", testCategory, testBrand, 4.0, null, new Date()); // Was BigDecimal.ZERO
        createAndSaveProductWithDetails("Product NoDiscount2", testCategory, testBrand, 4.1, null, new Date());

        mockMvc.perform(get("/api/products/top-discounted")
                        .param("page", "0")
                        .param("size", "10")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());
    }
}
