package demo.com.example.testserver.admin.dto;

public class ProductSalesDTO {
    private String productName;
    private Long quantitySold;

    public ProductSalesDTO(String productName, Long quantitySold) {
        this.productName = productName;
        this.quantitySold = quantitySold;
    }

    // Getters and Setters
    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public Long getQuantitySold() {
        return quantitySold;
    }

    public void setQuantitySold(Long quantitySold) {
        this.quantitySold = quantitySold;
    }
}
