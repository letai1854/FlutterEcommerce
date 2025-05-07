package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.elasticsearch.ProductElasticsearchDTO;
import demo.com.example.testserver.product.model.Product;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.query.Query;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

/**
 * A fallback implementation when Elasticsearch is disabled or unavailable.
 * This service is activated if ProductElasticsearchService is not created.
 */
@Service
@ConditionalOnMissingBean(ProductElasticsearchService.class)
public class FallbackProductElasticsearchService {

    private static final Logger logger = LoggerFactory.getLogger(FallbackProductElasticsearchService.class);

    public FallbackProductElasticsearchService() {
        logger.info("FallbackProductElasticsearchService is active (Elasticsearch not configured, disabled, or unavailable).");
    }

    public void saveProduct(Product product) {
        logger.debug("Elasticsearch fallback - Not saving product with ID: {}", product != null ? product.getId() : "null");
    }

    public void deleteProduct(Long productId) {
        logger.debug("Elasticsearch fallback - Not deleting product with ID: {}", productId);
    }

    public void deleteProductById(Long productId) {
        logger.debug("Elasticsearch fallback - Not deleting product with ID: {}", productId);
    }

    public ProductElasticsearchDTO findById(Long productId) {
        logger.debug("Elasticsearch fallback - Not finding product by ID: {}", productId);
        return null;
    }

    public Page<ProductElasticsearchDTO> searchProducts(Query searchQuery, Pageable pageable) {
        logger.debug("Elasticsearch fallback - Not searching products.");
        return new PageImpl<>(Collections.emptyList(), pageable, 0);
    }

    public void updateProductEnabledStatus(Long productId, boolean isEnabled) {
        logger.debug("Elasticsearch fallback - Not updating product enabled status for ID: {}", productId);
    }

    public List<Long> searchProductIds(String search) {
        logger.debug("Elasticsearch fallback - Not searching product IDs for: {}", search);
        // If a search term is provided when ES is disabled/unavailable,
        // return null to allow ProductServiceImpl to fallback to database search.
        if (search != null && !search.trim().isEmpty()) {
            return null;
        }
        return Collections.emptyList();
    }
}
