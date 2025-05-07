package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.elasticsearch.ProductElasticsearchDTO;
import demo.com.example.testserver.product.model.Product;
import demo.com.example.testserver.product.repository.elasticsearch.ProductElasticsearchRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.client.elc.NativeQuery;
import co.elastic.clients.elasticsearch._types.query_dsl.Operator;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;
import java.util.Collections;

@Service
@ConditionalOnProperty(name = "spring.elasticsearch.enabled", havingValue = "true")
public class ProductElasticsearchService {

    private static final Logger logger = LoggerFactory.getLogger(ProductElasticsearchService.class);

    private final ProductElasticsearchRepository productElasticsearchRepository;
    private final ProductMapper productMapper;
    private final ElasticsearchOperations elasticsearchOperations;

    @Autowired
    public ProductElasticsearchService(ProductElasticsearchRepository productElasticsearchRepository,
                                       ProductMapper productMapper,
                                       ElasticsearchOperations elasticsearchOperations) {
        this.productElasticsearchRepository = productElasticsearchRepository;
        this.productMapper = productMapper;
        this.elasticsearchOperations = elasticsearchOperations;
    }

    public void saveProduct(Product product) {
        if (product == null) {
            logger.warn("Attempted to save a null product to Elasticsearch. Skipping.");
            return;
        }
        try {
            ProductElasticsearchDTO dto = productMapper.mapToProductElasticsearchDTO(product);
            if (dto == null) {
                logger.error("Failed to map Product entity with ID {} to ProductElasticsearchDTO. DTO was null.", product.getId());
                return;
            }
            productElasticsearchRepository.save(dto);
            logger.info("Successfully saved/updated product with ID {} in Elasticsearch.", dto.getId());
        } catch (Exception e) {
            logger.error("Error saving product with ID {} to Elasticsearch: {}", product.getId(), e.getMessage(), e);
        }
    }

    public void deleteProduct(Long productId) {
        try {
            productElasticsearchRepository.deleteById(productId);
            logger.info("Successfully deleted product with ID {} from Elasticsearch.", productId);
        } catch (Exception e) {
            logger.error("Error deleting product with ID {} from Elasticsearch: {}", productId, e.getMessage(), e);
        }
    }

    public ProductElasticsearchDTO findById(Long productId) {
        return productElasticsearchRepository.findById(productId).orElse(null);
    }

    public Page<ProductElasticsearchDTO> searchProducts(org.springframework.data.elasticsearch.core.query.Query searchQuery, Pageable pageable) {
        SearchHits<ProductElasticsearchDTO> searchHits = elasticsearchOperations.search(searchQuery, ProductElasticsearchDTO.class);
        List<ProductElasticsearchDTO> dtos = searchHits.getSearchHits().stream()
                .map(SearchHit::getContent)
                .collect(Collectors.toList());

        return new PageImpl<>(dtos, pageable, searchHits.getTotalHits());
    }

    public void updateProductEnabledStatus(Long productId, boolean isEnabled) {
        productElasticsearchRepository.findById(productId).ifPresent(dto -> {
            dto.setIsEnabled(isEnabled);
            productElasticsearchRepository.save(dto);
            logger.info("Updated enabled status for product ID {} to {} in Elasticsearch.", productId, isEnabled);
        });
    }

    public List<Long> searchProductIds(String search) {
        logger.info("Searching for product IDs in Elasticsearch with search term: {}", search);
        if (search == null || search.trim().isEmpty()) {
            logger.warn("Search term is empty, returning no results.");
            return Collections.emptyList();
        }
        try {
            var esMatchQuery = co.elastic.clients.elasticsearch._types.query_dsl.MatchQuery.of(m -> m
                    .field("name")
                    .query(search)
                    .operator(Operator.And)
                    .fuzziness("AUTO")
            );

            var esQuery = co.elastic.clients.elasticsearch._types.query_dsl.Query.of(qBuilder -> qBuilder
                    .match(esMatchQuery)
            );

            NativeQuery springDataQuery = NativeQuery.builder()
                    .withQuery(esQuery)
                    .build();

            SearchHits<ProductElasticsearchDTO> searchHits = elasticsearchOperations.search(springDataQuery, ProductElasticsearchDTO.class);

            return searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(ProductElasticsearchDTO::getId)
                    .collect(Collectors.toList());

        } catch (Exception e) {
            logger.error("Error searching for products with term {}: {}. Returning null to allow fallback.", search, e.getMessage(), e);
            return null;
        }
    }

    public void deleteProductById(Long productId) {
        logger.info("Deleting product with ID: {} from Elasticsearch", productId);
        try {
            productElasticsearchRepository.deleteById(productId);
            logger.info("Successfully deleted product with ID {} from Elasticsearch.", productId);
        } catch (Exception e) {
            logger.error("Error deleting product with ID {} from Elasticsearch: {}", productId, e.getMessage(), e);
        }
    }
}
