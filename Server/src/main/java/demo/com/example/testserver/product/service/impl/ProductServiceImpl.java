package demo.com.example.testserver.product.service.impl;

import demo.com.example.testserver.product.dto.ProductDTO;
import demo.com.example.testserver.product.model.Product;
import demo.com.example.testserver.product.repository.ProductRepository;
import demo.com.example.testserver.product.service.*; // Import new service classes
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductServiceImpl implements ProductService {

    private static final Logger logger = LoggerFactory.getLogger(ProductServiceImpl.class);

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private ProductSortBuilder productSortBuilder;

    @Autowired
    private ProductSpecificationBuilder productSpecificationBuilder;

    @Autowired
    private ProductElasticsearchService productElasticsearchService;

    @Autowired
    private ProductMapper productMapper;

    @Override
    public Page<ProductDTO> findProducts(
            Pageable pageable, // Initial pageable might not have sort
            String search,
            Integer categoryId,
            Integer brandId,
            BigDecimal minPrice,
            BigDecimal maxPrice,
            Double minRating,
            String sortBy,
            String sortDir
    ) {
        logger.info("Finding products with criteria - Search: '{}', CategoryId: {}, BrandId: {}, Price: {}-{}, Rating >= {}, Sort: {} {}, Page: {}",
                search, categoryId, brandId, minPrice, maxPrice, minRating, sortBy, sortDir, pageable);

        // 1. Determine Sorting using ProductSortBuilder
        Sort sort = productSortBuilder.buildSort(sortBy, sortDir);
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sort);

        List<Integer> productIdsFromSearch = null;

        // 2. Check if search term exists and perform Elasticsearch search using ProductElasticsearchService
        if (search != null && !search.trim().isEmpty()) {
            logger.debug("Performing Elasticsearch search for keyword: {}", search);
            productIdsFromSearch = productElasticsearchService.searchProductIds(search /*, other filters if needed */);
            if (productIdsFromSearch != null && productIdsFromSearch.isEmpty()) {
                // If ES search returns no IDs, no need to query the database
                logger.info("Elasticsearch returned no results for '{}'. Returning empty page.", search);
                return new PageImpl<>(Collections.emptyList(), pageRequest, 0);
            }
            // If productIdsFromSearch is null, it means ES search failed or is not implemented, proceed with DB search only
            if (productIdsFromSearch == null) {
                logger.warn("Elasticsearch search failed or not implemented/available. Proceeding with database filtering only for search term '{}'. Results might be incomplete.", search);
            }
        }

        // 3. Build Dynamic Database Query using ProductSpecificationBuilder
        Specification<Product> spec = productSpecificationBuilder.build(search, categoryId, brandId, minPrice, maxPrice, minRating, productIdsFromSearch);

        // 4. Execute Database Query
        logger.debug("Executing database query with filters and pagination.");
        Page<Product> productPage = productRepository.findAll(spec, pageRequest);

        // 5. Convert Page<Product> to Page<ProductDTO> using ProductMapper
        List<ProductDTO> dtos = productPage.getContent().stream()
                .map(productMapper::mapToProductDTO) // Use mapper instance
                .collect(Collectors.toList());

        logger.info("Found {} products matching criteria.", productPage.getTotalElements());
        return new PageImpl<>(dtos, pageRequest, productPage.getTotalElements());
    }
}
