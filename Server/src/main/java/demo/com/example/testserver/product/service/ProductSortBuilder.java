package demo.com.example.testserver.product.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

@Component
public class ProductSortBuilder {

    private static final Logger logger = LoggerFactory.getLogger(ProductSortBuilder.class);

    public Sort buildSort(String sortBy, String sortDir) {
        Sort sort = Sort.unsorted();
        if (sortBy != null && !sortBy.trim().isEmpty()) {
            Sort.Direction direction = (sortDir != null && sortDir.equalsIgnoreCase("desc")) ? Sort.Direction.DESC : Sort.Direction.ASC;

            // Map API sort fields to entity fields
            String sortField = switch (sortBy.toLowerCase()) {
                case "name" -> "name";
                case "price" -> "variantZeroPrice"; // Use denormalized price of the first variant for price sorting
                case "rating" -> "averageRating"; // Use denormalized averageRating for rating sorting
                case "newest", "createddate" -> "createdDate";
                default -> {
                    logger.warn("Unsupported sort field '{}'. Using default sort.", sortBy);
                    yield "createdDate"; // Default sort field
                }
            };

            // Ensure fallback uses default direction if needed
            if ("createdDate".equals(sortField) && !"createdDate".equalsIgnoreCase(sortBy)) {
                direction = Sort.Direction.DESC; // Default direction for fallback
            }

            sort = Sort.by(direction, sortField);
        }
        // Add a default sort if no specific sort is requested or if the requested sort is complex/invalid
        if (sort.isUnsorted()) {
            sort = Sort.by(Sort.Direction.DESC, "createdDate"); // Default to newest
        }
        logger.debug("Applied sort: {}", sort);
        return sort;
    }
}
