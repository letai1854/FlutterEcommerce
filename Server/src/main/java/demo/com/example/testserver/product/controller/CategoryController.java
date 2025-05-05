package demo.com.example.testserver.product.controller;

import demo.com.example.testserver.product.dto.CategoryDTO;
import demo.com.example.testserver.product.dto.CreateCategoryRequestDTO;
import demo.com.example.testserver.product.dto.UpdateCategoryRequestDTO;
import demo.com.example.testserver.product.service.CategoryService; // Assuming this service exists
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page; // Import Page
import org.springframework.data.domain.Pageable; // Import Pageable
import org.springframework.data.web.PageableDefault; // Import PageableDefault
import org.springframework.format.annotation.DateTimeFormat; // Import DateTimeFormat
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.Date; // Import Date
import java.util.List;

@RestController
@RequestMapping("/api/categories")
@CrossOrigin(origins = "*")
public class CategoryController {

    private static final Logger logger = LoggerFactory.getLogger(CategoryController.class);

    @Autowired
    private CategoryService categoryService; // Inject CategoryService

    @GetMapping
    public ResponseEntity<Page<CategoryDTO>> getAllCategories(
            @PageableDefault(size = 10, sort = "createdDate,desc") Pageable pageable, // Add Pageable parameter
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) Date startDate, // Add startDate
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) Date endDate // Add endDate
    ) {
        try {
            logger.info("Received request to get categories with pageable: {}, startDate: {}, endDate: {}", pageable, startDate, endDate);
            Page<CategoryDTO> categoriesPage = categoryService.findCategories(pageable, startDate, endDate);
            if (categoriesPage.isEmpty()) {
                logger.info("No categories found for the given criteria.");
                // Return empty page instead of noContent for consistency with pagination
                return ResponseEntity.ok(categoriesPage);
            }
            logger.info("Returning page {} of categories.", categoriesPage.getNumber());
            return ResponseEntity.ok(categoriesPage);
        } catch (Exception e) {
            logger.error("Error fetching categories with pagination", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getCategoryById(@PathVariable Integer id) {
        try {
            logger.info("Received request to get category by ID: {}", id);
            CategoryDTO categoryDTO = categoryService.findCategoryById(id);
            return ResponseEntity.ok(categoryDTO);
        } catch (EntityNotFoundException e) {
            logger.warn("Category not found for ID {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error fetching category with ID {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred.");
        }
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createCategory(@Valid @RequestBody CreateCategoryRequestDTO requestDTO) {
        try {
            logger.info("Received request to create category: {}", requestDTO.getName());
            CategoryDTO createdCategory = categoryService.createCategory(requestDTO);
            URI location = URI.create(String.format("/api/categories/%s", createdCategory.getId()));
            return ResponseEntity.created(location).body(createdCategory);
        } catch (IllegalArgumentException e) { // Catch potential duplicate name errors from service
             logger.warn("Invalid request data for creating category: {}", e.getMessage());
             return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error creating category", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred.");
        }
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateCategory(@PathVariable Integer id, @Valid @RequestBody UpdateCategoryRequestDTO requestDTO) {
        try {
            logger.info("Received request to update category with ID: {}", id);
            CategoryDTO updatedCategory = categoryService.updateCategory(id, requestDTO);
            return ResponseEntity.ok(updatedCategory);
        } catch (EntityNotFoundException e) {
            logger.warn("Failed to update category. Reason: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (IllegalArgumentException e) {
             logger.warn("Invalid request data for updating category {}: {}", id, e.getMessage());
             return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error updating category with ID {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred.");
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteCategory(@PathVariable Integer id) {
        try {
            logger.info("Received request to delete category with ID: {}", id);
            categoryService.deleteCategory(id);
            return ResponseEntity.noContent().build();
        } catch (EntityNotFoundException e) {
            logger.warn("Failed to delete category. Reason: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) { // Consider DataIntegrityViolationException if linked to products
            logger.error("Error deleting category with ID {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred.");
        }
    }
}
