package demo.com.example.testserver.product.dto.elasticsearch;

import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;
import org.springframework.data.elasticsearch.annotations.Setting;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Document(indexName = "products")
// Optional: if you have custom analyzers. Ensure 'elasticsearch/analyzer-settings.json' exists if uncommented.
public class ProductElasticsearchDTO {

    @Id
    private Long id;

    @Field(type = FieldType.Text, analyzer = "standard", fielddata = true) // fielddata=true for sorting/aggregations on text
    private String name;

    @Field(type = FieldType.Text, analyzer = "standard")
    private String description;

    @Field(type = FieldType.Keyword)
    private String categoryName;

    @Field(type = FieldType.Keyword)
    private String brandName;

    @Field(type = FieldType.Keyword)
    private String mainImageUrl;

    @Field(type = FieldType.Keyword)
    private List<String> imageUrls;

    @Field(type = FieldType.Double)
    private BigDecimal discountPercentage;

    @Field(type = FieldType.Date)
    private Date createdDate;

    @Field(type = FieldType.Date)
    private Date updatedDate;

    @Field(type = FieldType.Double)
    private Double averageRating;

    @Field(type = FieldType.Double)
    private BigDecimal minPrice;

    @Field(type = FieldType.Double)
    private BigDecimal maxPrice;

    @Field(type = FieldType.Nested) // Use Nested for lists of objects to query them independently
    private List<ProductVariantElasticsearchDTO> variants;
    
    @Field(type = FieldType.Nested)
    private List<ProductReviewElasticsearchDTO> reviews;

    @Field(type = FieldType.Boolean)
    private Boolean isEnabled = true; // Assuming products are enabled by default

    // Getters and Setters

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public String getBrandName() {
        return brandName;
    }

    public void setBrandName(String brandName) {
        this.brandName = brandName;
    }

    public String getMainImageUrl() {
        return mainImageUrl;
    }

    public void setMainImageUrl(String mainImageUrl) {
        this.mainImageUrl = mainImageUrl;
    }

    public List<String> getImageUrls() {
        return imageUrls;
    }

    public void setImageUrls(List<String> imageUrls) {
        this.imageUrls = imageUrls;
    }

    public BigDecimal getDiscountPercentage() {
        return discountPercentage;
    }

    public void setDiscountPercentage(BigDecimal discountPercentage) {
        this.discountPercentage = discountPercentage;
    }

    public Date getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(Date createdDate) {
        this.createdDate = createdDate;
    }

    public Date getUpdatedDate() {
        return updatedDate;
    }

    public void setUpdatedDate(Date updatedDate) {
        this.updatedDate = updatedDate;
    }

    public Double getAverageRating() {
        return averageRating;
    }

    public void setAverageRating(Double averageRating) {
        this.averageRating = averageRating;
    }

    public BigDecimal getMinPrice() {
        return minPrice;
    }

    public void setMinPrice(BigDecimal minPrice) {
        this.minPrice = minPrice;
    }

    public BigDecimal getMaxPrice() {
        return maxPrice;
    }

    public void setMaxPrice(BigDecimal maxPrice) {
        this.maxPrice = maxPrice;
    }

    public List<ProductVariantElasticsearchDTO> getVariants() {
        return variants;
    }

    public void setVariants(List<ProductVariantElasticsearchDTO> variants) {
        this.variants = variants;
    }
    
    public List<ProductReviewElasticsearchDTO> getReviews() {
        return reviews;
    }

    public void setReviews(List<ProductReviewElasticsearchDTO> reviews) {
        this.reviews = reviews;
    }

    public Boolean getIsEnabled() {
        return isEnabled;
    }

    public void setIsEnabled(Boolean enabled) {
        isEnabled = enabled;
    }
}
