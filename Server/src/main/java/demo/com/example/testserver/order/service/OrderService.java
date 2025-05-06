package demo.com.example.testserver.order.service;

import demo.com.example.testserver.order.dto.CreateOrderRequestDTO;
import demo.com.example.testserver.order.dto.OrderDTO;
import demo.com.example.testserver.order.dto.OrderStatusHistoryDTO;
import demo.com.example.testserver.order.model.Order;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;

public interface OrderService {
    OrderDTO createOrder(String userEmail, CreateOrderRequestDTO requestDTO);
    Page<OrderDTO> getCurrentUserOrders(String userEmail, Order.OrderStatus status, Pageable pageable);
    OrderDTO getOrderByIdForCurrentUser(String userEmail, Integer orderId);
    List<OrderStatusHistoryDTO> getOrderStatusHistoryForCurrentUser(String userEmail, Integer orderId);
    OrderDTO updateOrderStatusByAdmin(Integer orderId, Order.OrderStatus newStatus, String adminNotes);
}
