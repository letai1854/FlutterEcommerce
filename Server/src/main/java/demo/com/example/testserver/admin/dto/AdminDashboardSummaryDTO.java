package demo.com.example.testserver.admin.dto;

import java.util.List;

public class AdminDashboardSummaryDTO {
    private long totalUsers;
    private long newUsersLast7Days;
    private long totalOrders;
    private Double revenuePercentageChangeLast7Days; // Use Double to allow for null or specific meaning
    private List<ProductSalesDTO> topSellingProductsLast7Days;

    public AdminDashboardSummaryDTO(long totalUsers, long newUsersLast7Days, long totalOrders, Double revenuePercentageChangeLast7Days, List<ProductSalesDTO> topSellingProductsLast7Days) {
        this.totalUsers = totalUsers;
        this.newUsersLast7Days = newUsersLast7Days;
        this.totalOrders = totalOrders;
        this.revenuePercentageChangeLast7Days = revenuePercentageChangeLast7Days;
        this.topSellingProductsLast7Days = topSellingProductsLast7Days;
    }

    // Getters and Setters
    public long getTotalUsers() {
        return totalUsers;
    }

    public void setTotalUsers(long totalUsers) {
        this.totalUsers = totalUsers;
    }

    public long getNewUsersLast7Days() {
        return newUsersLast7Days;
    }

    public void setNewUsersLast7Days(long newUsersLast7Days) {
        this.newUsersLast7Days = newUsersLast7Days;
    }

    public long getTotalOrders() {
        return totalOrders;
    }

    public void setTotalOrders(long totalOrders) {
        this.totalOrders = totalOrders;
    }

    public Double getRevenuePercentageChangeLast7Days() {
        return revenuePercentageChangeLast7Days;
    }

    public void setRevenuePercentageChangeLast7Days(Double revenuePercentageChangeLast7Days) {
        this.revenuePercentageChangeLast7Days = revenuePercentageChangeLast7Days;
    }

    public List<ProductSalesDTO> getTopSellingProductsLast7Days() {
        return topSellingProductsLast7Days;
    }

    public void setTopSellingProductsLast7Days(List<ProductSalesDTO> topSellingProductsLast7Days) {
        this.topSellingProductsLast7Days = topSellingProductsLast7Days;
    }
}
