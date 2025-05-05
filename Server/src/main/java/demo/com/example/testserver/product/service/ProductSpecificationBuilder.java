package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.model.Product;
import jakarta.persistence.criteria.Predicate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Component
public class ProductSpecificationBuilder {

    private static final Logger logger = LoggerFactory.getLogger(ProductSpecificationBuilder.class);

    public Specification<Product> build(
            String search, // Keep search term for potential DB fallback LIKE search if needed
            Integer categoryId,
            Integer brandId,
            BigDecimal minPrice,
            BigDecimal maxPrice,
            Double minRating,
            List<Integer> productIdsFromSearch // Keep as Integer for now, adjust if ES service changes
            // List<Long> productIdsFromSearch // Use Long if ES returns Long IDs
    ) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Filter by IDs from Elasticsearch if available
            if (productIdsFromSearch != null && !productIdsFromSearch.isEmpty()) {
                logger.debug("Adding ID filter from Elasticsearch results ({} IDs)", productIdsFromSearch.size());
                // Ensure the 'in' clause uses the correct type (Long for Product.id)
                predicates.add(root.get("id").in(productIdsFromSearch.stream().map(Long::valueOf).toList())); // Convert Integer IDs to Long
                // If productIdsFromSearch is already List<Long>, use:
                // predicates.add(root.get("id").in(productIdsFromSearch));
            } else if (productIdsFromSearch == null && search != null && !search.trim().isEmpty()) {
                // Fallback: If ES search failed (returned null) but search term exists,
                // consider adding a basic LIKE predicate. Be cautious about performance.
                logger.warn("Elasticsearch search failed or unavailable for term '{}'. Adding DB LIKE search fallback.", search);
                predicates.add(criteriaBuilder.like(criteriaBuilder.lower(root.get("name")), "%" + search.toLowerCase() + "%"));
                // Could also search description:
                // Predicate nameLike = criteriaBuilder.like(criteriaBuilder.lower(root.get("name")), "%" + search.toLowerCase() + "%");
                // Predicate descriptionLike = criteriaBuilder.like(criteriaBuilder.lower(root.get("description")), "%" + search.toLowerCase() + "%");
                // predicates.add(criteriaBuilder.or(nameLike, descriptionLike));
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
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("minPrice"), minPrice));
            }
            if (maxPrice != null) {
                // Ensure maxPrice filter includes products where maxPrice is exactly the filter value
                logger.debug("Adding filter for maxPrice: {}", maxPrice);
                 // Check if product's minPrice <= maxPriceFilter AND product's maxPrice >= minPriceFilter
                 // A simpler approach using denormalized fields: filter products whose price range overlaps the query range.
                 // However, the current logic filters products whose *entire* range falls *within* the query range.
                 // Let's stick to the simpler: Product.maxPrice <= maxPriceFilter
                 // And Product.minPrice >= minPriceFilter (already handled above)
                predicates.add(criteriaBuilder.lessThanOrEqualTo(root.get("maxPrice"), maxPrice));
                 // Consider if the logic should be: find products where *any* variant price is within the range.
                 // This would require a subquery or join, making it more complex. Denormalized fields are simpler.
            }


            // Filter by Minimum Rating using denormalized field
            if (minRating != null && minRating > 0) {
                logger.debug("Adding filter for minRating: {}", minRating);
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("averageRating"), minRating));
            }

            // Combine predicates
            if (predicates.isEmpty()) {
                return criteriaBuilder.conjunction(); // Return a predicate that always evaluates to true if no filters
            }
            return criteriaBuilder.and(predicates.toArray(new Predicate[0]));
        };
    }
}
