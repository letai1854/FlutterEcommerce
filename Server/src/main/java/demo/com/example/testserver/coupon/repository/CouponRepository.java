package demo.com.example.testserver.coupon.repository;

import demo.com.example.testserver.coupon.model.Coupon;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Date;
import java.util.List;
import java.util.Optional;

@Repository
public interface CouponRepository extends JpaRepository<Coupon, Integer> {

    Optional<Coupon> findByCode(String code);

    boolean existsByCode(String code);

    // Find by code containing (case-insensitive)
    List<Coupon> findByCodeContainingIgnoreCase(String code);

    // Find by creation date between
    List<Coupon> findByCreatedDateBetween(Date startDate, Date endDate);

    // Find by code containing and creation date between
    List<Coupon> findByCodeContainingIgnoreCaseAndCreatedDateBetween(String code, Date startDate, Date endDate);


    // Find available coupons (usageCount < maxUsageCount) ordered by discount value descending
    @Query("SELECT c FROM Coupon c WHERE c.usageCount < c.maxUsageCount ORDER BY c.discountValue DESC")
    List<Coupon> findAvailableCouponsOrderByDiscountValueDesc();
}
