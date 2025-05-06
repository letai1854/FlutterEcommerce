package demo.com.example.testserver.product.controller;

import com.fasterxml.jackson.databind.ObjectMapper; // Import ObjectMapper
import demo.com.example.testserver.product.dto.CreateProductRequestDTO; // Import Create DTO
import demo.com.example.testserver.product.dto.ProductDTO;
import demo.com.example.testserver.product.dto.ProductVariantDTO; // Import ProductVariantDTO
import demo.com.example.testserver.product.dto.UpdateProductRequestDTO; // Import Update DTO
import demo.com.example.testserver.product.dto.CreateProductVariantDTO; // Import Create Variant DTO
import demo.com.example.testserver.product.dto.UpdateProductVariantDTO; // Import Update Variant DTO
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
import static org.mockito.Mockito.doNothing; // Import doNothing
import static org.mockito.Mockito.verify; // Import verify

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId; // Import ZoneId
import java.util.Arrays;
import java.util.Collections;
import java.util.Date; // Import Date
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
    private UpdateProductRequestDTO sampleUpdateRequest; // For update test
    private ProductDTO sampleProductDetail; // For getById test
    private ProductVariantDTO sampleVariant; // For getById test
    private ProductDTO createdProductDTO; // For create test
    private ProductDTO updatedProductDTO; // For update test

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
        // Add a sample variant for creation
        CreateProductVariantDTO createVariantDto = new CreateProductVariantDTO();
        createVariantDto.setName("Standard");
        createVariantDto.setPrice(new BigDecimal("49.99"));
        createVariantDto.setStockQuantity(100);
        sampleCreateRequest.setVariants(List.of(createVariantDto));
        sampleCreateRequest.setImageUrls(List.of("img1.jpg", "img2.jpg"));

        // Sample data for create response
        createdProductDTO = new ProductDTO();
        createdProductDTO.setId(5L); // Assume new ID
        createdProductDTO.setName(sampleCreateRequest.getName());
        createdProductDTO.setDescription(sampleCreateRequest.getDescription());
        createdProductDTO.setCategoryName("Electronics"); // Assume category name
        createdProductDTO.setBrandName("BrandA"); // Assume brand name
        createdProductDTO.setMainImageUrl(sampleCreateRequest.getMainImageUrl());
        createdProductDTO.setImageUrls(sampleCreateRequest.getImageUrls());
        createdProductDTO.setDiscountPercentage(sampleCreateRequest.getDiscountPercentage());
        createdProductDTO.setCreatedDate(LocalDateTime.now());
        createdProductDTO.setUpdatedDate(LocalDateTime.now());
        createdProductDTO.setMinPrice(new BigDecimal("49.99"));
        createdProductDTO.setMaxPrice(new BigDecimal("49.99"));
        createdProductDTO.setAverageRating(null); // New product
        createdProductDTO.setVariantCount(1);
        // Map created variant DTO to response variant DTO
        ProductVariantDTO createdVariantResp = new ProductVariantDTO();
        createdVariantResp.setId(201); // Assume new variant ID
        createdVariantResp.setName(createVariantDto.getName());
        createdVariantResp.setPrice(createVariantDto.getPrice());
        createdVariantResp.setStockQuantity(createVariantDto.getStockQuantity());
        createdProductDTO.setVariants(List.of(createdVariantResp));

        // Sample data for update tests
        sampleUpdateRequest = new UpdateProductRequestDTO();
        sampleUpdateRequest.setName("Updated Laptop Pro");
        sampleUpdateRequest.setDescription("Updated description");
        sampleUpdateRequest.setCategoryId(1);
        sampleUpdateRequest.setBrandId(1);
        sampleUpdateRequest.setMainImageUrl("updated_main.jpg");
        sampleUpdateRequest.setDiscountPercentage(new BigDecimal("15.00"));
        // Add variant update DTO (updating existing variant 101)
        UpdateProductVariantDTO updateVariantDto = new UpdateProductVariantDTO();
        updateVariantDto.setId(101); // ID of the variant to update
        updateVariantDto.setName("Variant A Updated");
        updateVariantDto.setPrice(new BigDecimal("1250.00"));
        updateVariantDto.setStockQuantity(45);
        sampleUpdateRequest.setVariants(List.of(updateVariantDto));
        sampleUpdateRequest.setImageUrls(List.of("updated_img1.jpg"));

        // Sample data for update response
        updatedProductDTO = new ProductDTO();
        updatedProductDTO.setId(1L); // ID of the updated product
        updatedProductDTO.setName(sampleUpdateRequest.getName());
        updatedProductDTO.setDescription(sampleUpdateRequest.getDescription());
        updatedProductDTO.setCategoryName("Electronics");
        updatedProductDTO.setBrandName("BrandA");
        updatedProductDTO.setMainImageUrl(sampleUpdateRequest.getMainImageUrl());
        updatedProductDTO.setImageUrls(sampleUpdateRequest.getImageUrls());
        updatedProductDTO.setDiscountPercentage(sampleUpdateRequest.getDiscountPercentage());
        updatedProductDTO.setCreatedDate(sampleProductDetail.getCreatedDate()); // Created date shouldn't change
        updatedProductDTO.setUpdatedDate(LocalDateTime.now()); // Updated date should change
        updatedProductDTO.setMinPrice(new BigDecimal("1250.00")); // Updated price
        updatedProductDTO.setMaxPrice(new BigDecimal("1250.00")); // Updated price
        updatedProductDTO.setAverageRating(sampleProductDetail.getAverageRating()); // Rating might not change immediately
        updatedProductDTO.setVariantCount(1);
        // Map updated variant DTO to response variant DTO
        ProductVariantDTO updatedVariantResp = new ProductVariantDTO();
        updatedVariantResp.setId(updateVariantDto.getId());
        updatedVariantResp.setName(updateVariantDto.getName());
        updatedVariantResp.setPrice(updateVariantDto.getPrice());
        updatedVariantResp.setStockQuantity(updateVariantDto.getStockQuantity());
        updatedProductDTO.setVariants(List.of(updatedVariantResp));
    }

    @Test
    void getProducts_defaultParams_shouldReturnProductsSortedByDateDesc() throws Exception {
        List<ProductDTO> sortedList = productList.stream()
                .sorted((p1, p2) -> p2.getCreatedDate().compareTo(p1.getCreatedDate()))
                .toList();
        Page<ProductDTO> productPage = new PageImpl<>(sortedList.subList(0, Math.min(10, sortedList.size())), PageRequest.of(0, 10), sortedList.size());

        Mockito.when(productService.findProducts(
                any(Pageable.class), eq(null), eq(null), eq(null), eq(null), eq(null), eq(null),
                eq("createdDate"), eq("desc")
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(productPage.getNumberOfElements())))
                .andExpect(jsonPath("$.content[0].id", is(productPage.getContent().get(0).getId().intValue()))); // Check first element ID
    }

    @Test
    void getProducts_withCategoryFilter_shouldReturnFilteredProducts() throws Exception {
        String categoryName = "Electronics";
        Integer categoryId = 1;
        List<ProductDTO> filteredList = productList.stream().filter(p -> categoryName.equals(p.getCategoryName())).toList();
        Page<ProductDTO> productPage = new PageImpl<>(filteredList, PageRequest.of(0, 10), filteredList.size());

        Mockito.when(productService.findProducts(
                any(Pageable.class), eq(null), eq(categoryId), eq(null), eq(null), eq(null), eq(null),
                eq("createdDate"), eq("desc") // Default sort
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
                eq("createdDate"), eq("desc") // Default sort
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
                eq("createdDate"), eq("desc") // Default sort
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
                eq("createdDate"), eq("desc") // Default sort
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("minRating", minRating.toString())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(filteredList.size())));
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
                .andExpect(jsonPath("$.content[0].id", is(sortedList.get(0).getId().intValue()))); // Check first element ID after sort
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
                .andExpect(jsonPath("$.content[0].id", is(sortedList.get(0).getId().intValue()))); // Check first element ID after sort
    }

    @Test
    void getProducts_withPagination_shouldReturnCorrectPage() throws Exception {
        int page = 1;
        int size = 2;
        List<ProductDTO> sortedList = productList.stream()
                .sorted((p1, p2) -> p2.getCreatedDate().compareTo(p1.getCreatedDate())) // Default sort
                .toList();
        List<ProductDTO> pagedList = sortedList.subList(size * page, Math.min(size * (page + 1), sortedList.size()));
        Page<ProductDTO> productPage = new PageImpl<>(pagedList, PageRequest.of(page, size), sortedList.size());

        Mockito.when(productService.findProducts(
                eq(PageRequest.of(page, size)), // Expect specific pageable
                eq(null), eq(null), eq(null), eq(null), eq(null), eq(null),
                eq("createdDate"), eq("desc") // Default sort
        )).thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products")
                        .param("page", String.valueOf(page))
                        .param("size", String.valueOf(size))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(pagedList.size())))
                .andExpect(jsonPath("$.number", is(page)))
                .andExpect(jsonPath("$.size", is(size)))
                .andExpect(jsonPath("$.totalElements", is(sortedList.size())));
    }

    @Test
    void searchProductsAdmin_withDateRange_shouldReturnFilteredProducts() throws Exception {
        Date startDate = Date.from(LocalDateTime.now().minusDays(3).atZone(ZoneId.systemDefault()).toInstant());
        Date endDate = Date.from(LocalDateTime.now().minusDays(1).atZone(ZoneId.systemDefault()).toInstant());
        Page<ProductDTO> productPage = new PageImpl<>(List.of(productList.get(0), productList.get(1)), PageRequest.of(0, 10), 2); // Assume 2 match

        when(productService.findProductsAdmin(eq(null), eq(startDate), eq(endDate), any(Pageable.class)))
                .thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products/admin/search")
                        .param("startDate", startDate.toInstant().toString())
                        .param("endDate", endDate.toInstant().toString())
                        .with(user("admin").roles("ADMIN")) // Authenticate as ADMIN
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(2)));
    }

     @Test
    void searchProductsAdmin_withSearchTerm_shouldReturnFilteredProducts() throws Exception {
        String searchTerm = "Laptop";
        Page<ProductDTO> productPage = new PageImpl<>(List.of(productList.get(0)), PageRequest.of(0, 10), 1); // Assume 1 matches

        when(productService.findProductsAdmin(eq(searchTerm), eq(null), eq(null), any(Pageable.class)))
                .thenReturn(productPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/products/admin/search")
                        .param("search", searchTerm)
                        .with(user("admin").roles("ADMIN")) // Authenticate as ADMIN
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)))
                .andExpect(jsonPath("$.content[0].name", containsString(searchTerm)));
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
    void createProduct_validInput_shouldReturnCreatedProduct() throws Exception {
        when(productService.createProduct(any(CreateProductRequestDTO.class))).thenReturn(createdProductDTO);

        mockMvc.perform(MockMvcRequestBuilders.post("/api/products/create")
                        .with(user("admin").roles("ADMIN")) // Authenticate as ADMIN
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleCreateRequest)))
                .andExpect(status().isCreated()) // Expect 201 Created
                .andExpect(header().exists("Location"))
                .andExpect(jsonPath("$.id", is(createdProductDTO.getId().intValue())))
                .andExpect(jsonPath("$.name", is(createdProductDTO.getName())))
                .andExpect(jsonPath("$.variantCount", is(1)))
                .andExpect(jsonPath("$.variants[0].name", is("Standard")));
    }

    @Test
    void updateProduct_validInput_shouldReturnUpdatedProduct() throws Exception {
        Long productId = 1L;
        when(productService.updateProduct(eq(productId), any(UpdateProductRequestDTO.class))).thenReturn(updatedProductDTO);

        mockMvc.perform(MockMvcRequestBuilders.put("/api/products/{id}", productId)
                        .with(user("admin").roles("ADMIN")) // Authenticate as ADMIN
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleUpdateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(productId.intValue())))
                .andExpect(jsonPath("$.name", is(updatedProductDTO.getName())))
                .andExpect(jsonPath("$.description", is(updatedProductDTO.getDescription())))
                .andExpect(jsonPath("$.discountPercentage", is(updatedProductDTO.getDiscountPercentage().doubleValue())))
                .andExpect(jsonPath("$.variants[0].price", is(updatedProductDTO.getVariants().get(0).getPrice().doubleValue())));
    }

    @Test
    void deleteProduct_validId_shouldReturnNoContent() throws Exception {
        Long productId = 1L;
        doNothing().when(productService).deleteProduct(productId); // Mock void method

        mockMvc.perform(MockMvcRequestBuilders.delete("/api/products/{id}", productId)
                        .with(user("admin").roles("ADMIN")) // Authenticate as ADMIN
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent()); // Expect 204 No Content

        verify(productService).deleteProduct(productId); // Verify service method was called
    }

    // Skipped error handling tests as requested
    // @Test
    // void getProducts_serviceThrowsIllegalArgumentException_shouldReturnBadRequest() throws Exception { ... }
    // @Test
    // void getProducts_serviceThrowsGenericException_shouldReturnInternalServerError() throws Exception { ... }
    // @Test
    // void getProductById_notFound_shouldReturnNotFound() throws Exception { ... }
    // @Test
    // void createProduct_invalidInput_shouldReturnBadRequest() throws Exception { ... }
    // @Test
    // void createProduct_unauthorized_shouldReturnForbidden() throws Exception { ... }
    // @Test
    // void updateProduct_notFound_shouldReturnNotFound() throws Exception { ... }
    // @Test
    // void deleteProduct_notFound_shouldReturnNotFound() throws Exception { ... }

}