package demo.com.example.testserver.product.controller;

import com.fasterxml.jackson.databind.ObjectMapper; // Import ObjectMapper
import demo.com.example.testserver.product.dto.CreateProductRequestDTO; // Import Create DTO
import demo.com.example.testserver.product.dto.ProductDTO;
import demo.com.example.testserver.product.dto.ProductVariantDTO; // Import ProductVariantDTO
import demo.com.example.testserver.product.service.ProductService;
import jakarta.persistence.EntityNotFoundException; // Import
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*; // Import security post processors

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when; // Import static when
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class ProductControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProductService productService;

    @Autowired
    private ObjectMapper objectMapper; // Autowire ObjectMapper

    private List<ProductDTO> productList;
    private CreateProductRequestDTO sampleCreateRequest;
    private ProductDTO sampleProductDetail; // For getById test
    private ProductVariantDTO sampleVariant; // For getById test

    @BeforeEach
    void setUp() {
        // Sample Variant DTO (using Integer ID)
        sampleVariant = new ProductVariantDTO();
        sampleVariant.setId(101); // Integer ID
        sampleVariant.setName("Variant A");
        sampleVariant.setPrice(new BigDecimal("1200.00"));
        sampleVariant.setStockQuantity(50);
        sampleVariant.setSku("LP-VA");

        // Sample data matching the updated ProductDTO structure for list view
        ProductDTO product1 = new ProductDTO();
        product1.setId(1L); // Use Long
        product1.setName("Laptop Pro");
        product1.setDescription("High-end laptop");
        product1.setCategoryName("Electronics");
        product1.setBrandName("BrandA");
        product1.setMainImageUrl("url1.jpg");
        product1.setDiscountPercentage(new BigDecimal("10.00"));
        product1.setAverageRating(4.5);
        product1.setMinPrice(new BigDecimal("1150.00"));
        product1.setMaxPrice(new BigDecimal("1200.00"));
        product1.setCreatedDate(LocalDateTime.now().minusDays(1));
        product1.setUpdatedDate(LocalDateTime.now());
        product1.setVariantCount(1); // Added
        product1.setVariants(Collections.emptyList()); // Empty list for list view DTO

        ProductDTO product2 = new ProductDTO();
        product2.setId(2L); // Use Long
        product2.setName("Smartphone X");
        product2.setDescription("Latest smartphone");
        product2.setCategoryName("Electronics");
        product2.setBrandName("BrandB");
        product2.setMainImageUrl("url2.jpg");
        product2.setDiscountPercentage(null);
        product2.setAverageRating(4.8);
        product2.setMinPrice(new BigDecimal("999.99"));
        product2.setMaxPrice(new BigDecimal("999.99"));
        product2.setCreatedDate(LocalDateTime.now().minusDays(2));
        product2.setUpdatedDate(LocalDateTime.now());
        product2.setVariantCount(2); // Added
        product2.setVariants(Collections.emptyList()); // Empty list for list view DTO

        ProductDTO product3 = new ProductDTO();
        product3.setId(3L); // Use Long
        product3.setName("Wireless Mouse");
        product3.setDescription("Ergonomic mouse");
        product3.setCategoryName("Accessories");
        product3.setBrandName("BrandA");
        product3.setMainImageUrl("url3.jpg");
        product3.setDiscountPercentage(new BigDecimal("5.00"));
        product3.setAverageRating(4.2);
        product3.setMinPrice(new BigDecimal("25.50"));
        product3.setMaxPrice(new BigDecimal("25.50"));
        product3.setCreatedDate(LocalDateTime.now());
        product3.setUpdatedDate(LocalDateTime.now());
        product3.setVariantCount(1); // Added
        product3.setVariants(Collections.emptyList()); // Empty list for list view DTO

        ProductDTO product4 = new ProductDTO();
        product4.setId(4L); // Use Long
        product4.setName("Gaming Keyboard");
        product4.setDescription("Mechanical keyboard");
        product4.setCategoryName("Accessories");
        product4.setBrandName("BrandC");
        product4.setMainImageUrl("url4.jpg");
        product4.setDiscountPercentage(null);
        product4.setAverageRating(4.7);
        product4.setMinPrice(new BigDecimal("150.00"));
        product4.setMaxPrice(new BigDecimal("150.00"));
        product4.setCreatedDate(LocalDateTime.now().minusHours(5));
        product4.setUpdatedDate(LocalDateTime.now());
        product4.setVariantCount(1); // Added
        product4.setVariants(Collections.emptyList()); // Empty list for list view DTO

        productList = Arrays.asList(product1, product2, product3, product4);

        // Sample ProductDTO for detail view (includes variants)
        sampleProductDetail = new ProductDTO();
        sampleProductDetail.setId(1L);
        sampleProductDetail.setName("Laptop Pro");
        sampleProductDetail.setDescription("High-end laptop");
        sampleProductDetail.setCategoryName("Electronics");
        sampleProductDetail.setBrandName("BrandA");
        sampleProductDetail.setMainImageUrl("url1.jpg");
        sampleProductDetail.setDiscountPercentage(new BigDecimal("10.00"));
        sampleProductDetail.setAverageRating(4.5);
        sampleProductDetail.setMinPrice(new BigDecimal("1150.00"));
        sampleProductDetail.setMaxPrice(new BigDecimal("1200.00"));
        sampleProductDetail.setCreatedDate(LocalDateTime.now().minusDays(1));
        sampleProductDetail.setUpdatedDate(LocalDateTime.now());
        sampleProductDetail.setVariantCount(1);
        sampleProductDetail.setVariants(List.of(sampleVariant)); // Include the sample variant

        // Sample data for create tests (request only)
        sampleCreateRequest = new CreateProductRequestDTO();
        sampleCreateRequest.setName("New Gadget");
        sampleCreateRequest.setDescription("A cool new gadget");
        sampleCreateRequest.setCategoryId(1L); // Use Long for IDs in DTO
        sampleCreateRequest.setBrandId(1L);   // Use Long for IDs in DTO
        sampleCreateRequest.setMainImageUrl("new_gadget.jpg");
        sampleCreateRequest.setDiscountPercentage(BigDecimal.ZERO);
    }

    @Test
    void getProducts_defaultParams_shouldReturnProductsSortedByDateDesc() throws Exception {
        List<ProductDTO> sortedList = productList.stream()
                .sorted((p1, p2) -> p2.getCreatedDate().compareTo(p1.getCreatedDate()))
                .toList();
        Page<ProductDTO> productPage = new PageImpl<>(sortedList.subList(0, 2), PageRequest.of(0, 2), sortedList.size());

        Mockito.when(productService.findProducts(
                any(Pageable.class),
                eq(null), eq(null), eq(null), eq(null), eq(null), eq(null),
                eq("createdDate"), eq("desc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("size", "2")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(2)))
                .andExpect(jsonPath("$.content[0].id", is(3)))
                .andExpect(jsonPath("$.content[1].id", is(4)))
                .andExpect(jsonPath("$.totalPages", is(productList.size() / 2)))
                .andExpect(jsonPath("$.totalElements", is(productList.size())))
                .andExpect(jsonPath("$.number", is(0)))
                .andExpect(jsonPath("$.size", is(2)));
    }

    @Test
    void getProducts_withCategoryFilter_shouldReturnFilteredProducts() throws Exception {
        String categoryName = "Electronics";
        Integer categoryId = 1;
        List<ProductDTO> filteredList = productList.stream().filter(p -> categoryName.equals(p.getCategoryName())).toList();
        Page<ProductDTO> productPage = new PageImpl<>(filteredList, PageRequest.of(0, 10), filteredList.size());

        Mockito.when(productService.findProducts(
                any(Pageable.class), eq(null), eq(categoryId), eq(null), eq(null), eq(null), eq(null),
                eq("createdDate"), eq("desc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("categoryId", categoryId.toString())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(filteredList.size())))
                .andExpect(jsonPath("$.content[0].categoryName", is(categoryName)));
    }

    @Test
    void getProducts_withBrandFilter_shouldReturnFilteredProducts() throws Exception {
        String brandName = "BrandA";
        Integer brandId = 1;
        List<ProductDTO> filteredList = productList.stream().filter(p -> brandName.equals(p.getBrandName())).toList();
        Page<ProductDTO> productPage = new PageImpl<>(filteredList, PageRequest.of(0, 10), filteredList.size());

        Mockito.when(productService.findProducts(
                any(Pageable.class), eq(null), eq(null), eq(brandId), eq(null), eq(null), eq(null),
                eq("createdDate"), eq("desc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("brandId", brandId.toString())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(filteredList.size())))
                .andExpect(jsonPath("$.content[0].brandName", is(brandName)));
    }

    @Test
    void getProducts_withPriceRangeFilter_shouldReturnFilteredProducts() throws Exception {
        BigDecimal minPrice = new BigDecimal("100.00");
        BigDecimal maxPrice = new BigDecimal("1000.00");
        List<ProductDTO> filteredList = productList.stream()
                .filter(p -> (p.getMaxPrice() != null && p.getMaxPrice().compareTo(minPrice) >= 0) &&
                        (p.getMinPrice() != null && p.getMinPrice().compareTo(maxPrice) <= 0))
                .toList();
        Page<ProductDTO> productPage = new PageImpl<>(filteredList, PageRequest.of(0, 10), filteredList.size());

        Mockito.when(productService.findProducts(
                any(Pageable.class), eq(null), eq(null), eq(null), eq(minPrice), eq(maxPrice), eq(null),
                eq("createdDate"), eq("desc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("minPrice", minPrice.toString())
                        .param("maxPrice", maxPrice.toString())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(filteredList.size())));
    }

    @Test
    void getProducts_withMinRatingFilter_shouldReturnFilteredProducts() throws Exception {
        Double minRating = 4.6;
        List<ProductDTO> filteredList = productList.stream().filter(p -> p.getAverageRating() != null && p.getAverageRating() >= minRating).toList();
        Page<ProductDTO> productPage = new PageImpl<>(filteredList, PageRequest.of(0, 10), filteredList.size());

        Mockito.when(productService.findProducts(
                any(Pageable.class), eq(null), eq(null), eq(null), eq(null), eq(null), eq(minRating),
                eq("createdDate"), eq("desc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("minRating", minRating.toString())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(filteredList.size())))
                .andExpect(jsonPath("$.content[0].averageRating", greaterThanOrEqualTo(minRating)));
    }

    @Test
    void getProducts_sortByPriceAsc_shouldReturnSortedProducts() throws Exception {
        List<ProductDTO> sortedList = productList.stream()
                .filter(p -> p.getMinPrice() != null)
                .sorted((p1, p2) -> p1.getMinPrice().compareTo(p2.getMinPrice()))
                .toList();
        Page<ProductDTO> productPage = new PageImpl<>(sortedList, PageRequest.of(0, 10), sortedList.size());

        Mockito.when(productService.findProducts(
                any(Pageable.class), eq(null), eq(null), eq(null), eq(null), eq(null), eq(null),
                eq("price"), eq("asc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("sortBy", "price")
                        .param("sortDir", "asc")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(sortedList.size())))
                .andExpect(jsonPath("$.content[0].id", is(3)))
                .andExpect(jsonPath("$.content[1].id", is(4)))
                .andExpect(jsonPath("$.content[2].id", is(2)))
                .andExpect(jsonPath("$.content[3].id", is(1)));
    }

    @Test
    void getProducts_sortByRatingDesc_shouldReturnSortedProducts() throws Exception {
        List<ProductDTO> sortedList = productList.stream()
                .filter(p -> p.getAverageRating() != null)
                .sorted((p1, p2) -> Double.compare(p2.getAverageRating(), p1.getAverageRating()))
                .toList();
        Page<ProductDTO> productPage = new PageImpl<>(sortedList, PageRequest.of(0, 10), sortedList.size());

        Mockito.when(productService.findProducts(
                any(Pageable.class), eq(null), eq(null), eq(null), eq(null), eq(null), eq(null),
                eq("rating"), eq("desc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("sortBy", "rating")
                        .param("sortDir", "desc")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(sortedList.size())))
                .andExpect(jsonPath("$.content[0].id", is(2)))
                .andExpect(jsonPath("$.content[1].id", is(4)))
                .andExpect(jsonPath("$.content[2].id", is(1)))
                .andExpect(jsonPath("$.content[3].id", is(3)));
    }

    @Test
    void getProducts_withPagination_shouldReturnCorrectPage() throws Exception {
        int page = 1;
        int size = 2;
        List<ProductDTO> sortedList = productList.stream()
                .sorted((p1, p2) -> p2.getCreatedDate().compareTo(p1.getCreatedDate()))
                .toList();
        List<ProductDTO> pagedList = sortedList.subList(size * page, Math.min(size * (page + 1), sortedList.size()));
        Page<ProductDTO> productPage = new PageImpl<>(pagedList, PageRequest.of(page, size), sortedList.size());

        Mockito.when(productService.findProducts(
                any(Pageable.class),
                eq(null), eq(null), eq(null), eq(null), eq(null), eq(null),
                eq("createdDate"), eq("desc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("page", String.valueOf(page))
                        .param("size", String.valueOf(size))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(pagedList.size())))
                .andExpect(jsonPath("$.number", is(page)))
                .andExpect(jsonPath("$.size", is(size)))
                .andExpect(jsonPath("$.totalElements", is(productList.size())));
    }

    @Test
    void getProducts_noProductsFound_shouldReturnNoContent() throws Exception {
        Page<ProductDTO> emptyPage = new PageImpl<>(Collections.emptyList(), PageRequest.of(0, 10), 0);

        Mockito.when(productService.findProducts(
                any(Pageable.class), any(), any(), any(), any(), any(), any(), any(), any()
        )).thenReturn(emptyPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());
    }

    @Test
    void getProducts_serviceThrowsIllegalArgumentException_shouldReturnBadRequest() throws Exception {
        String errorMessage = "Invalid parameter value";
        Mockito.when(productService.findProducts(
                any(Pageable.class), any(), any(), any(), any(), any(), any(), any(), any()
        )).thenThrow(new IllegalArgumentException(errorMessage));

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("minPrice", "-10")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getProducts_serviceThrowsGenericException_shouldReturnInternalServerError() throws Exception {
        Mockito.when(productService.findProducts(
                any(Pageable.class), any(), any(), any(), any(), any(), any(), any(), any()
        )).thenThrow(new RuntimeException("Database connection failed"));

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isInternalServerError());
    }

    @Test
    void getProductById_exists_shouldReturnProductDetails() throws Exception {
        Long productId = 1L;
        when(productService.findProductById(productId)).thenReturn(sampleProductDetail);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products/{id}", productId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(productId.intValue())))
                .andExpect(jsonPath("$.name", is(sampleProductDetail.getName())))
                .andExpect(jsonPath("$.description", is(sampleProductDetail.getDescription())))
                .andExpect(jsonPath("$.variantCount", is(sampleProductDetail.getVariantCount())))
                .andExpect(jsonPath("$.variants", hasSize(1)))
                .andExpect(jsonPath("$.variants[0].id", is(sampleVariant.getId())))
                .andExpect(jsonPath("$.variants[0].name", is(sampleVariant.getName())))
                .andExpect(jsonPath("$.variants[0].price", is(sampleVariant.getPrice().doubleValue())));
    }

    @Test
    void getProductById_notFound_shouldReturnNotFound() throws Exception {
        Long productId = 999L;
        String errorMessage = "Product not found with ID: " + productId;
        when(productService.findProductById(productId)).thenThrow(new EntityNotFoundException(errorMessage));

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products/{id}", productId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound())
                .andExpect(content().string(errorMessage));
    }
}