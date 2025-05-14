package demo.com.example.testserver.order.repository;

import demo.com.example.testserver.order.model.Order;
import demo.com.example.testserver.user.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Integer> {

    Page<Order> findByUserAndOrderStatus(User user, Order.OrderStatus status, Pageable pageable);

    Page<Order> findByUser(User user, Pageable pageable);

    Optional<Order> findByIdAndUser(Integer orderId, User user);

    List<Order> findByUserAndOrderStatusIn(User user, List<Order.OrderStatus> statuses);

    @Query("SELECT o FROM Order o WHERE o.user.id = :userId AND o.orderStatus = :status")
    Page<Order> findOrdersByUserIdAndStatus(@Param("userId") Integer userId, @Param("status") Order.OrderStatus status, Pageable pageable);

    @Query("SELECT o FROM Order o WHERE o.user.id = :userId")
    Page<Order> findOrdersByUserId(@Param("userId") Integer userId, Pageable pageable);

    @Query("SELECT COALESCE(SUM(o.totalAmount), 0.0) FROM Order o WHERE o.orderDate >= :startDate AND o.orderDate < :endDate")
    BigDecimal sumTotalAmountBetweenDates(@Param("startDate") Date startDate, @Param("endDate") Date endDate);

    long countByOrderDateBetween(Date startDate, Date endDate);

    // Methods for Admin order search
    Page<Order> findById(Integer id, Pageable pageable);

    Page<Order> findByOrderStatus(Order.OrderStatus status, Pageable pageable);

    Page<Order> findByOrderDateGreaterThanEqualAndOrderDateLessThan(Date startDate, Date endDate, Pageable pageable);

    Page<Order> findByOrderStatusAndOrderDateGreaterThanEqualAndOrderDateLessThan(Order.OrderStatus status, Date startDate, Date endDate, Pageable pageable);

    @Query("SELECT CAST(o.orderDate AS DATE) as orderDay, SUM(o.totalAmount) as dailyRevenue " +
           "FROM Order o WHERE o.orderDate >= :startDate AND o.orderDate < :endDate " +
           "AND o.orderStatus <> demo.com.example.testserver.order.model.Order.OrderStatus.da_huy " + // Exclude cancelled orders from revenue
           "GROUP BY orderDay ORDER BY orderDay ASC")
    List<Object[]> findRevenueOverTime(@Param("startDate") Date startDate, @Param("endDate") Date endDate);

    @Query("SELECT CAST(o.orderDate AS DATE) as orderDay, COUNT(o) as dailyOrderCount " +
           "FROM Order o WHERE o.orderDate >= :startDate AND o.orderDate < :endDate " +
           "GROUP BY orderDay ORDER BY orderDay ASC")
    List<Object[]> findOrdersOverTime(@Param("startDate") Date startDate, @Param("endDate") Date endDate);

    @Query("SELECT CAST(o.orderDate AS DATE) as orderDay, SUM(od.quantity) as dailyProductsSold " +
           "FROM Order o JOIN o.orderDetails od " +
           "WHERE o.orderDate >= :startDate AND o.orderDate < :endDate " +
           "AND o.orderStatus <> demo.com.example.testserver.order.model.Order.OrderStatus.da_huy " + // Exclude items from cancelled orders
           "GROUP BY orderDay ORDER BY orderDay ASC")
    List<Object[]> findProductsSoldOverTime(@Param("startDate") Date startDate, @Param("endDate") Date endDate);

}
