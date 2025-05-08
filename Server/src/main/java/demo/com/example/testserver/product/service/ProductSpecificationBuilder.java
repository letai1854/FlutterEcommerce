package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.model.Product;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;
import jakarta.persistence.criteria.Predicate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Component
public class ProductSpecificationBuilder {

    private static final Logger logger = LoggerFactory.getLogger(ProductSpecificationBuilder.class);

    // Modified build method to include date parameters and discount filter
    public Specification<Product> build(
            String search,
            Integer categoryId,
            Integer brandId,
            BigDecimal minPrice,
            BigDecimal maxPrice,
            Double minRating,
            List<Long> productIdsFromSearch, // Changed to List<Long>
            Date startDate,
            Date endDate,
            Boolean onlyWithDiscount // New parameter for discount filter
    ) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();
            logger.debug("Building specification with Search: '{}', CategoryId: {}, BrandId: {}, Price: {}-{}, Rating >= {}, StartDate: {}, EndDate: {}, OnlyWithDiscount: {}",
                    search, categoryId, brandId, minPrice, maxPrice, minRating, startDate, endDate, onlyWithDiscount);


            // Handle Elasticsearch search results
            if (productIdsFromSearch != null && !productIdsFromSearch.isEmpty()) {
                logger.debug("Adding filter for productIdsFromSearch (size: {})", productIdsFromSearch.size());
                // Assuming product ID in database is Long. If it's Integer, adjust `Product_.ID` or cast.
                predicates.add(root.get("id").in(productIdsFromSearch));
            } else if (search != null && !search.trim().isEmpty() && productIdsFromSearch == null) {
                // Fallback to database search if ES failed or not used, and search term is present
                logger.debug("Adding database LIKE filter for search term: {}", search);
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

            // Filter by Price Range
            if (minPrice != null) {
                logger.debug("Adding filter for minPrice: {}", minPrice);
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("minPrice"), minPrice)); // Use denormalized minPrice
            }
            if (maxPrice != null) {
                logger.debug("Adding filter for maxPrice: {}", maxPrice);
                predicates.add(criteriaBuilder.lessThanOrEqualTo(root.get("maxPrice"), maxPrice)); // Use denormalized maxPrice
            }

            // Filter by Minimum Rating
            if (minRating != null) {
                logger.debug("Adding filter for minRating: {}", minRating);
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("averageRating"), minRating)); // Use denormalized averageRating
            }

            // Filter by Date Range (for createdDate)
            if (startDate != null) {
                logger.debug("Adding filter for startDate: {}", startDate);
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("createdDate"), startDate));
            }
            if (endDate != null) {
                // To make endDate inclusive, search for dates less than the day after endDate
                // Or adjust based on exact requirements (e.g., end of day for endDate)
                logger.debug("Adding filter for endDate: {}", endDate);
                predicates.add(criteriaBuilder.lessThanOrEqualTo(root.get("createdDate"), endDate));
            }

            // Filter for products with discount
            if (Boolean.TRUE.equals(onlyWithDiscount)) {
                logger.debug("Adding filter for products with discountPercentage > 0");
                predicates.add(criteriaBuilder.isNotNull(root.get("discountPercentage")));
                predicates.add(criteriaBuilder.greaterThan(root.get("discountPercentage"), BigDecimal.ZERO));
            }

            logger.debug("Total predicates generated: {}", predicates.size());
            return criteriaBuilder.and(predicates.toArray(new Predicate[0]));
        };
    }
}
