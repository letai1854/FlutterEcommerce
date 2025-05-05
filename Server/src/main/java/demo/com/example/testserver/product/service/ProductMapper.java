package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.CreateProductRequestDTO;
import demo.com.example.testserver.product.dto.ProductDTO;
import demo.com.example.testserver.product.model.Brand;
import demo.com.example.testserver.product.model.Category;
import demo.com.example.testserver.product.model.Product;
import org.springframework.stereotype.Component;
import demo.com.example.testserver.product.model.ProductImage;
import demo.com.example.testserver.product.model.ProductVariant;
import demo.com.example.testserver.product.dto.CreateProductVariantDTO;
import demo.com.example.testserver.product.dto.ProductVariantDTO; // Import ProductVariantDTO
import demo.com.example.testserver.product.dto.UpdateProductRequestDTO; // Import Update DTOs
import demo.com.example.testserver.product.dto.UpdateProductVariantDTO;

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
        ProductDTO dto = new ProductDTO(product); // Constructor handles basic mapping + variants now
        // Set denormalized fields directly from the entity
        dto.setAverageRating(product.getAverageRating());
        dto.setMinPrice(product.getMinPrice());
        dto.setMaxPrice(product.getMaxPrice());
        // Explicitly set variant count (redundant if constructor does it, but safe)
        dto.setVariantCount(product.getVariants() != null ? product.getVariants().size() : 0);
        // Map variants explicitly if needed (constructor might already do this)
        if (product.getVariants() != null) {
             dto.setVariants(product.getVariants().stream()
                                   .map(this::mapToProductVariantDTO) // Use helper method
                                   .collect(Collectors.toList()));
        } else {
            dto.setVariants(new ArrayList<>());
        }
        // Add any other complex mapping logic here if needed
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
        product.setDiscountPercentage(dto.getDiscountPercentage() != null ? dto.getDiscountPercentage() : BigDecimal.ZERO);

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
        ProductVariantDTO variantDto = new ProductVariantDTO();
        variantDto.setId(variant.getId());
        variantDto.setName(variant.getName());
        variantDto.setSku(variant.getSku());
        variantDto.setPrice(variant.getPrice());
        variantDto.setStockQuantity(variant.getStockQuantity());
        variantDto.setVariantImageUrl(variant.getVariantImageUrl());
        // Avoid mapping back the product to prevent circular references in JSON
        return variantDto;
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
        product.setDiscountPercentage(dto.getDiscountPercentage() != null ? dto.getDiscountPercentage() : BigDecimal.ZERO);

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
}
