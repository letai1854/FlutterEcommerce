package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.CreateProductRequestDTO;
import demo.com.example.testserver.product.dto.ProductDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import demo.com.example.testserver.product.dto.UpdateProductRequestDTO; // Import Update DTO

import java.math.BigDecimal;
import java.util.Date; // Import Date

public interface ProductService {

    /**
     * Finds products based on various criteria including search, filtering, sorting, and pagination.
     *
     * @param pageable Page request (page number, size).
     * @param search Optional search keyword (for full-text search).
     * @param categoryId Optional category ID to filter by.
     * @param brandId Optional brand ID to filter by.
     * @param minPrice Optional minimum price filter.
     * @param maxPrice Optional maximum price filter.
     * @param minRating Optional minimum average rating filter.
     * @param sortBy Optional field to sort by (e.g., "name", "price", "createdDate", "rating").
     * @param sortDir Optional sort direction ("asc" or "desc").
     * @return A page of ProductDTOs matching the criteria.
     */
    Page<ProductDTO> findProducts(
            Pageable pageable,
            String search,
            Integer categoryId,
            Integer brandId,
            BigDecimal minPrice,
            BigDecimal maxPrice,
            Double minRating,
            String sortBy,
            String sortDir
    );

    /**
     * Finds products for admin based on search term, date range, and pagination.
     *
     * @param search Optional search keyword (for full-text search).
     * @param startDate Optional start date filter.
     * @param endDate Optional end date filter.
     * @param pageable Page request (page number, size).
     * @return A page of ProductDTOs matching the criteria.
     */
    Page<ProductDTO> findProductsAdmin(String search, Date startDate, Date endDate, Pageable pageable);

    /**
     * Creates a new product based on the provided data.
     *
     * @param requestDTO DTO containing the details for the new product.
     * @return The created ProductDTO.
     */
    ProductDTO createProduct(CreateProductRequestDTO requestDTO);

    /**
     * Finds a single product by its ID.
     * Includes detailed information like variants.
     *
     * @param id The ID of the product to find.
     * @return The ProductDTO containing detailed product information.
     * @throws jakarta.persistence.EntityNotFoundException if the product with the given ID is not found.
     */
    ProductDTO findProductById(Long id);

    /**
     * Updates an existing product with the provided data.
     * Handles merging/updating of variants and images.
     *
     * @param productId The ID of the product to update.
     * @param requestDTO DTO containing the updated product details.
     * @return The updated ProductDTO.
     * @throws jakarta.persistence.EntityNotFoundException if the product, category, or brand is not found.
     */
    ProductDTO updateProduct(Long productId, UpdateProductRequestDTO requestDTO);

    /**
     * Deletes a product and its associated variants and images.
     *
     * @param productId The ID of the product to delete.
     * @throws jakarta.persistence.EntityNotFoundException if the product is not found.
     */
    void deleteProduct(Long productId);

    // Add other methods as needed
}
