package demo.com.example.testserver.product.service.impl;

import demo.com.example.testserver.product.dto.CreateProductRequestDTO;
import demo.com.example.testserver.product.dto.ProductDTO;
import demo.com.example.testserver.product.dto.UpdateProductRequestDTO;
import demo.com.example.testserver.product.model.Brand;
import demo.com.example.testserver.product.model.Category;
import demo.com.example.testserver.product.model.Product;
import demo.com.example.testserver.product.repository.BrandRepository;
import demo.com.example.testserver.product.repository.CategoryRepository;
import demo.com.example.testserver.product.repository.ProductRepository;
import demo.com.example.testserver.product.service.*;
import jakarta.persistence.EntityNotFoundException;
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
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductServiceImpl implements ProductService {

    private static final Logger logger = LoggerFactory.getLogger(ProductServiceImpl.class);

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private BrandRepository brandRepository;

    @Autowired
    private ProductSortBuilder productSortBuilder;

    @Autowired
    private ProductSpecificationBuilder productSpecificationBuilder;

    @Autowired
    private ProductElasticsearchService productElasticsearchService;

    @Autowired
    private ProductMapper productMapper;

    @Autowired(required = false)
    private ProductDenormalizationService productDenormalizationService;

    @Override
    public Page<ProductDTO> findProducts(
            Pageable pageable,
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

        Sort sort = productSortBuilder.buildSort(sortBy, sortDir);
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sort);

        List<Integer> productIdsFromSearch = null;

        if (search != null && !search.trim().isEmpty()) {
            logger.debug("Performing Elasticsearch search for keyword: {}", search);
            productIdsFromSearch = productElasticsearchService.searchProductIds(search);
            if (productIdsFromSearch != null && productIdsFromSearch.isEmpty()) {
                logger.info("Elasticsearch returned no results for '{}'. Returning empty page.", search);
                return new PageImpl<>(Collections.emptyList(), pageRequest, 0);
            }
            if (productIdsFromSearch == null) {
                logger.warn("Elasticsearch search failed or not implemented/available. Proceeding with database filtering only for search term '{}'. Results might be incomplete.", search);
            }
        }

        Specification<Product> spec = productSpecificationBuilder.build(
            search, categoryId, brandId, minPrice, maxPrice, minRating, productIdsFromSearch, null, null // Pass null for dates
        );

        logger.debug("Executing database query with filters and pagination.");
        Page<Product> productPage = productRepository.findAll(spec, pageRequest);

        List<ProductDTO> dtos = productPage.getContent().stream()
                .map(productMapper::mapToProductDTO)
                .collect(Collectors.toList());

        logger.info("Found {} products matching criteria.", productPage.getTotalElements());
        return new PageImpl<>(dtos, pageRequest, productPage.getTotalElements());
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductDTO> findProductsAdmin(String search, Date startDate, Date endDate, Pageable pageable) {
        logger.info("Admin finding products with criteria - Search: '{}', StartDate: {}, EndDate: {}, Page: {}",
                search, startDate, endDate, pageable);

        Sort sort = pageable.getSort().isSorted() ? pageable.getSort() : Sort.by(Sort.Direction.DESC, "createdDate");
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sort);

        Specification<Product> spec = productSpecificationBuilder.build(
            search, null, null, null, null, null, null, startDate, endDate // Pass null for category, brand, price, rating, ES IDs
        );

        logger.debug("Executing admin database query with filters and pagination.");
        Page<Product> productPage = productRepository.findAll(spec, pageRequest);

        List<ProductDTO> dtos = productPage.getContent().stream()
                .map(productMapper::mapToProductDTO)
                .collect(Collectors.toList());

        logger.info("Admin search found {} products matching criteria.", productPage.getTotalElements());
        return new PageImpl<>(dtos, pageRequest, productPage.getTotalElements());
    }

    @Override
    @Transactional
    public ProductDTO findProductById(Long id) {
        logger.info("Attempting to find product with ID: {}", id);
        Product product = productRepository.findById(id)
                .orElseThrow(() -> {
                    logger.warn("Product not found with ID: {}", id);
                    return new EntityNotFoundException("Product not found with ID: " + id);
                });

        logger.info("Found product with ID: {}. Mapping to DTO.", id);
        ProductDTO productDTO = productMapper.mapToProductDTO(product);

        logger.debug("Mapped ProductDTO: ID={}, Name={}, Variants={}", productDTO.getId(), productDTO.getName(), productDTO.getVariantCount());

        return productDTO;
    }

    @Override
    @Transactional
    public ProductDTO createProduct(CreateProductRequestDTO requestDTO) {
        logger.info("Attempting to create product with name: {}", requestDTO.getName());

        Category category = categoryRepository.findById(requestDTO.getCategoryId().intValue())
                .orElseThrow(() -> new EntityNotFoundException("Category not found with ID: " + requestDTO.getCategoryId()));
        Brand brand = brandRepository.findById(requestDTO.getBrandId().intValue())
                .orElseThrow(() -> new EntityNotFoundException("Brand not found with ID: " + requestDTO.getBrandId()));

        Product product = productMapper.mapToProductEntity(requestDTO, category, brand);
        if (product == null) {
            throw new IllegalArgumentException("Failed to map DTO to Product entity. Invalid input provided.");
        }

        logger.debug("Mapped Product entity: Name={}, Category={}, Brand={}, Variants={}, Images={}",
                product.getName(),
                product.getCategory().getName(),
                product.getBrand().getName(),
                product.getVariants() != null ? product.getVariants().size() : 0,
                product.getImages() != null ? product.getImages().size() : 0);

        Product savedProduct = productRepository.save(product);
        logger.info("Product created successfully with ID: {}. Associated variants and images saved via cascade.", savedProduct.getId());

        if (productDenormalizationService != null) {
            try {
                productDenormalizationService.updateDenormalizedFields(savedProduct.getId());
                logger.info("Triggered denormalization for new product ID: {}", savedProduct.getId());
            } catch (Exception e) {
                logger.error("Error during post-creation denormalization for product ID {}: {}", savedProduct.getId(), e.getMessage(), e);
            }
        } else {
            logger.warn("ProductDenormalizationService not available. Skipping denormalization for product ID: {}", savedProduct.getId());
        }

        Product finalProduct = productRepository.findById(savedProduct.getId()).orElse(savedProduct);
        return productMapper.mapToProductDTO(finalProduct);
    }

    @Override
    @Transactional
    public ProductDTO updateProduct(Long productId, UpdateProductRequestDTO requestDTO) {
        logger.info("Attempting to update product with ID: {}", productId);

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new EntityNotFoundException("Product not found with ID: " + productId));

        Category category = categoryRepository.findById(requestDTO.getCategoryId().intValue())
                .orElseThrow(() -> new EntityNotFoundException("Category not found with ID: " + requestDTO.getCategoryId()));
        Brand brand = brandRepository.findById(requestDTO.getBrandId().intValue())
                .orElseThrow(() -> new EntityNotFoundException("Brand not found with ID: " + requestDTO.getBrandId()));

        productMapper.updateProductFromDTO(product, requestDTO, category, brand);

        Product updatedProduct = productRepository.save(product);
        logger.info("Product updated successfully with ID: {}", updatedProduct.getId());

        if (productDenormalizationService != null) {
            try {
                productDenormalizationService.updateDenormalizedFields(updatedProduct.getId());
                logger.info("Triggered denormalization for updated product ID: {}", updatedProduct.getId());
            } catch (Exception e) {
                logger.error("Error during post-update denormalization for product ID {}: {}", updatedProduct.getId(), e.getMessage(), e);
            }
        } else {
            logger.warn("ProductDenormalizationService not available. Skipping denormalization for product ID: {}", updatedProduct.getId());
        }

        Product finalProduct = productRepository.findById(updatedProduct.getId()).orElse(updatedProduct);
        return productMapper.mapToProductDTO(finalProduct);
    }

    @Override
    @Transactional
    public void deleteProduct(Long productId) {
        logger.info("Attempting to delete product with ID: {}", productId);

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new EntityNotFoundException("Product not found with ID: " + productId));

        productRepository.delete(product);

        logger.info("Product deleted successfully with ID: {}", productId);
    }
}
