package demo.com.example.testserver.product.controller;

import demo.com.example.testserver.product.dto.CreateProductRequestDTO; // Import new DTO
import demo.com.example.testserver.product.dto.ProductDTO;
import demo.com.example.testserver.product.service.ProductService;
import jakarta.persistence.EntityNotFoundException; // Import
import jakarta.validation.Valid; // Import for validation
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize; // Import PreAuthorize

import java.math.BigDecimal;
import java.net.URI; // Import for location header

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

    // Add other endpoints like getProductById, updateProduct, deleteProduct as needed
    // Example:
    /*
    @GetMapping("/{id}")
    public ResponseEntity<ProductDTO> getProductById(@PathVariable Integer id) {
        // Implementation using productService.findProductById(id)
    }
    */
}
