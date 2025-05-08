package demo.com.example.testserver.coupon.controller;

import demo.com.example.testserver.coupon.dto.CouponResponseDTO;
import demo.com.example.testserver.coupon.dto.CreateCouponRequestDTO;
import demo.com.example.testserver.coupon.service.CouponService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/api/coupons")
@CrossOrigin(origins = "*")
public class CouponController {

    @Autowired
    private CouponService couponService;

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<CouponResponseDTO> createCoupon(@Valid @RequestBody CreateCouponRequestDTO requestDTO) {
        CouponResponseDTO createdCoupon = couponService.createCoupon(requestDTO);
        return new ResponseEntity<>(createdCoupon, HttpStatus.CREATED);
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<CouponResponseDTO>> getCoupons(
            @RequestParam(required = false) String code,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) Date startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) Date endDate) {

        List<CouponResponseDTO> coupons = couponService.searchCoupons(code, startDate, endDate);
        if (coupons.isEmpty()) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(coupons);
    }

    @GetMapping("/available")
    public ResponseEntity<List<CouponResponseDTO>> getAvailableCoupons() {
        List<CouponResponseDTO> availableCoupons = couponService.getAvailableCouponsSortedByDiscount();
        if (availableCoupons.isEmpty()) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(availableCoupons);
    }
}
