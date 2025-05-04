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
            List<Integer> productIdsFromSearch // IDs from Elasticsearch
    ) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Filter by IDs from Elasticsearch if available
            if (productIdsFromSearch != null && !productIdsFromSearch.isEmpty()) {
                logger.debug("Adding ID filter from Elasticsearch results ({} IDs)", productIdsFromSearch.size());
                predicates.add(root.get("id").in(productIdsFromSearch));
            }
            // TODO: If productIdsFromSearch is null and 'search' is not empty,
            // consider adding a basic LIKE predicate as a fallback?
            // Example: predicates.add(criteriaBuilder.like(root.get("name"), "%" + search + "%"));
            // Be cautious about performance with LIKE on large tables.

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
                logger.debug("Adding filter for maxPrice: {}", maxPrice);
                predicates.add(criteriaBuilder.lessThanOrEqualTo(root.get("maxPrice"), maxPrice));
            }

            // Filter by Minimum Rating using denormalized field
            if (minRating != null && minRating > 0) {
                logger.debug("Adding filter for minRating: {}", minRating);
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("averageRating"), minRating));
            }

            // Combine predicates
            return criteriaBuilder.and(predicates.toArray(new Predicate[0]));
        };
    }
}
