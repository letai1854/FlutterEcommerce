package demo.com.example.testserver.coupon.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public class CreateCouponRequestDTO {

    @NotBlank(message = "Mã code không được để trống")
    @Size(min = 5, max = 5, message = "Mã code phải có đúng 5 ký tự")
    @Pattern(regexp = "[A-Z0-9]{5}", message = "Mã code chỉ được chứa chữ cái in hoa (A-Z) và số (0-9)")
    private String code;

    @NotNull(message = "Giá trị giảm không được để trống")
    @DecimalMin(value = "0.01", message = "Giá trị giảm phải lớn hơn 0")
    private BigDecimal discountValue;

    @NotNull(message = "Số lần sử dụng tối đa không được để trống")
    @Min(value = 1, message = "Số lần sử dụng tối đa phải ít nhất là 1")
    private Integer maxUsageCount;

    // Getters and Setters
    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public BigDecimal getDiscountValue() {
        return discountValue;
    }

    public void setDiscountValue(BigDecimal discountValue) {
        this.discountValue = discountValue;
    }

    public Integer getMaxUsageCount() {
        return maxUsageCount;
    }

    public void setMaxUsageCount(Integer maxUsageCount) {
        this.maxUsageCount = maxUsageCount;
    }
}
