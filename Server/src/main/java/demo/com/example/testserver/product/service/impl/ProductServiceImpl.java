package demo.com.example.testserver.product.service.impl;

import demo.com.example.testserver.product.dto.CreateProductRequestDTO;
import demo.com.example.testserver.product.dto.ProductDTO;
import demo.com.example.testserver.product.dto.UpdateProductRequestDTO;
import demo.com.example.testserver.product.dto.CreateProductReviewRequestDTO;
import demo.com.example.testserver.product.dto.ProductReviewDTO;
import demo.com.example.testserver.product.model.Brand;
import demo.com.example.testserver.product.model.Category;
import demo.com.example.testserver.product.model.Product;
import demo.com.example.testserver.product.model.ProductReview;
import demo.com.example.testserver.product.repository.BrandRepository;
import demo.com.example.testserver.product.repository.CategoryRepository;
import demo.com.example.testserver.product.repository.ProductRepository;
import demo.com.example.testserver.product.repository.ProductReviewRepository;
import demo.com.example.testserver.product.service.*;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.UserRepository;
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
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

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

    @Autowired(required = false) // Make Elasticsearch service optional
    private ProductElasticsearchService productElasticsearchService;

    @Autowired
    private FallbackProductElasticsearchService fallbackProductElasticsearchService; // Inject fallback

    @Autowired
    private ProductMapper productMapper;

    @Autowired
    private ProductDenormalizationService productDenormalizationService;

    @Autowired
    private ProductReviewRepository productReviewRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate; // Added for WebSocket broadcasting

    // Helper method to convert Sort object with entity properties to SQL column names
    private Sort convertToNativeSort(Sort entitySort) {
        if (entitySort == null || entitySort.isUnsorted()) {
            // Default sort for native query if none is provided or if it's unsorted
            return Sort.by(Sort.Direction.DESC, "ngay_tao");
        }
        List<Sort.Order> nativeOrders = entitySort.stream()
            .map(order -> {
                String property = order.getProperty();
                String sqlColumn;
                switch (property.toLowerCase()) {
                    case "createddate":
                    case "newest": // Alias for createdDate
                        sqlColumn = "ngay_tao";
                        break;
                    case "name":
                        sqlColumn = "ten_san_pham";
                        break;
                    case "averagerating":
                    case "rating": // Alias for averageRating
                        sqlColumn = "average_rating";
                        break;
                    case "variantzeroprice": // Used by ProductSortBuilder for "price"
                    case "price":
                        sqlColumn = "variant_zero_price";
                        break;
                    // Add other mappings if ProductSortBuilder supports more fields for Product
                    default:
                        // Fallback to a default known column if property is not explicitly mapped
                        // This prevents errors if an unmapped property is somehow passed.
                        // Alternatively, could throw an exception for unmapped properties.
                        sqlColumn = "ngay_tao"; // Default fallback column
                }
                return order.isAscending() ? Sort.Order.asc(sqlColumn) : Sort.Order.desc(sqlColumn);
            })
            .collect(Collectors.toList());
        return Sort.by(nativeOrders);
    }

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

        List<Long> productIdsFromSearch = null;
        boolean useFullTextSearch = false;

        if (search != null && !search.trim().isEmpty()) {
            logger.debug("Performing Elasticsearch search for keyword: {}", search);
            if (productElasticsearchService != null) {
                productIdsFromSearch = productElasticsearchService.searchProductIds(search);
                if (productIdsFromSearch != null && productIdsFromSearch.isEmpty()) {
                    logger.info("Elasticsearch returned no results for '{}'. Attempting fallback to database search.", search);
                    productIdsFromSearch = null; // Signal to use DB search
                    useFullTextSearch = fallbackProductElasticsearchService.isFullTextSearchEnabled(); // Check if Full-Text Search is enabled
                } else if (productIdsFromSearch == null) {
                    // This case might indicate an issue with the ES service itself, even if available
                    logger.warn("Elasticsearch search returned null (possibly an error or timeout) for search term '{}'. Falling back to database search.", search);
                    useFullTextSearch = fallbackProductElasticsearchService.isFullTextSearchEnabled(); // Check if Full-Text Search is enabled
                }
            } else {
                logger.info("Elasticsearch service is not available. Using fallback for search term: {}", search);
                productIdsFromSearch = fallbackProductElasticsearchService.searchProductIds(search); // Fallback returns null to trigger DB search
                useFullTextSearch = fallbackProductElasticsearchService.isFullTextSearchEnabled(); // Check if Full-Text Search is enabled
            }
        }

        // Handle full-text search with native query if needed
        Page<Product> productPage;
        if (search != null && !search.trim().isEmpty() && productIdsFromSearch == null && useFullTextSearch) {
            logger.info("Using native MySQL full-text search for term: {}", search);
            String searchTermWithWildcard = search + "*"; // Add wildcard for partial matches
            try {
                // Convert sort properties to native SQL column names for the native query
                Sort nativeQuerySort = convertToNativeSort(sort);
                Pageable nativePageRequest = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), nativeQuerySort);
                productPage = productRepository.findByFullTextSearch(searchTermWithWildcard, nativePageRequest);
                logger.debug("Full-text search returned {} results", productPage.getTotalElements());
            } catch (Exception e) {
                logger.error("Error executing full-text search: {}", e.getMessage(), e);
                // Fallback to regular specification if full-text search fails
                logger.info("Falling back to regular specification search after full-text search error");
                Specification<Product> spec = productSpecificationBuilder.build(
                    search, categoryId, brandId, minPrice, maxPrice, minRating, productIdsFromSearch, 
                    null, null, false, false // Set useFullTextSearch to false to use LIKE instead
                );
                productPage = productRepository.findAll(spec, pageRequest);
            }
        } else {
            // Use standard specification 
            Specification<Product> spec = productSpecificationBuilder.build(
                search, categoryId, brandId, minPrice, maxPrice, minRating, productIdsFromSearch, 
                null, null, false, useFullTextSearch
            );
            logger.debug("Executing database query with filters and pagination.");
            productPage = productRepository.findAll(spec, pageRequest);
        }

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
        // Initialize pageRequest here
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sort);

        List<Long> productIdsFromSearch = null;
        boolean useFullTextSearch = false;
        
        if (search != null && !search.trim().isEmpty()) {
            logger.debug("Admin: Performing Elasticsearch search for keyword: {}", search);
            if (productElasticsearchService != null) {
                productIdsFromSearch = productElasticsearchService.searchProductIds(search);
                if (productIdsFromSearch != null && productIdsFromSearch.isEmpty()) {
                    logger.info("Admin: Elasticsearch returned no results for '{}'. Attempting fallback to database search.", search);
                    productIdsFromSearch = null; // Signal to use DB search
                    useFullTextSearch = fallbackProductElasticsearchService.isFullTextSearchEnabled(); // Check if Full-Text Search is enabled
                } else if (productIdsFromSearch == null) {
                    logger.warn("Admin: Elasticsearch search returned null for search term '{}'. Falling back to database search.", search);
                    useFullTextSearch = fallbackProductElasticsearchService.isFullTextSearchEnabled(); // Check if Full-Text Search is enabled
                }
            } else {
                logger.info("Admin: Elasticsearch service is not available. Using fallback for search term: {}", search);
                productIdsFromSearch = fallbackProductElasticsearchService.searchProductIds(search); // Fallback returns null to trigger DB search
                useFullTextSearch = fallbackProductElasticsearchService.isFullTextSearchEnabled(); // Check if Full-Text Search is enabled
            }
        }

        // Handle full-text search with native query if needed
        Page<Product> productPage;
        if (search != null && !search.trim().isEmpty() && productIdsFromSearch == null && useFullTextSearch) {
            logger.info("Admin: Using native MySQL full-text search for term: {}", search);
            String searchTermWithWildcard = search + "*"; // Add wildcard for partial matches
            try {
                // Convert sort properties to native SQL column names for the native query
                Sort nativeQuerySort = convertToNativeSort(sort); // Use the same conversion
                Pageable nativePageRequest = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), nativeQuerySort);
                productPage = productRepository.findByFullTextSearch(searchTermWithWildcard, nativePageRequest);
                logger.debug("Admin: Full-text search returned {} results", productPage.getTotalElements());
            } catch (Exception e) {
                logger.error("Admin: Error executing full-text search: {}", e.getMessage(), e);
                // Fallback to regular specification if full-text search fails
                logger.info("Admin: Falling back to regular specification search after full-text search error");
                Specification<Product> spec = productSpecificationBuilder.build(
                    search, null, null, null, null, null, productIdsFromSearch, startDate, endDate, false, false // Set useFullTextSearch to false to use LIKE instead
                );
                productPage = productRepository.findAll(spec, pageRequest); // Now pageRequest is defined
            }
        } else {
            // Use standard specification 
            Specification<Product> spec = productSpecificationBuilder.build(
                search, null, null, null, null, null, productIdsFromSearch, startDate, endDate, false, useFullTextSearch
            );
            logger.debug("Executing admin database query with filters and pagination.");
            productPage = productRepository.findAll(spec, pageRequest); // Now pageRequest is defined
        }

        List<ProductDTO> dtos = productPage.getContent().stream()
                .map(productMapper::mapToProductDTO)
                .collect(Collectors.toList());

        logger.info("Admin search found {} products matching criteria.", productPage.getTotalElements());
        return new PageImpl<>(dtos, pageRequest, productPage.getTotalElements()); // Now pageRequest is defined
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

        logger.info("Found product with ID: {}. Mapping to DTO with details.", id);
        ProductDTO productDTO = productMapper.mapToProductDetailDTO(product); // Use detail mapper to include reviews

        logger.debug("Mapped ProductDTO: ID={}, Name={}, Variants={}, Reviews={}", 
                     productDTO.getId(), 
                     productDTO.getName(), 
                     productDTO.getVariantCount(),
                     productDTO.getReviews() != null ? productDTO.getReviews().size() : 0);

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

        try {
            if (productElasticsearchService != null) {
                productElasticsearchService.saveProduct(savedProduct);
            } else {
                fallbackProductElasticsearchService.saveProduct(savedProduct);
            }
        } catch (Exception e) {
            logger.error("Failed to process product {} with Elasticsearch/fallback after creation: {}", savedProduct.getId(), e.getMessage(), e);
        }

        Product finalProduct = productRepository.findById(savedProduct.getId()).orElse(savedProduct);
        return productMapper.mapToProductDetailDTO(finalProduct); // Use detail mapper
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

        try {
            if (productElasticsearchService != null) {
                productElasticsearchService.saveProduct(updatedProduct);
            } else {
                fallbackProductElasticsearchService.saveProduct(updatedProduct);
            }
        } catch (Exception e) {
            logger.error("Failed to process product {} with Elasticsearch/fallback after database update: {}", updatedProduct.getId(), e.getMessage(), e);
        }

        Product finalProduct = productRepository.findById(updatedProduct.getId()).orElse(updatedProduct);
        return productMapper.mapToProductDetailDTO(finalProduct); // Use detail mapper
    }

    @Override
    @Transactional
    public void deleteProduct(Long productId) {
        logger.info("Attempting to delete product with ID: {}", productId);

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new EntityNotFoundException("Product not found with ID: " + productId));

        productRepository.delete(product);
        logger.info("Product deleted successfully with ID: {}", productId);

        try {
            if (productElasticsearchService != null) {
                productElasticsearchService.deleteProductById(productId);
            } else {
                fallbackProductElasticsearchService.deleteProductById(productId);
            }
        } catch (Exception e) {
            logger.error("Failed to process product {} deletion with Elasticsearch/fallback after database deletion: {}", productId, e.getMessage(), e);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductDTO> findTopSellingProducts(Pageable pageable) {
        logger.info("Finding top-selling products (placeholder logic) with page: {}", pageable);

        Sort sort = Sort.by(Sort.Direction.DESC, "averageRating")
                        .and(Sort.by(Sort.Direction.DESC, "createdDate"));
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sort);

        Specification<Product> spec = productSpecificationBuilder.build(
            null, null, null, null, null, null, null, null, null, false, false
        );

        Page<Product> productPage = productRepository.findAll(spec, pageRequest);
        List<ProductDTO> dtos = productPage.getContent().stream()
                .map(productMapper::mapToProductDTO) // This will now exclude reviews
                .collect(Collectors.toList());
        return new PageImpl<>(dtos, pageRequest, productPage.getTotalElements());
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductDTO> findTopDiscountedProducts(Pageable pageable) {
        logger.info("Finding top-discounted products with page: {}", pageable);

        Sort sort = Sort.by(Sort.Direction.DESC, "discountPercentage");
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sort);

        Specification<Product> spec = productSpecificationBuilder.build(
            null, null, null, null, null, null, null, null, null, true, false
        );

        Page<Product> productPage = productRepository.findAll(spec, pageRequest);
        List<ProductDTO> dtos = productPage.getContent().stream()
                .map(productMapper::mapToProductDTO) // This will now exclude reviews
                .collect(Collectors.toList());
        return new PageImpl<>(dtos, pageRequest, productPage.getTotalElements());
    }

    @Override
    @Transactional
    public ProductReviewDTO addReview(Long productId, CreateProductReviewRequestDTO reviewDTO, String userEmail) {
        logger.info("Attempting to add review for product ID: {} by user: {}", productId, userEmail != null ? userEmail : "Anonymous");

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new EntityNotFoundException("Product not found with ID: " + productId));

        ProductReview review = new ProductReview();
        review.setProduct(product);

        if (userEmail != null) {
            User user = userRepository.findByEmail(userEmail)
                    .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail + " for review submission."));
            review.setUser(user);
            // review.setReviewerName(user.getFullName()); // Set reviewer name from user
            review.setReviewerAvatarUrl(user.getAvatar()); // Set avatar URL from user
            // Rating is mandatory for logged-in users
            if (reviewDTO.getRating() == null || reviewDTO.getRating() < 1 || reviewDTO.getRating() > 5) {
                throw new IllegalArgumentException("Rating must be between 1 and 5 for logged-in users.");
            }
            review.setRating(reviewDTO.getRating());
        } else {
            // Anonymous user
            review.setReviewerName(StringUtils.hasText(reviewDTO.getReviewerName()) ? reviewDTO.getReviewerName() : "Anonymous");
            // For anonymous users, reviewerAvatarUrl could be set if provided in DTO, or from a service like Gravatar.
            // For now, it will remain null unless explicitly set.
            // If you have a default anonymous avatar, you can set it here:
            // review.setReviewerAvatarUrl("URL_TO_DEFAULT_ANONYMOUS_AVATAR");
            // Rating is optional for anonymous, but if provided, must be valid
            if (reviewDTO.getRating() != null) {
                if (reviewDTO.getRating() < 1 || reviewDTO.getRating() > 5) {
                    throw new IllegalArgumentException("If rating is provided for anonymous review, it must be between 1 and 5.");
                }
                review.setRating(reviewDTO.getRating());
            }
        }

        if (StringUtils.hasText(reviewDTO.getComment())) {
            review.setComment(reviewDTO.getComment().trim());
        }
        
        // Ensure either rating (for logged-in) or comment is present
        if (review.getRating() == null && (review.getComment() == null || review.getComment().trim().isEmpty())) {
            throw new IllegalArgumentException("A review must have at least a rating (for logged-in users) or a comment.");
        }


        ProductReview savedReview = productReviewRepository.save(review);
        logger.info("Review ID: {} saved for product ID: {}", savedReview.getId(), productId);

        // Update denormalized fields and Elasticsearch
        // This will re-fetch the product, including the new review in its collection, then calculate average rating.
        productDenormalizationService.updateDenormalizedFields(productId);

        // Re-fetch the product to get the updated denormalized values for Elasticsearch indexing
        Product updatedProduct = productRepository.findById(productId)
                .orElseThrow(() -> new EntityNotFoundException("Product not found after denormalization for ID: " + productId));


        if (productElasticsearchService != null) {
            try {
                productElasticsearchService.saveProduct(updatedProduct);
                logger.info("Product ID {} re-indexed in Elasticsearch after review addition.", productId);
            } catch (Exception e) {
                logger.error("Failed to re-index product ID {} in Elasticsearch after review: {}", productId, e.getMessage(), e);
                // Continue, as the primary operation (DB save) was successful
            }
        }
        
        ProductReviewDTO savedReviewDTO = productMapper.toProductReviewDTO(savedReview);

        // Broadcast the new review via WebSocket
        String destination = "/topic/product/" + productId + "/reviews";
        messagingTemplate.convertAndSend(destination, savedReviewDTO);
        logger.info("Broadcasted new review ID {} to WebSocket destination: {}", savedReviewDTO.getId(), destination);
        
        return savedReviewDTO;
    }
}
