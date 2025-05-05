package demo.com.example.testserver.product.dto;

import jakarta.validation.constraints.NotBlank;

public class UpdateBrandRequestDTO {

    @NotBlank(message = "Brand name cannot be blank")
    private String name;

    // Getters and Setters
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
