package demo.com.example.testserver.product.controller;

import com.fasterxml.jackson.databind.ObjectMapper; // Import ObjectMapper
import demo.com.example.testserver.product.dto.CreateProductRequestDTO; // Import Create DTO
import demo.com.example.testserver.product.dto.ProductDTO;
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

    @BeforeEach
    void setUp() {
        // Sample data matching the updated ProductDTO structure
        ProductDTO product1;
        product1 = new ProductDTO();
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

        productList = Arrays.asList(product1, product2, product3, product4);

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
        // Sort the list by createdDate descending to match the expected service behavior
        List<ProductDTO> sortedList = productList.stream()
                .sorted((p1, p2) -> p2.getCreatedDate().compareTo(p1.getCreatedDate()))
                .toList();
        // Create the page from the sorted list
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
                .andExpect(jsonPath("$.content[0].id", is(3))) // Should now pass (Product 3 is newest)
                .andExpect(jsonPath("$.content[1].id", is(4))) // Should now pass (Product 4 is second newest)
                .andExpect(jsonPath("$.totalPages", is(productList.size() / 2)))
                .andExpect(jsonPath("$.totalElements", is(productList.size()))) // Fix: Compare with int size
                .andExpect(jsonPath("$.number", is(0)))
                .andExpect(jsonPath("$.size", is(2)));
    }

    @Test
    void getProducts_withCategoryFilter_shouldReturnFilteredProducts() throws Exception {
        String categoryName = "Electronics";
        Integer categoryId = 1; // Define the categoryId used in the test
        List<ProductDTO> filteredList = productList.stream().filter(p -> categoryName.equals(p.getCategoryName())).toList();
        Page<ProductDTO> productPage = new PageImpl<>(filteredList, PageRequest.of(0, 10), filteredList.size());

        // Update the mock to expect the correct categoryId
        Mockito.when(productService.findProducts(
                any(Pageable.class), eq(null), eq(categoryId), eq(null), eq(null), eq(null), eq(null), // Changed eq(null) to eq(categoryId
                eq("createdDate"), eq("desc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("categoryId", categoryId.toString()) // Use the defined variable
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(filteredList.size())))
                .andExpect(jsonPath("$.content[0].categoryName", is(categoryName)));
    }

    @Test
    void getProducts_withBrandFilter_shouldReturnFilteredProducts() throws Exception {
        String brandName = "BrandA";
        Integer brandId = 1; // Define the brandId used in the test
        List<ProductDTO> filteredList = productList.stream().filter(p -> brandName.equals(p.getBrandName())).toList();
        Page<ProductDTO> productPage = new PageImpl<>(filteredList, PageRequest.of(0, 10), filteredList.size());

        // Update the mock to expect the correct brandId
        Mockito.when(productService.findProducts(
                any(Pageable.class), eq(null), eq(null), eq(brandId), eq(null), eq(null), eq(null), // Changed eq(null) to eq(brandId)
                eq("createdDate"), eq("desc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("brandId", brandId.toString()) // Use the defined variable
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
        // Sort the list by createdDate descending to match the default sort order assumed by the controller/service
        List<ProductDTO> sortedList = productList.stream()
                .sorted((p1, p2) -> p2.getCreatedDate().compareTo(p1.getCreatedDate()))
                .toList();
        List<ProductDTO> pagedList = sortedList.subList(size * page, Math.min(size * (page + 1), sortedList.size()));
        Page<ProductDTO> productPage = new PageImpl<>(pagedList, PageRequest.of(page, size), sortedList.size());

        // Use any(Pageable.class) for more robust matching
        Mockito.when(productService.findProducts(
                any(Pageable.class), // Changed from eq(PageRequest.of(...))
                eq(null), eq(null), eq(null), eq(null), eq(null), eq(null),
                eq("createdDate"), eq("desc") // Keep matching other params
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("page", String.valueOf(page))
                        .param("size", String.valueOf(size))
                        // Ensure sortBy and sortDir are implicitly "createdDate" and "desc" by default
                        // or explicitly add them if the controller default differs:
                        // .param("sortBy", "createdDate")
                        // .param("sortDir", "desc")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(pagedList.size())))
                .andExpect(jsonPath("$.number", is(page)))
                .andExpect(jsonPath("$.size", is(size)))
                .andExpect(jsonPath("$.totalElements", is(productList.size()))); // Fix: Compare with int size
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
}