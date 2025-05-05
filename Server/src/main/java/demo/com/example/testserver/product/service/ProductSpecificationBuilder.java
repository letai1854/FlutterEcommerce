package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.model.Product;
import jakarta.persistence.criteria.Predicate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Date; // Import Date
import java.util.List;

@Component
public class ProductSpecificationBuilder {

    private static final Logger logger = LoggerFactory.getLogger(ProductSpecificationBuilder.class);

    // Modified build method to include date parameters
    public Specification<Product> build(
            String search,
            Integer categoryId,
            Integer brandId,
            BigDecimal minPrice,
            BigDecimal maxPrice,
            Double minRating,
            List<Integer> productIdsFromSearch,
            Date startDate, // New parameter
            Date endDate    // New parameter
    ) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Filter by IDs from Elasticsearch if available
            if (productIdsFromSearch != null && !productIdsFromSearch.isEmpty()) {
                logger.debug("Adding ID filter from Elasticsearch results ({} IDs)", productIdsFromSearch.size());
                predicates.add(root.get("id").in(productIdsFromSearch.stream().map(Long::valueOf).toList()));
            } else if (productIdsFromSearch == null && search != null && !search.trim().isEmpty()) {
                // Fallback: Nếu tìm kiếm ES thất bại hoặc không có, dùng LIKE search trong DB
                logger.warn("Elasticsearch search failed or unavailable for term '{}'. Adding DB LIKE search fallback.", search);
                // Tìm trong tên HOẶC mô tả sản phẩm (không phân biệt hoa thường)
                 Predicate nameLike = criteriaBuilder.like(criteriaBuilder.lower(root.get("name")), "%" + search.toLowerCase() + "%");
                 Predicate descriptionLike = criteriaBuilder.like(criteriaBuilder.lower(root.get("description")), "%" + search.toLowerCase() + "%");
                 predicates.add(criteriaBuilder.or(nameLike, descriptionLike)); // Thêm điều kiện OR vào câu truy vấn
            }

            // Filter by Category
            if (categoryId != null) {
                logger.debug("Adding filter for categoryId: {}", categoryId);
                predicates.add(criteriaBuilder.equal(root.get("category").get("id"), categoryId));
            }

            // Filter by Brand
            if (brandId != null) {
                logger.debug("Adding filter for brandId: {}", brandId);
                predicates.add(criteriaBuilder.equal(root.get("brand").get("id"), brandId));
            }

            // Filter by Price Range using denormalized fields
            if (minPrice != null) {
                logger.debug("Adding filter for minPrice: {}", minPrice);
                // Assuming minPrice in DB represents the lowest price of any variant
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("minPrice"), minPrice));
            }
            if (maxPrice != null) {
                logger.debug("Adding filter for maxPrice: {}", maxPrice);
                 // Assuming maxPrice in DB represents the highest price of any variant
                 // Find products where *some* variant might be <= maxPrice.
                 // A simple filter on minPrice might be sufficient depending on desired behavior:
                 // If a product's lowest variant price is above maxPrice, exclude it.
                predicates.add(criteriaBuilder.lessThanOrEqualTo(root.get("minPrice"), maxPrice)); // Changed from maxPrice field
            }

            // Filter by Minimum Rating using denormalized field
            if (minRating != null && minRating > 0) {
                logger.debug("Adding filter for minRating: {}", minRating);
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("averageRating"), minRating));
            }

            // Filter by Creation Date Range
            if (startDate != null) {
                logger.debug("Adding filter for startDate: {}", startDate);
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("createdDate"), startDate));
            }
            if (endDate != null) {
                logger.debug("Adding filter for endDate: {}", endDate);
                // To include the whole day, consider setting time to 23:59:59 or using LocalDate comparison if applicable
                predicates.add(criteriaBuilder.lessThanOrEqualTo(root.get("createdDate"), endDate));
            }


            // Combine predicates
            if (predicates.isEmpty()) {
                return criteriaBuilder.conjunction(); // Return a predicate that always evaluates to true if no filters
            }
            return criteriaBuilder.and(predicates.toArray(new Predicate[0]));
        };
    }
}
