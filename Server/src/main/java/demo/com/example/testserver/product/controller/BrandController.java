package demo.com.example.testserver.product.controller;

import demo.com.example.testserver.product.dto.BrandDTO;
import demo.com.example.testserver.product.dto.CreateBrandRequestDTO;
import demo.com.example.testserver.product.dto.UpdateBrandRequestDTO;
import demo.com.example.testserver.product.service.BrandService; // Assuming this service exists
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/brands")
@CrossOrigin(origins = "*")
public class BrandController {

    private static final Logger logger = LoggerFactory.getLogger(BrandController.class);

    @Autowired
    private BrandService brandService; // Inject BrandService

    @GetMapping
    public ResponseEntity<List<BrandDTO>> getAllBrands() {
        try {
            List<BrandDTO> brands = brandService.findAllBrands();
            if (brands.isEmpty()) {
                return ResponseEntity.noContent().build();
            }
            return ResponseEntity.ok(brands);
        } catch (Exception e) {
            logger.error("Error fetching all brands", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getBrandById(@PathVariable Integer id) {
        try {
            logger.info("Received request to get brand by ID: {}", id);
            BrandDTO brandDTO = brandService.findBrandById(id);
            return ResponseEntity.ok(brandDTO);
        } catch (EntityNotFoundException e) {
            logger.warn("Brand not found for ID {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error fetching brand with ID {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred.");
        }
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createBrand(@Valid @RequestBody CreateBrandRequestDTO requestDTO) {
        try {
            logger.info("Received request to create brand: {}", requestDTO.getName());
            BrandDTO createdBrand = brandService.createBrand(requestDTO);
            URI location = URI.create(String.format("/api/brands/%s", createdBrand.getId()));
            return ResponseEntity.created(location).body(createdBrand);
        } catch (IllegalArgumentException e) { // Catch potential duplicate name errors from service
             logger.warn("Invalid request data for creating brand: {}", e.getMessage());
             return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error creating brand", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred.");
        }
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateBrand(@PathVariable Integer id, @Valid @RequestBody UpdateBrandRequestDTO requestDTO) {
        try {
            logger.info("Received request to update brand with ID: {}", id);
            BrandDTO updatedBrand = brandService.updateBrand(id, requestDTO);
            return ResponseEntity.ok(updatedBrand);
        } catch (EntityNotFoundException e) {
            logger.warn("Failed to update brand. Reason: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (IllegalArgumentException e) {
             logger.warn("Invalid request data for updating brand {}: {}", id, e.getMessage());
             return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error updating brand with ID {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred.");
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteBrand(@PathVariable Integer id) {
        try {
            logger.info("Received request to delete brand with ID: {}", id);
            brandService.deleteBrand(id);
            return ResponseEntity.noContent().build();
        } catch (EntityNotFoundException e) {
            logger.warn("Failed to delete brand. Reason: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) { // Consider DataIntegrityViolationException if linked to products
            logger.error("Error deleting brand with ID {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred.");
        }
    }
}
