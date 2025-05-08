package demo.com.example.testserver.admin.controller;

import demo.com.example.testserver.admin.dto.AdminDashboardSummaryDTO;
import demo.com.example.testserver.admin.dto.AdminSalesStatisticsDTO;
import demo.com.example.testserver.admin.service.AdminDashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Date;

@RestController
@RequestMapping("/api/admin/dashboard")
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('ADMIN')")
public class AdminDashboardController {

    @Autowired
    private AdminDashboardService adminDashboardService;

    @GetMapping("/summary")
    public ResponseEntity<AdminDashboardSummaryDTO> getDashboardSummary() {
        AdminDashboardSummaryDTO summary = adminDashboardService.getDashboardSummary();
        return ResponseEntity.ok(summary);
    }

    @GetMapping("/sales")
    public ResponseEntity<AdminSalesStatisticsDTO> getSalesStatistics(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Date startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Date endDate) {
        AdminSalesStatisticsDTO statistics = adminDashboardService.getSalesStatistics(startDate, endDate);
        return ResponseEntity.ok(statistics);
    }
}
