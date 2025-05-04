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

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class ProductMapper {

    public ProductDTO mapToProductDTO(Product product) {
        if (product == null) {
            return null;
        }
        ProductDTO dto = new ProductDTO(product); // Assuming ProductDTO constructor handles basic mapping
        // Set denormalized fields directly from the entity
        dto.setAverageRating(product.getAverageRating());
        dto.setMinPrice(product.getMinPrice());
        dto.setMaxPrice(product.getMaxPrice());
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
}
