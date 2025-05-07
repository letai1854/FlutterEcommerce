package demo.com.example.testserver.order.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

public class CreateOrderRequestDTO {

    @NotNull(message = "Address ID cannot be null")
    private Integer addressId;

    @NotEmpty(message = "Order details cannot be empty")
    @Valid
    private List<OrderDetailRequestDTO> orderDetails;

    private String couponCode; // Optional

    @NotNull(message = "Payment method cannot be null")
    @Size(min = 1, max = 50, message = "Payment method must be between 1 and 50 characters")
    private String paymentMethod;

    private BigDecimal pointsToUse; // Optional

    private BigDecimal shippingFee; // Added field

    private BigDecimal tax; // Added field

    // Getters and Setters
    public Integer getAddressId() {
        return addressId;
    }

    public void setAddressId(Integer addressId) {
        this.addressId = addressId;
    }

    public List<OrderDetailRequestDTO> getOrderDetails() {
        return orderDetails;
    }

    public void setOrderDetails(List<OrderDetailRequestDTO> orderDetails) {
        this.orderDetails = orderDetails;
    }

    public String getCouponCode() {
        return couponCode;
    }

    public void setCouponCode(String couponCode) {
        this.couponCode = couponCode;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public BigDecimal getPointsToUse() {
        return pointsToUse;
    }

    public void setPointsToUse(BigDecimal pointsToUse) {
        this.pointsToUse = pointsToUse;
    }

    public BigDecimal getShippingFee() {
        return shippingFee;
    }

    public void setShippingFee(BigDecimal shippingFee) {
        this.shippingFee = shippingFee;
    }

    public BigDecimal getTax() {
        return tax;
    }

    public void setTax(BigDecimal tax) {
        this.tax = tax;
    }
}
