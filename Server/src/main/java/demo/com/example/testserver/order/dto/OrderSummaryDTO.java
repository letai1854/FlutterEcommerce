package demo.com.example.testserver.order.dto;

import java.math.BigDecimal;

public class OrderSummaryDTO {
    private Integer orderId;
    private BigDecimal orderValue;

    public OrderSummaryDTO(Integer orderId, BigDecimal orderValue) {
        this.orderId = orderId;
        this.orderValue = orderValue;
    }

    public Integer getOrderId() {
        return orderId;
    }

    public void setOrderId(Integer orderId) {
        this.orderId = orderId;
    }

    public BigDecimal getOrderValue() {
        return orderValue;
    }

    public void setOrderValue(BigDecimal orderValue) {
        this.orderValue = orderValue;
    }
}
