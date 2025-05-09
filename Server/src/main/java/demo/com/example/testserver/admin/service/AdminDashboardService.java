package demo.com.example.testserver.admin.service;

import demo.com.example.testserver.admin.dto.AdminDashboardSummaryDTO;
import demo.com.example.testserver.admin.dto.AdminSalesStatisticsDTO;
import demo.com.example.testserver.admin.dto.ProductSalesDTO;
import demo.com.example.testserver.order.repository.OrderDetailRepository;
import demo.com.example.testserver.order.repository.OrderRepository;
import demo.com.example.testserver.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

@Service
public class AdminDashboardService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderDetailRepository orderDetailRepository;

    public AdminDashboardSummaryDTO getDashboardSummary() {
        long totalUsers = userRepository.count();
        long totalOrders = orderRepository.count();

        Date now = new Date();
        Calendar cal = Calendar.getInstance();

        cal.setTime(now);
        cal.add(Calendar.DAY_OF_MONTH, -7);
        Date sevenDaysAgo = cal.getTime();

        cal.setTime(now);
        cal.add(Calendar.DAY_OF_MONTH, -14);
        Date fourteenDaysAgo = cal.getTime();

        long newUsersLast7Days = userRepository.countByCreatedDateGreaterThanEqual(sevenDaysAgo);

        BigDecimal revenueLast7Days = orderRepository.sumTotalAmountBetweenDates(sevenDaysAgo, now);
        if (revenueLast7Days == null) revenueLast7Days = BigDecimal.ZERO;

        BigDecimal revenuePrevious7Days = orderRepository.sumTotalAmountBetweenDates(fourteenDaysAgo, sevenDaysAgo);
        if (revenuePrevious7Days == null) revenuePrevious7Days = BigDecimal.ZERO;

        Double revenuePercentageChange;
        if (revenuePrevious7Days.compareTo(BigDecimal.ZERO) == 0) {
            if (revenueLast7Days.compareTo(BigDecimal.ZERO) == 0) {
                revenuePercentageChange = 0.0;
            } else {
                revenuePercentageChange = 100.0; // Infinite growth, represented as 100%
            }
        } else {
            BigDecimal change = revenueLast7Days.subtract(revenuePrevious7Days);
            BigDecimal percentage = change.multiply(BigDecimal.valueOf(100))
                                          .divide(revenuePrevious7Days, 2, RoundingMode.HALF_UP);
            revenuePercentageChange = percentage.doubleValue();
        }

        List<ProductSalesDTO> topSellingProducts = orderDetailRepository.findTopSellingProductsBetweenDates(
                sevenDaysAgo, now, PageRequest.of(0, 7));

        return new AdminDashboardSummaryDTO(
                totalUsers,
                newUsersLast7Days,
                totalOrders,
                revenuePercentageChange,
                topSellingProducts
        );
    }

    public AdminSalesStatisticsDTO getSalesStatistics(Date startDate, Date endDate) {
        long totalOrdersInRange = orderRepository.countByOrderDateBetween(startDate, endDate);
        BigDecimal totalRevenueInRange = orderRepository.sumTotalAmountBetweenDates(startDate, endDate);
        if (totalRevenueInRange == null) totalRevenueInRange = BigDecimal.ZERO;
        Long totalItemsSoldInRange = orderDetailRepository.sumTotalQuantitySoldBetweenDates(startDate, endDate);
        if (totalItemsSoldInRange == null) totalItemsSoldInRange = 0L;


        return new AdminSalesStatisticsDTO(
                totalOrdersInRange,
                totalRevenueInRange,
                totalItemsSoldInRange
        );
    }
}
