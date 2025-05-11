package demo.com.example.testserver.admin.controller;

import demo.com.example.testserver.admin.dto.AdminDashboardSummaryDTO;
import demo.com.example.testserver.admin.dto.AdminSalesStatisticsDTO;
import demo.com.example.testserver.admin.service.AdminDashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Date;

@RestController
@RequestMapping("/api/admin/dashboard")
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('ADMIN')")
public class AdminDashboardController {

    @Autowired
    private AdminDashboardService adminDashboardService;
    
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
}
