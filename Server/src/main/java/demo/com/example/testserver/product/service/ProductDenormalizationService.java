package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.model.Product;
import demo.com.example.testserver.product.model.ProductReview;
import demo.com.example.testserver.product.model.ProductVariant;
import demo.com.example.testserver.product.repository.ProductRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Objects;
import java.util.Optional;
import java.util.OptionalDouble;

@Service
public class ProductDenormalizationService {

    private static final Logger logger = LoggerFactory.getLogger(ProductDenormalizationService.class);

    @Autowired
    private ProductRepository productRepository;

    @Transactional // Ensure this method runs in a transaction
    public void updateDenormalizedFields(Integer productId) {
        logger.debug("Updating denormalized fields for product ID: {}", productId);
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found with ID: " + productId)); // Or a custom exception

        // Calculate min and max price from variants
        BigDecimal minPrice = null;
        BigDecimal maxPrice = null;
        if (product.getVariants() != null && !product.getVariants().isEmpty()) {
            Optional<BigDecimal> calculatedMinPrice = product.getVariants().stream()
                    .map(ProductVariant::getPrice)
                    .filter(Objects::nonNull)
                    .min(BigDecimal::compareTo);
            Optional<BigDecimal> calculatedMaxPrice = product.getVariants().stream()
                    .map(ProductVariant::getPrice)
                    .filter(Objects::nonNull)
                    .max(BigDecimal::compareTo);

            minPrice = calculatedMinPrice.orElse(null);
            maxPrice = calculatedMaxPrice.orElse(null);
        }
        product.setMinPrice(minPrice);
        product.setMaxPrice(maxPrice);
        logger.debug("Calculated minPrice: {}, maxPrice: {} for product ID: {}", minPrice, maxPrice, productId);

        // Calculate average rating from reviews
        Double averageRating = null;
        if (product.getReviews() != null && !product.getReviews().isEmpty()) {
            OptionalDouble calculatedAverageRating = product.getReviews().stream()
                    .map(ProductReview::getRating)
                    .filter(Objects::nonNull) // Filter out null ratings
                    .mapToDouble(Byte::doubleValue) // Convert Byte to double
                    .average();

            averageRating = calculatedAverageRating.isPresent() ? calculatedAverageRating.getAsDouble() : null;
        }
        product.setAverageRating(averageRating);
        logger.debug("Calculated averageRating: {} for product ID: {}", averageRating, productId);

        // Save the updated product
        productRepository.save(product);
        logger.info("Denormalized fields updated successfully for product ID: {}", productId);
    }
}
