package demo.com.example.testserver.dashboard.service;

import demo.com.example.testserver.dashboard.dto.ChartDataDTO;
import demo.com.example.testserver.dashboard.dto.TimeSeriesDataPointDTO;
import demo.com.example.testserver.order.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.*;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalAdjusters;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.Comparator;
import java.math.BigDecimal;

@Service
public class DashboardService {

    @Autowired
    private OrderRepository orderRepository;

    private static final ZoneId APP_ZONE_ID = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final int WEEKLY_AGGREGATION_THRESHOLD_DAYS = 60;

    public ChartDataDTO getChartData(LocalDate startDate, LocalDate endDate) {
        Date queryStartDate = Date.from(startDate.atStartOfDay(APP_ZONE_ID).toInstant());
        // For query, endDate is exclusive, so use start of day of (endDate + 1 day)
        Date queryEndDate = Date.from(endDate.plusDays(1).atStartOfDay(APP_ZONE_ID).toInstant());

        List<TimeSeriesDataPointDTO> revenueData = processRawData(
            orderRepository.findRevenueOverTime(queryStartDate, queryEndDate), startDate, endDate
        );
        List<TimeSeriesDataPointDTO> ordersData = processRawData(
            orderRepository.findOrdersOverTime(queryStartDate, queryEndDate), startDate, endDate
        );
        List<TimeSeriesDataPointDTO> productsSoldData = processRawData(
            orderRepository.findProductsSoldOverTime(queryStartDate, queryEndDate), startDate, endDate
        );

        return new ChartDataDTO(revenueData, ordersData, productsSoldData);
    }

    private List<TimeSeriesDataPointDTO> processRawData(List<Object[]> rawData, LocalDate startDate, LocalDate endDate) {
        List<TimeSeriesDataPointDTO> dailyData = rawData.stream()
            .map(row -> {
                // The date from CAST(o.orderDate AS DATE) is java.sql.Date
                java.sql.Date sqlDate = (java.sql.Date) row[0];
                LocalDate localDate = sqlDate.toLocalDate();
                double value = 0;
                if (row[1] instanceof BigDecimal) {
                    value = ((BigDecimal) row[1]).doubleValue();
                } else if (row[1] instanceof Number) {
                    value = ((Number) row[1]).doubleValue();
                }
                return new TimeSeriesDataPointDTO(localDate, value);
            })
            .collect(Collectors.toList());

        long daysBetween = ChronoUnit.DAYS.between(startDate, endDate);

        if (daysBetween > WEEKLY_AGGREGATION_THRESHOLD_DAYS) {
            return aggregateToWeekly(dailyData, startDate, endDate);
        }
        return dailyData;
    }

    private List<TimeSeriesDataPointDTO> aggregateToWeekly(List<TimeSeriesDataPointDTO> dailyData, LocalDate overallStartDate, LocalDate overallEndDate) {
        if (dailyData.isEmpty()) {
            return List.of();
        }
        
        Map<LocalDate, Double> weeklyAggregated = dailyData.stream()
            .collect(Collectors.groupingBy(
                point -> point.getDate().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)), // Week starts on Monday
                Collectors.summingDouble(TimeSeriesDataPointDTO::getValue)
            ));

        return weeklyAggregated.entrySet().stream()
            .map(entry -> new TimeSeriesDataPointDTO(entry.getKey(), entry.getValue()))
            .sorted(Comparator.comparing(TimeSeriesDataPointDTO::getDate))
            .collect(Collectors.toList());
    }
}
