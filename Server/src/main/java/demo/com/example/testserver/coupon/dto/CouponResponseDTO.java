package demo.com.example.testserver.coupon.dto;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
import demo.com.example.testserver.order.dto.OrderSummaryDTO;

public class CouponResponseDTO {
    private Integer id;
    private String code;
    private BigDecimal discountValue;
    private Integer maxUsageCount;
    private Integer usageCount;
    private Date createdDate;
    private List<OrderSummaryDTO> orders;

    // Constructor, Getters and Setters
    public CouponResponseDTO(Integer id, String code, BigDecimal discountValue, Integer maxUsageCount, Integer usageCount, Date createdDate) {
        this.id = id;
        this.code = code;
        this.discountValue = discountValue;
        this.maxUsageCount = maxUsageCount;
        this.usageCount = usageCount;
        this.createdDate = createdDate;
        // this.orders = orders;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

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

    public Integer getUsageCount() {
        return usageCount;
    }

    public void setUsageCount(Integer usageCount) {
        this.usageCount = usageCount;
    }

    public Date getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(Date createdDate) {
        this.createdDate = createdDate;
    }

    public List<OrderSummaryDTO> getOrders() {
        return orders;
    }

    public void setOrders(List<OrderSummaryDTO> orders) {
        this.orders = orders;
    }
}
