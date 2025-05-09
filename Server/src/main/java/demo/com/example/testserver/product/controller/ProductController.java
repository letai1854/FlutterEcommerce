package demo.com.example.testserver.product.controller;

import demo.com.example.testserver.product.dto.CreateProductRequestDTO; // Import new DTO
import demo.com.example.testserver.product.dto.ProductDTO;
import demo.com.example.testserver.product.dto.UpdateProductRequestDTO; // Import Update DTO
import demo.com.example.testserver.product.dto.CreateProductReviewRequestDTO; // Import for reviews
import demo.com.example.testserver.product.dto.ProductReviewDTO; // Import for reviews
import org.springframework.security.core.userdetails.UserDetails; // Import UserDetails
import demo.com.example.testserver.product.service.ProductService;
import jakarta.persistence.EntityNotFoundException; // Import
import jakarta.validation.Valid; // Import for validation
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal; // Import for authentication
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.security.access.prepost.PreAuthorize; // Import PreAuthorize

import java.math.BigDecimal;
import java.net.URI; // Import for location header
import java.util.Date; // Import Date

@RestController
@RequestMapping("/api/products")
@CrossOrigin(origins = "*") // Allow requests from any origin
public class ProductController {

    private static final Logger logger = LoggerFactory.getLogger(ProductController.class);

    @Autowired
    private ProductService productService;

    @GetMapping
    public ResponseEntity<Page<ProductDTO>> getProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Integer categoryId,
            @RequestParam(required = false) Integer brandId,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(required = false) Double minRating,
            @RequestParam(defaultValue = "createdDate") String sortBy, // Default sort: newest
            @RequestParam(defaultValue = "desc") String sortDir,      // Default direction: descending
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        try {
            Pageable pageable = PageRequest.of(page, size); // Sort will be handled by the service

            Page<ProductDTO> productPage = productService.findProducts(
                    pageable, search, categoryId, brandId, minPrice, maxPrice, minRating, sortBy, sortDir
            );

            if (productPage.isEmpty()) {
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            return ResponseEntity.ok(productPage);

        } catch (IllegalArgumentException e) {
             logger.warn("Invalid request parameter: {}", e.getMessage());
             return new ResponseEntity<>(HttpStatus.BAD_REQUEST); // Or return a specific error DTO
        } catch (Exception e) {
            logger.error("Error fetching products", e);
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // New endpoint for Admin search by date range and optional search term
    @GetMapping("/admin/search")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<ProductDTO>> searchProductsAdmin(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Date startDate, // Expect ISO 8601 format
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Date endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        try {
            Pageable pageable = PageRequest.of(page, size); // Basic pagination
            logger.info("Admin searching products - Search: {}, StartDate: {}, EndDate: {}, Pageable: {}", search, startDate, endDate, pageable);

            Page<ProductDTO> productPage = productService.findProductsAdmin(search, startDate, endDate, pageable);

            if (productPage.isEmpty()) {
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            return ResponseEntity.ok(productPage);

        } catch (IllegalArgumentException e) {
             logger.warn("Invalid request parameter for admin search: {}", e.getMessage());
             return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            logger.error("Error during admin product search", e);
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<?> getProductById(@PathVariable Long id) {
        try {
            logger.info("Received request to get product by ID: {}", id);
            ProductDTO productDTO = productService.findProductById(id);
            return ResponseEntity.ok(productDTO);
        } catch (EntityNotFoundException e) {
            logger.warn("Product not found for ID {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error fetching product with ID {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while fetching the product.");
        }
    }

    @PostMapping("/create") // Changed from @PostMapping
    @PreAuthorize("hasRole('ADMIN')") // Only allow users with ADMIN role
    public ResponseEntity<?> createProduct(@Valid @RequestBody CreateProductRequestDTO requestDTO) {
        try {
            logger.info("Received request to create product: {}", requestDTO.getName());
            ProductDTO createdProduct = productService.createProduct(requestDTO);
            // Return 201 Created status with the location of the new resource and the resource itself
            URI location = URI.create(String.format("/api/products/%s", createdProduct.getId()));
            return ResponseEntity.created(location).body(createdProduct);
        } catch (EntityNotFoundException e) {
            logger.warn("Failed to create product. Reason: {}", e.getMessage());
            // Return 404 or 400 depending on whether it's a client error (bad ID) or server state
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage()); // e.g., "Category not found..."
        } catch (IllegalArgumentException e) {
             logger.warn("Invalid request data for creating product: {}", e.getMessage());
             return ResponseEntity.badRequest().body(e.getMessage()); // Or a more structured error response
        } catch (Exception e) {
            logger.error("Error creating product", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while creating the product.");
        }
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateProduct(@PathVariable Long id, @Valid @RequestBody UpdateProductRequestDTO requestDTO) {
        try {
            logger.info("Received request to update product with ID: {}", id);
            ProductDTO updatedProduct = productService.updateProduct(id, requestDTO);
            return ResponseEntity.ok(updatedProduct);
        } catch (EntityNotFoundException e) {
            logger.warn("Failed to update product. Reason: {}", e.getMessage());
            // Return 404 if product/category/brand not found, 400 for other validation?
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (IllegalArgumentException e) {
             logger.warn("Invalid request data for updating product {}: {}", id, e.getMessage());
             return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error updating product with ID {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while updating the product.");
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteProduct(@PathVariable Long id) {
        try {
            logger.info("Received request to delete product with ID: {}", id);
            productService.deleteProduct(id);
            return ResponseEntity.noContent().build(); // Standard response for successful DELETE
        } catch (EntityNotFoundException e) {
            logger.warn("Failed to delete product. Reason: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            // Consider catching DataIntegrityViolationException if deletion is blocked by constraints
            logger.error("Error deleting product with ID {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while deleting the product.");
        }
    }

    @GetMapping("/top-selling")
    public ResponseEntity<Page<ProductDTO>> getTopSellingProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ProductDTO> productPage = productService.findTopSellingProducts(pageable);
            if (productPage.isEmpty()) {
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            return ResponseEntity.ok(productPage);
        } catch (Exception e) {
            logger.error("Error fetching top-selling products", e);
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/top-discounted")
    public ResponseEntity<Page<ProductDTO>> getTopDiscountedProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ProductDTO> productPage = productService.findTopDiscountedProducts(pageable);
            if (productPage.isEmpty()) {
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            return ResponseEntity.ok(productPage);
        } catch (Exception e) {
            logger.error("Error fetching top-discounted products", e);
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PostMapping("/{productId}/reviews")
    public ResponseEntity<?> addProductReview(
            @PathVariable Long productId,
            @Valid @RequestBody CreateProductReviewRequestDTO reviewDTO,
            @AuthenticationPrincipal UserDetails currentUser) { 
        try {
            String userEmail = (currentUser != null) ? currentUser.getUsername() : null; // Use getUsername() which is the email
            ProductReviewDTO createdReview = productService.addReview(productId, reviewDTO, userEmail);
            return new ResponseEntity<>(createdReview, HttpStatus.CREATED);
        } catch (EntityNotFoundException e) {
            logger.warn("Cannot add review: {}", e.getMessage());
            return new ResponseEntity<>(e.getMessage(), HttpStatus.NOT_FOUND);
        } catch (IllegalArgumentException e) {
            logger.warn("Invalid review submission: {}", e.getMessage());
            return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            logger.error("Error adding product review for product ID {}: {}", productId, e.getMessage(), e);
            return new ResponseEntity<>("Error adding review.", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
