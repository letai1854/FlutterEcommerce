package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.CreateProductRequestDTO;
import demo.com.example.testserver.product.dto.ProductDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;

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
     * Creates a new product based on the provided data.
     *
     * @param requestDTO DTO containing the details for the new product.
     * @return The created ProductDTO.
     */
    ProductDTO createProduct(CreateProductRequestDTO requestDTO);

    // Add other methods as needed, e.g., findProductById
}
