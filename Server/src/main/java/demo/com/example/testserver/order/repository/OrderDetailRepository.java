package demo.com.example.testserver.order.repository;

import demo.com.example.testserver.admin.dto.ProductSalesDTO;
import demo.com.example.testserver.order.model.OrderDetail;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Date;
import java.util.List;

@Repository
public interface OrderDetailRepository extends JpaRepository<OrderDetail, Integer> {

    @Query("SELECT new demo.com.example.testserver.admin.dto.ProductSalesDTO(od.productVariant.product.name, SUM(od.quantity)) " +
           "FROM OrderDetail od JOIN od.order o " +
           "WHERE o.orderDate >= :startDate AND o.orderDate < :endDate " +
           "GROUP BY od.productVariant.product.id, od.productVariant.product.name ORDER BY SUM(od.quantity) DESC")
    List<ProductSalesDTO> findTopSellingProductsBetweenDates(@Param("startDate") Date startDate, @Param("endDate") Date endDate, Pageable pageable);

    @Query("SELECT COALESCE(SUM(od.quantity), 0L) " +
           "FROM OrderDetail od JOIN od.order o " +
           "WHERE o.orderDate >= :startDate AND o.orderDate < :endDate")
    Long sumTotalQuantitySoldBetweenDates(@Param("startDate") Date startDate, @Param("endDate") Date endDate);
}
