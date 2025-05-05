package demo.com.example.testserver.coupon.service;

import demo.com.example.testserver.common.exception.DuplicateResourceException; // Import custom exception
import demo.com.example.testserver.coupon.dto.CouponResponseDTO;
import demo.com.example.testserver.coupon.dto.CreateCouponRequestDTO;
import demo.com.example.testserver.coupon.model.Coupon;
import demo.com.example.testserver.coupon.repository.CouponRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class CouponService {

    @Autowired
    private CouponRepository couponRepository;

    @Transactional
    public CouponResponseDTO createCoupon(CreateCouponRequestDTO requestDTO) {
        // Kiểm tra xem mã code đã tồn tại chưa
        if (couponRepository.existsByCode(requestDTO.getCode())) {
            throw new DuplicateResourceException("Mã coupon '" + requestDTO.getCode() + "' đã tồn tại.");
        }

        Coupon coupon = new Coupon();
        coupon.setCode(requestDTO.getCode());
        coupon.setDiscountValue(requestDTO.getDiscountValue());
        coupon.setMaxUsageCount(requestDTO.getMaxUsageCount());
        coupon.setUsageCount(0); // Khởi tạo số lần đã sử dụng là 0

        Coupon savedCoupon = couponRepository.save(coupon);
        return mapToResponseDTO(savedCoupon);
    }

    @Transactional(readOnly = true)
    public List<CouponResponseDTO> searchCoupons(String code, Date startDate, Date endDate) {
        List<Coupon> coupons;

        if (code != null && !code.trim().isEmpty() && startDate != null && endDate != null) {
            coupons = couponRepository.findByCodeContainingIgnoreCaseAndCreatedDateBetween(code, startDate, endDate);
        } else if (code != null && !code.trim().isEmpty()) {
            coupons = couponRepository.findByCodeContainingIgnoreCase(code);
        } else if (startDate != null && endDate != null) {
            // Đảm bảo endDate bao gồm cả ngày đó
             Date adjustedEndDate = new Date(endDate.getTime() + (24 * 60 * 60 * 1000 - 1)); // Add 23:59:59.999
            coupons = couponRepository.findByCreatedDateBetween(startDate, adjustedEndDate);
        } else {
            coupons = couponRepository.findAll();
        }

        return coupons.stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    private CouponResponseDTO mapToResponseDTO(Coupon coupon) {
        return new CouponResponseDTO(
                coupon.getId(),
                coupon.getCode(),
                coupon.getDiscountValue(),
                coupon.getMaxUsageCount(),
                coupon.getUsageCount(),
                coupon.getCreatedDate()
        );
    }
}
