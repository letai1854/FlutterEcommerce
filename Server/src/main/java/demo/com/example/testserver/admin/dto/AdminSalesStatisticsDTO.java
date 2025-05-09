package demo.com.example.testserver.admin.dto;

import java.math.BigDecimal;

public class AdminSalesStatisticsDTO {
    private long totalOrdersInRange;
    private BigDecimal totalRevenueInRange;
    private Long totalItemsSoldInRange;

    public AdminSalesStatisticsDTO(long totalOrdersInRange, BigDecimal totalRevenueInRange, Long totalItemsSoldInRange) {
        this.totalOrdersInRange = totalOrdersInRange;
        this.totalRevenueInRange = totalRevenueInRange;
        this.totalItemsSoldInRange = totalItemsSoldInRange;
    }

    // Getters and Setters
    public long getTotalOrdersInRange() {
        return totalOrdersInRange;
    }

    public void setTotalOrdersInRange(long totalOrdersInRange) {
        this.totalOrdersInRange = totalOrdersInRange;
    }

    public BigDecimal getTotalRevenueInRange() {
        return totalRevenueInRange;
    }

    public void setTotalRevenueInRange(BigDecimal totalRevenueInRange) {
        this.totalRevenueInRange = totalRevenueInRange;
    }

    public Long getTotalItemsSoldInRange() {
        return totalItemsSoldInRange;
    }

    public void setTotalItemsSoldInRange(Long totalItemsSoldInRange) {
        this.totalItemsSoldInRange = totalItemsSoldInRange;
    }
}
