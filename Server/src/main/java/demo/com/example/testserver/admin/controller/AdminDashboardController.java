package demo.com.example.testserver.admin.controller;

import java.time.LocalDate;
import java.util.Date;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory; // Added import
import org.springframework.beans.factory.annotation.Autowired; // Added import
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController; // Added import

import demo.com.example.testserver.admin.dto.AdminDashboardSummaryDTO;
import demo.com.example.testserver.admin.dto.AdminSalesStatisticsDTO;
import demo.com.example.testserver.admin.service.AdminDashboardService;
import demo.com.example.testserver.dashboard.dto.ChartDataDTO;
import demo.com.example.testserver.dashboard.service.DashboardService;

@RestController
@RequestMapping("/api/admin/dashboard")
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('ADMIN')")
public class AdminDashboardController {

    @Autowired
    private AdminDashboardService adminDashboardService;

    @Autowired
    private DashboardService dashboardService; // Added DashboardService injection
    
    private static final Logger logger = LoggerFactory.getLogger(AdminDashboardController.class);

    @GetMapping("/summary")
    public ResponseEntity<?> getDashboardSummary() {
        try {
            logger.info("Fetching dashboard summary");
            AdminDashboardSummaryDTO summary = adminDashboardService.getDashboardSummary();
            return ResponseEntity.ok(summary);
        } catch (Exception e) {
            logger.error("Error fetching dashboard summary", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Error retrieving dashboard summary: " + e.getMessage());
        }
    }

    @GetMapping("/sales")
    public ResponseEntity<?> getSalesStatistics(
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS") Date startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS") Date endDate) {
        try {
            if (startDate.after(endDate)) {
                logger.warn("Invalid date range: startDate {} is after endDate {}", startDate, endDate);
                return ResponseEntity.badRequest().body("Start date must be before end date");
            }
            
            logger.info("Fetching sales statistics from {} to {}", startDate, endDate);
            AdminSalesStatisticsDTO statistics = adminDashboardService.getSalesStatistics(startDate, endDate);
            return ResponseEntity.ok(statistics);
        } catch (Exception e) {
            logger.error("Error fetching sales statistics for period {} to {}: {}", startDate, endDate, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Error retrieving sales statistics: " + e.getMessage());
        }
    }

    @GetMapping("/chart-data")
    public ResponseEntity<ChartDataDTO> getChartData(
            @RequestParam("startDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam("endDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        logger.info("Fetching chart data from {} to {}", startDate, endDate);
        if (startDate == null || endDate == null || startDate.isAfter(endDate)) {
            logger.warn("Invalid date range for chart data: startDate {}, endDate {}", startDate, endDate);
            return ResponseEntity.badRequest().body(null); // Basic validation
        }

        try {
            ChartDataDTO chartData = dashboardService.getChartData(startDate, endDate);
            return ResponseEntity.ok(chartData);
        } catch (Exception e) {
            logger.error("Error fetching chart data for period {} to {}: {}", startDate, endDate, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
}
