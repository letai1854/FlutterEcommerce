package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.CreateProductRequestDTO;
import demo.com.example.testserver.product.dto.ProductDTO;
import demo.com.example.testserver.product.dto.elasticsearch.ProductElasticsearchDTO;
import demo.com.example.testserver.product.dto.elasticsearch.ProductReviewElasticsearchDTO;
import demo.com.example.testserver.product.dto.elasticsearch.ProductVariantElasticsearchDTO;
import demo.com.example.testserver.product.model.Brand;
import demo.com.example.testserver.product.model.Category;
import demo.com.example.testserver.product.model.Product;
import org.springframework.stereotype.Component;
import demo.com.example.testserver.product.model.ProductImage;
import demo.com.example.testserver.product.model.ProductReview;
import demo.com.example.testserver.product.model.ProductVariant;
import demo.com.example.testserver.product.dto.CreateProductVariantDTO;
import demo.com.example.testserver.product.dto.ProductVariantDTO; // Import ProductVariantDTO
import demo.com.example.testserver.product.dto.UpdateProductRequestDTO; // Import Update DTOs
import demo.com.example.testserver.product.dto.UpdateProductVariantDTO;
import demo.com.example.testserver.product.dto.ProductReviewDTO;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class ProductMapper {

    public ProductDTO mapToProductDTO(Product product) {
        if (product == null) {
            return null;
        }
        ProductDTO dto = new ProductDTO(product); // Constructor handles basic mapping (excluding reviews now)
        // Set denormalized fields directly from the entity
        dto.setAverageRating(product.getAverageRating());
        dto.setMinPrice(product.getMinPrice());
        dto.setMaxPrice(product.getMaxPrice());
        // Explicitly set variant count (constructor also does this, but explicit is fine)
        dto.setVariantCount(product.getVariants() != null ? product.getVariants().size() : 0);

        // Map additional images explicitly (constructor also does this)
        if (product.getImages() != null) {
            dto.setImageUrls(product.getImages().stream()
                                    .map(ProductImage::getImageUrl)
                                    .collect(Collectors.toList()));
        } else {
            dto.setImageUrls(new ArrayList<>());
        }

        // Map variants explicitly (constructor also does this)
        if (product.getVariants() != null) {
             dto.setVariants(product.getVariants().stream()
                                   .map(this::mapToProductVariantDTO) // Use helper method
                                   .collect(Collectors.toList()));
        } else {
            dto.setVariants(new ArrayList<>());
        }
        // Reviews are not mapped here for the general DTO.
        // Use mapToProductDetailDTO for DTOs that require reviews.
        return dto;
    }

    public ProductDTO mapToProductDetailDTO(Product product) {
        if (product == null) {
            return null;
        }
        // Start with the base mapping (which excludes reviews by default now)
        ProductDTO dto = this.mapToProductDTO(product);

        // Explicitly map reviews for the detail DTO
        if (product.getReviews() != null) {
            dto.setReviews(product.getReviews().stream()
                                  .map(this::toProductReviewDTO) // Use existing helper to map ProductReview to ProductReviewDTO
                                  .collect(Collectors.toList()));
        } else {
            dto.setReviews(new ArrayList<>()); // Ensure it's an empty list if no reviews
        }
        return dto;
    }

    public Product mapToProductEntity(CreateProductRequestDTO dto, Category category, Brand brand) {
        if (dto == null || category == null || brand == null) {
            // Consider throwing an exception or returning null based on desired error handling
            return null;
        }
        Product product = new Product();
        product.setName(dto.getName());
        product.setDescription(dto.getDescription());
        product.setCategory(category);
        product.setBrand(brand);
        product.setMainImageUrl(dto.getMainImageUrl());
        product.setDiscountPercentage(dto.getDiscountPercentage()); // Allow null to be set directly

        // Initialize denormalized fields to null or default values if appropriate
        product.setMinPrice(null);
        product.setMaxPrice(null);
        product.setAverageRating(null);

        // Map additional images
        if (dto.getImageUrls() != null && !dto.getImageUrls().isEmpty()) {
            List<ProductImage> images = dto.getImageUrls().stream()
                    .map(url -> {
                        ProductImage img = new ProductImage();
                        img.setImageUrl(url);
                        img.setProduct(product); // Set the back-reference
                        return img;
                    })
                    .collect(Collectors.toList());
            product.setImages(images);
        } else {
            product.setImages(new ArrayList<>()); // Initialize with empty list if null
        }

        // Map variants
        if (dto.getVariants() != null && !dto.getVariants().isEmpty()) {
            List<ProductVariant> variants = dto.getVariants().stream()
                    .map(variantDto -> mapToProductVariantEntity(variantDto, product))
                    .collect(Collectors.toList());
            product.setVariants(variants);
        } else {
            product.setVariants(new ArrayList<>());
        }

        return product;
    }

    // Helper method to map ProductVariant entity to ProductVariantDTO
    private ProductVariantDTO mapToProductVariantDTO(ProductVariant variant) {
        if (variant == null) {
            return null;
        }
        ProductVariantDTO dto = new ProductVariantDTO();
        dto.setId(variant.getId());
        dto.setName(variant.getName());
        dto.setSku(variant.getSku());
        dto.setPrice(variant.getPrice());
        dto.setStockQuantity(variant.getStockQuantity());
        dto.setVariantImageUrl(variant.getVariantImageUrl());
        return dto;
    }

    // Helper method to map CreateProductVariantDTO to ProductVariant entity
    private ProductVariant mapToProductVariantEntity(CreateProductVariantDTO variantDto, Product product) {
        ProductVariant variant = new ProductVariant();
        variant.setName(variantDto.getName());
        variant.setSku(variantDto.getSku());
        variant.setPrice(variantDto.getPrice());
        variant.setStockQuantity(variantDto.getStockQuantity());
        variant.setVariantImageUrl(variantDto.getVariantImageUrl());
        variant.setProduct(product); // Set the back-reference to the owning product
        return variant;
    }

    /**
     * Updates an existing Product entity with data from UpdateProductRequestDTO.
     * Handles merging of variants and images.
     *
     * @param product    The existing Product entity to update.
     * @param dto        The DTO containing update data.
     * @param category   The updated Category entity.
     * @param brand      The updated Brand entity.
     */
    public void updateProductFromDTO(Product product, UpdateProductRequestDTO dto, Category category, Brand brand) {
        if (product == null || dto == null || category == null || brand == null) {
            // Or throw an exception
            return;
        }

        product.setName(dto.getName());
        product.setDescription(dto.getDescription());
        product.setCategory(category);
        product.setBrand(brand);
        product.setMainImageUrl(dto.getMainImageUrl());
        product.setDiscountPercentage(dto.getDiscountPercentage()); // Allow null to be set directly

        // Update Images (Replace strategy for simplicity, could be merge)
        updateProductImages(product, dto.getImageUrls());

        // Update Variants (Merge strategy)
        updateProductVariants(product, dto.getVariants());

        // Denormalized fields will be updated by ProductDenormalizationService after save
    }

    // Helper to update product images (replace strategy)
    private void updateProductImages(Product product, List<String> imageUrls) {
        // Clear existing images managed by this relationship
        if (product.getImages() == null) {
            product.setImages(new ArrayList<>());
        }
        product.getImages().clear();

        // Add new images from DTO
        if (imageUrls != null && !imageUrls.isEmpty()) {
            List<ProductImage> newImages = imageUrls.stream()
                    .map(url -> {
                        ProductImage img = new ProductImage();
                        img.setImageUrl(url);
                        img.setProduct(product); // Set back-reference
                        return img;
                    })
                    .collect(Collectors.toList());
            product.getImages().addAll(newImages);
        }
    }

    // Helper to update product variants (merge strategy)
    private void updateProductVariants(Product product, List<UpdateProductVariantDTO> variantDtos) {
        if (product.getVariants() == null) {
            product.setVariants(new ArrayList<>());
        }

        // Map existing variants by ID for quick lookup
        Map<Integer, ProductVariant> existingVariantsMap = product.getVariants().stream()
                .collect(Collectors.toMap(ProductVariant::getId, Function.identity()));

        List<ProductVariant> updatedVariants = new ArrayList<>();

        for (UpdateProductVariantDTO dto : variantDtos) {
            ProductVariant variant;
            if (dto.getId() != null && existingVariantsMap.containsKey(dto.getId())) {
                // Update existing variant
                variant = existingVariantsMap.get(dto.getId());
                updateVariantEntityFromDTO(variant, dto);
                existingVariantsMap.remove(dto.getId()); // Remove from map as it's processed
            } else {
                // Create new variant
                variant = new ProductVariant();
                updateVariantEntityFromDTO(variant, dto);
                variant.setProduct(product); // Set back-reference for new variant
            }
            updatedVariants.add(variant);
        }

        // Variants remaining in existingVariantsMap were not in the DTO, so they should be removed.
        // JPA's orphanRemoval=true on the Product.variants mapping handles the deletion
        // when we replace the collection.

        // Replace the product's variant list with the updated list
        product.getVariants().clear();
        product.getVariants().addAll(updatedVariants);
    }

    // Helper to map UpdateProductVariantDTO data onto an existing or new ProductVariant entity
    private void updateVariantEntityFromDTO(ProductVariant variant, UpdateProductVariantDTO dto) {
        variant.setName(dto.getName());
        variant.setSku(dto.getSku());
        variant.setPrice(dto.getPrice());
        variant.setStockQuantity(dto.getStockQuantity());
        variant.setVariantImageUrl(dto.getVariantImageUrl());
        // product reference is set in the calling method (updateProductVariants)
    }

    // --- Elasticsearch DTO Mappers ---

    public ProductElasticsearchDTO mapToProductElasticsearchDTO(Product product) {
        if (product == null) {
            return null;
        }
        ProductElasticsearchDTO dto = new ProductElasticsearchDTO();
        dto.setId(product.getId());
        dto.setName(product.getName());
        dto.setDescription(product.getDescription());
        if (product.getCategory() != null) {
            dto.setCategoryName(product.getCategory().getName());
        }
        if (product.getBrand() != null) {
            dto.setBrandName(product.getBrand().getName());
        }
        dto.setMainImageUrl(product.getMainImageUrl());
        if (product.getImages() != null) {
            dto.setImageUrls(product.getImages().stream()
                    .map(ProductImage::getImageUrl)
                    .collect(Collectors.toList()));
        } else {
            dto.setImageUrls(new ArrayList<>());
        }
        dto.setDiscountPercentage(product.getDiscountPercentage());
        dto.setCreatedDate(product.getCreatedDate());
        dto.setUpdatedDate(product.getUpdatedDate());
        dto.setAverageRating(product.getAverageRating());
        dto.setMinPrice(product.getMinPrice());
        dto.setMaxPrice(product.getMaxPrice());
        dto.setIsEnabled(product.isEnabled());

        if (product.getVariants() != null) {
            dto.setVariants(product.getVariants().stream()
                    .map(this::mapToProductVariantElasticsearchDTO)
                    .collect(Collectors.toList()));
        } else {
            dto.setVariants(new ArrayList<>());
        }
        
        if (product.getReviews() != null) {
            dto.setReviews(product.getReviews().stream()
                    .map(this::mapToProductReviewElasticsearchDTO)
                    .collect(Collectors.toList()));
        } else {
            dto.setReviews(new ArrayList<>());
        }

        return dto;
    }

    private ProductVariantElasticsearchDTO mapToProductVariantElasticsearchDTO(ProductVariant variant) {
        if (variant == null) {
            return null;
        }
        ProductVariantElasticsearchDTO dto = new ProductVariantElasticsearchDTO();
        dto.setId(variant.getId());
        dto.setName(variant.getName());
        dto.setSku(variant.getSku());
        dto.setPrice(variant.getPrice());
        dto.setStockQuantity(variant.getStockQuantity());
        dto.setVariantImageUrl(variant.getVariantImageUrl());
        return dto;
    }

    public ProductReviewDTO toProductReviewDTO(ProductReview review) {
        if (review == null) {
            return null;
        }
        ProductReviewDTO dto = new ProductReviewDTO();
        dto.setId(review.getId());

        if (review.getUser() != null) {
            dto.setReviewerName(review.getUser().getFullName());
            dto.setUserId(review.getUser().getId().longValue());
            dto.setReviewerAvatarUrl(review.getUser().getAvatar()); // Get avatar from User
        } else {
            if (review.getReviewerName() != null && !review.getReviewerName().trim().isEmpty()) {
                dto.setReviewerName(review.getReviewerName());
            } else {
                dto.setReviewerName("Anonymous");
            }
            // For anonymous users, reviewerAvatarUrl in DTO will be based on what's in ProductReview entity.
            // If ProductReview.reviewerAvatarUrl is populated for anonymous (e.g. Gravatar), it will be mapped.
            // Otherwise, it will be null.
            dto.setReviewerAvatarUrl(review.getReviewerAvatarUrl());
            dto.setUserId(null); // Explicitly set userId to null for anonymous
        }

        dto.setRating(review.getRating());
        dto.setComment(review.getComment());
        dto.setReviewTime(review.getReviewTime());
        if (review.getProduct() != null) {
            dto.setProductId(review.getProduct().getId());
        }
        return dto;
    }

    private ProductReviewElasticsearchDTO mapToProductReviewElasticsearchDTO(ProductReview review) {
        if (review == null) {
            return null;
        }
        ProductReviewElasticsearchDTO dto = new ProductReviewElasticsearchDTO();
        dto.setId(review.getId());
        if (review.getUser() != null) {
            dto.setReviewerName(review.getUser().getFullName());
        } else {
            dto.setReviewerName(review.getReviewerName());
        }
        dto.setRating(review.getRating());
        dto.setComment(review.getComment());
        dto.setReviewTime(review.getReviewTime());
        return dto;
    }
}
