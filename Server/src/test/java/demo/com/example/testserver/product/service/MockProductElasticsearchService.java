package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.model.Product;
import org.mockito.Mockito;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import demo.com.example.testserver.product.repository.elasticsearch.ProductElasticsearchRepository;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * A mock implementation of ProductElasticsearchService for testing purposes.
 * This allows tests to run without requiring an actual Elasticsearch instance.
 */
@Service
public class MockProductElasticsearchService extends ProductElasticsearchService {

    private static final Logger logger = LoggerFactory.getLogger(MockProductElasticsearchService.class);

    public MockProductElasticsearchService() {
        super(Mockito.mock(ProductElasticsearchRepository.class), Mockito.mock(ProductMapper.class), Mockito.mock(ElasticsearchOperations.class)); // Pass mock objects
        logger.info("Creating MockProductElasticsearchService for testing");
    }

    @Override
    public List<Long> searchProductIds(String searchKeyword) {
        logger.info("Mock Elasticsearch search for: {}", searchKeyword);
        // Return empty list as default mock behavior
        return Collections.emptyList();
    }

    @Override
    public void saveProduct(Product product) {
        logger.info("Mock saving product to Elasticsearch: {}", product.getId());
        // Do nothing in mock implementation
    }

    @Override
    public void deleteProductById(Long productId) {
        logger.info("Mock deleting product from Elasticsearch: {}", productId);
        // Do nothing in mock implementation
    }
}
